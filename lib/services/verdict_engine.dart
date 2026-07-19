import '../models/product.dart';
import '../models/scan.dart';
import '../models/verdict.dart';

/// Pure-Dart verdict logic: Gemma reads the pack, THIS decides.
/// No I/O — takes the snapshot lists in memory so it is fully unit-testable.
class VerdictEngine {
  final List<Product> products;
  final List<Recall> recalls;
  final List<Lookalike> lookalikes;
  final DateTime Function() now;

  VerdictEngine({
    required this.products,
    required this.recalls,
    required this.lookalikes,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static const strongMatch = 0.83;
  static const weakMatch = 0.60;

  Verdict evaluate(Extraction e) {
    if (!e.legible || e.isEmpty) {
      return const Verdict(
        status: VerdictStatus.unreadable,
        reasons: ['The photo could not be read. Try more light and hold steady.'],
      );
    }

    final expiry = parseExpiry(e.expiryRaw);
    final expired = expiry != null && expiry.isBefore(now());

    // Recall/alert check — name against recall entries (manufacturer refines).
    Recall? hitRecall;
    var recallScore = 0.0;
    for (final r in recalls) {
      var s = similarity(e.productName, r.name);
      if (e.manufacturer.isNotEmpty &&
          r.manufacturer.isNotEmpty &&
          similarity(e.manufacturer, r.manufacturer) > 0.7) {
        s += 0.05;
      }
      if (s > recallScore) {
        recallScore = s;
        hitRecall = r;
      }
    }
    final recalled = recallScore >= strongMatch;

    // Register match — score against brand name and generic name.
    Product? best;
    var bestScore = 0.0;
    for (final p in products) {
      var s = similarity(e.productName, p.name);
      if (p.generic.isNotEmpty) {
        final g = similarity(e.productName, p.generic) - 0.02; // prefer brand hits
        if (g > s) s = g;
      }
      if (e.manufacturer.isNotEmpty && p.manufacturer.isNotEmpty) {
        final m = similarity(e.manufacturer, p.manufacturer);
        s += m > 0.7 ? 0.04 : (m < 0.3 ? -0.03 : 0);
      }
      if (s > bestScore) {
        bestScore = s;
        best = p;
      }
    }
    final matched = bestScore >= strongMatch ? best : null;

    // Lookalike note — attaches to whatever the verdict ends up being.
    String? lookNote;
    final nameForLook = matched?.name ?? e.productName;
    for (final l in lookalikes) {
      if (similarity(nameForLook, l.a) >= strongMatch ||
          similarity(nameForLook, l.b) >= strongMatch) {
        lookNote = '${l.a} and ${l.b} are easily confused. ${l.note}';
        break;
      }
    }

    // Precedence: recalled > expired > registered/caution/notFound.
    if (recalled) {
      return Verdict(
        status: VerdictStatus.recalled,
        recall: hitRecall,
        product: matched,
        matchScore: bestScore,
        expiryDate: expiry,
        lookalikeNote: lookNote,
        reasons: [
          'This product matches an FDA Ghana ${hitRecall!.type == 'recall' ? 'recall' : 'safety alert'}: ${hitRecall.name}.',
          if (hitRecall.reason.isNotEmpty) hitRecall.reason,
          'Do not take it. Report to the FDA on 0551112224 (WhatsApp) or return it to the pharmacy.',
        ],
      );
    }

    if (expired) {
      return Verdict(
        status: VerdictStatus.expired,
        product: matched,
        matchScore: bestScore,
        expiryDate: expiry,
        lookalikeNote: lookNote,
        reasons: [
          'The pack shows an expiry of ${_fmtMonth(expiry)} — that date has passed.',
          if (matched != null)
            'The product itself (${matched.name}) is in the register snapshot, but this pack is expired.',
          'Expired medicine can be weak or unsafe. Do not take it.',
        ],
      );
    }

    if (matched != null) {
      // A lookalike pairing only downgrades the verdict when the read name
      // is NOT an exact match — exact reads keep the note as information.
      final exact = similarity(e.productName, matched.name) == 1 ||
          (matched.generic.isNotEmpty &&
              similarity(e.productName, matched.generic) == 1);
      return Verdict(
        status: (lookNote == null || exact)
            ? VerdictStatus.registered
            : VerdictStatus.caution,
        product: matched,
        matchScore: bestScore,
        expiryDate: expiry,
        lookalikeNote: lookNote,
        reasons: [
          'Found in the register snapshot as “${matched.name}”'
              '${matched.manufacturer.isNotEmpty ? ' by ${matched.manufacturer}' : ''}.',
          if (expiry != null)
            'Expiry ${_fmtMonth(expiry)} — still in date.'
          else if (e.expiryRaw.isEmpty)
            'No expiry date was read from the pack — check it yourself before use.',
          ?lookNote,
        ],
      );
    }

    if (bestScore >= weakMatch && best != null) {
      return Verdict(
        status: VerdictStatus.caution,
        product: best,
        matchScore: bestScore,
        expiryDate: expiry,
        lookalikeNote: lookNote,
        reasons: [
          'The name read as “${e.productName}”, which is close to '
              '“${best.name}” in the register — but not an exact match.',
          'Check the spelling on the pack carefully. Small name changes are a known counterfeit trick.',
          ?lookNote,
        ],
      );
    }

    return Verdict(
      status: VerdictStatus.notFound,
      matchScore: bestScore,
      expiryDate: expiry,
      lookalikeNote: lookNote,
      reasons: [
        '“${e.productName}” was not found in this offline register snapshot.',
        'That does not prove it is fake — but treat it with caution.',
        'Verify with your pharmacist or the FDA (0551112224 on WhatsApp) before use.',
      ],
    );
  }

  // ── Text similarity ────────────────────────────────────────────────────

  static String normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  /// 0..1 similarity blending token overlap and edit distance.
  static double similarity(String a, String b) {
    final na = normalize(a), nb = normalize(b);
    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1;
    if (na.contains(nb) || nb.contains(na)) return 0.92;
    final ta = na.split(' ').toSet(), tb = nb.split(' ').toSet();
    final maxLen = na.length > nb.length ? na.length : nb.length;
    final charSim = 1 - _levenshtein(na, nb) / maxLen;
    // Single-word vs single-word: token overlap is meaningless; edit distance
    // rules. A near-miss spelling ("Pamadol" for "Panadol") is the classic
    // counterfeit trick, so anything short of exact is capped below the
    // strong-match threshold — it can reach caution, never registered.
    if (ta.length == 1 && tb.length == 1) {
      return charSim > 0.82 ? 0.82 : charSim;
    }
    final jaccard = ta.intersection(tb).length / ta.union(tb).length;
    final blended = jaccard * 0.6 + charSim * 0.4;
    // A single strong token (e.g. brand word) against a multi-word entry.
    final firstHit = tb.contains(ta.first) || ta.contains(tb.first);
    return firstHit && blended < 0.7 ? 0.7 : blended;
  }

  static int _levenshtein(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final cur = [i + 1, ...List.filled(b.length, 0)];
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        cur[j + 1] = [
          cur[j] + 1,
          prev[j + 1] + 1,
          prev[j] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  // ── Expiry parsing ─────────────────────────────────────────────────────

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  /// Parses pack expiry text ("08/2027", "EXP 08-27", "AUG 2027",
  /// "2027-08-15", "15.08.2027"). Month-precision dates resolve to the last
  /// day of that month (a pack is usable through its expiry month).
  static DateTime? parseExpiry(String raw) {
    if (raw.trim().isEmpty) return null;
    var s = raw.toLowerCase();
    s = s.replaceAll(RegExp(r'\b(exp|expiry|expiry date|exp date|best before|use by)\b[.: ]*'), ' ');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

    // Month name + year: "aug 2027", "2027 aug"
    final mName = RegExp(r'\b([a-z]{3,9})\b').firstMatch(s);
    final year4 = RegExp(r'\b(20\d{2})\b').firstMatch(s);
    if (mName != null && year4 != null) {
      final m = _months[mName.group(1)!.substring(0, 3)];
      if (m != null) return _endOfMonth(int.parse(year4.group(1)!), m);
    }

    final nums = RegExp(r'\d+').allMatches(s).map((m) => m.group(0)!).toList();
    if (nums.isEmpty) return null;

    // ISO-ish: 2027 08 [15]
    if (nums.first.length == 4) {
      final y = int.parse(nums.first);
      final m = nums.length > 1 ? int.parse(nums[1]) : 12;
      if (y >= 2000 && y < 2100 && m >= 1 && m <= 12) {
        if (nums.length > 2) {
          final d = int.parse(nums[2]);
          if (d >= 1 && d <= 31) return DateTime(y, m, d, 23, 59);
        }
        return _endOfMonth(y, m);
      }
    }

    // DD MM YYYY / DD MM YY
    if (nums.length >= 3) {
      final d = int.parse(nums[0]), m = int.parse(nums[1]);
      var y = int.parse(nums[2]);
      if (y < 100) y += 2000;
      if (d >= 1 && d <= 31 && m >= 1 && m <= 12 && y >= 2000 && y < 2100) {
        return DateTime(y, m, d, 23, 59);
      }
    }

    // MM YYYY / MM YY
    if (nums.length >= 2) {
      final m = int.parse(nums[0]);
      var y = int.parse(nums[1]);
      if (y < 100) y += 2000;
      if (m >= 1 && m <= 12 && y >= 2000 && y < 2100) return _endOfMonth(y, m);
    }
    return null;
  }

  static DateTime _endOfMonth(int y, int m) =>
      DateTime(y, m + 1, 0, 23, 59); // day 0 of next month = last day of m

  static String _fmtMonth(DateTime d) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${names[d.month - 1]} ${d.year}';
  }
}
