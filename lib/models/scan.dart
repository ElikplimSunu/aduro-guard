import 'dart:convert';

/// What Gemma's vision pass extracted from a pack photo.
/// Fields are raw strings as read; parsing/decisions happen in the engine.
class Extraction {
  final String productName;
  final String manufacturer;
  final String batchNumber;
  final String expiryRaw;
  final String regNo;
  final String packText; // everything legible on the pack, for grounded Q&A
  final bool legible; // false => model could not read the pack at all

  const Extraction({
    this.productName = '',
    this.manufacturer = '',
    this.batchNumber = '',
    this.expiryRaw = '',
    this.regNo = '',
    this.packText = '',
    this.legible = true,
  });

  factory Extraction.fromJson(Map<String, Object?> j) {
    String s(Object? v) {
      final t = (v ?? '').toString().trim();
      // Models sometimes emit literal null/none/unknown for absent fields.
      const absent = {'null', 'none', 'unknown', 'n/a', 'not visible', '-'};
      return absent.contains(t.toLowerCase()) ? '' : t;
    }

    return Extraction(
      productName: s(j['product_name']),
      manufacturer: s(j['manufacturer']),
      batchNumber: s(j['batch_number']),
      expiryRaw: s(j['expiry_date']),
      regNo: s(j['registration_number']),
      packText: s(j['pack_text']),
      legible: j['legible'] != false,
    );
  }

  Map<String, Object?> toJson() => {
        'product_name': productName,
        'manufacturer': manufacturer,
        'batch_number': batchNumber,
        'expiry_date': expiryRaw,
        'registration_number': regNo,
        'pack_text': packText,
        'legible': legible,
      };

  bool get isEmpty => productName.isEmpty && packText.isEmpty;

  /// Field-wise merge of a second read (another face of the box): this
  /// read's non-empty fields win, the other fills the gaps. Pack text
  /// concatenates so follow-up answers can draw on every photographed face.
  Extraction merge(Extraction other) => Extraction(
        productName:
            productName.isNotEmpty ? productName : other.productName,
        manufacturer:
            manufacturer.isNotEmpty ? manufacturer : other.manufacturer,
        batchNumber:
            batchNumber.isNotEmpty ? batchNumber : other.batchNumber,
        expiryRaw: expiryRaw.isNotEmpty ? expiryRaw : other.expiryRaw,
        regNo: regNo.isNotEmpty ? regNo : other.regNo,
        packText:
            [packText, other.packText].where((t) => t.isNotEmpty).join('\n'),
        legible: legible || other.legible,
      );
}

/// One question and its answer, saved with the scan.
class QaTurn {
  final String question; // '' when the question was spoken
  final String answer;

  const QaTurn(this.question, this.answer);

  Map<String, Object?> toJson() => {'q': question, 'a': answer};

  static List<QaTurn> decode(String raw) {
    if (raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => QaTurn((e['q'] ?? '') as String, (e['a'] ?? '') as String))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static String encode(List<QaTurn> turns) =>
      jsonEncode(turns.map((t) => t.toJson()).toList());
}

/// A saved scan (history).
class ScanRecord {
  final int? id;
  final DateTime at;
  final String imagePath;
  final Extraction extraction;
  final String verdictStatus;
  final String verdictSummary;
  final String counseling;
  final String language;
  final List<QaTurn> qa;

  const ScanRecord({
    this.id,
    required this.at,
    required this.imagePath,
    required this.extraction,
    required this.verdictStatus,
    required this.verdictSummary,
    this.counseling = '',
    this.language = 'en',
    this.qa = const [],
  });
}
