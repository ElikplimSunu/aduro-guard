import 'product.dart';

enum VerdictStatus {
  registered, // found in register snapshot, nothing wrong
  expired, // pack expiry date has passed
  recalled, // matches an FDA recall/alert entry
  caution, // near-miss name, lookalike risk, or low-confidence read
  notFound, // not in this snapshot — verify before use
  unreadable, // photo could not be read
}

/// Which branch of the engine produced the verdict — lets the UI rebuild the
/// explanation in the user's language from the structured fields below,
/// while [Verdict.reasons] stays the canonical English record.
enum VerdictKind {
  registered,
  expired,
  recalled,
  cautionName, // read name close to a register entry, not exact
  cautionRegMismatch, // name matched, printed reg number disagrees
  cautionLookalike, // exact-ish name that has a confusable sibling
  notFound,
  unreadable,
}

/// The deterministic outcome of checking an Extraction against the snapshot.
/// Produced entirely by code — the model never decides this.
class Verdict {
  final VerdictStatus status;
  final Product? product; // best register match, if any
  final Recall? recall;
  final List<String> reasons; // plain-language English, ordered; canonical
  final String? lookalikeNote;
  final double matchScore; // 0..1 similarity of the register match
  final DateTime? expiryDate; // parsed pack expiry, if read

  /// Structured context for localized rendering. [kind] is null on records
  /// rebuilt from history, where the UI falls back to [reasons].
  final VerdictKind? kind;
  final String readName; // product name as read off the pack
  final String packRegNo; // reg number as printed on the pack, if read
  final bool regDrift; // reg mismatch is 1-2 characters (likely misread)

  const Verdict({
    required this.status,
    this.product,
    this.recall,
    this.reasons = const [],
    this.lookalikeNote,
    this.matchScore = 0,
    this.expiryDate,
    this.kind,
    this.readName = '',
    this.packRegNo = '',
    this.regDrift = false,
  });
}
