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

  const ScanRecord({
    this.id,
    required this.at,
    required this.imagePath,
    required this.extraction,
    required this.verdictStatus,
    required this.verdictSummary,
    this.counseling = '',
    this.language = 'en',
  });
}
