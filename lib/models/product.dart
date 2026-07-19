/// A row from the offline register snapshot.
class Product {
  final int id;
  final String name;
  final String generic;
  final String manufacturer;
  final String category;
  final String form;
  final String strength;
  final String regNo;
  final String status;
  final String source;

  const Product({
    required this.id,
    required this.name,
    this.generic = '',
    this.manufacturer = '',
    this.category = '',
    this.form = '',
    this.strength = '',
    this.regNo = '',
    this.status = 'active',
    this.source = '',
  });

  factory Product.fromRow(Map<String, Object?> r) => Product(
        id: r['id'] as int,
        name: r['name'] as String,
        generic: (r['generic'] ?? '') as String,
        manufacturer: (r['manufacturer'] ?? '') as String,
        category: (r['category'] ?? '') as String,
        form: (r['form'] ?? '') as String,
        strength: (r['strength'] ?? '') as String,
        regNo: (r['reg_no'] ?? '') as String,
        status: (r['status'] ?? 'active') as String,
        source: (r['source'] ?? '') as String,
      );
}

/// An FDA Ghana recall/alert entry.
class Recall {
  final String name;
  final String manufacturer;
  final String type; // recall | alert | unregistered
  final String reason;
  final String date;
  final String sourceUrl;

  const Recall({
    required this.name,
    this.manufacturer = '',
    this.type = 'alert',
    this.reason = '',
    this.date = '',
    this.sourceUrl = '',
  });

  factory Recall.fromRow(Map<String, Object?> r) => Recall(
        name: r['name'] as String,
        manufacturer: (r['manufacturer'] ?? '') as String,
        type: (r['type'] ?? 'alert') as String,
        reason: (r['reason'] ?? '') as String,
        date: (r['date'] ?? '') as String,
        sourceUrl: (r['source_url'] ?? '') as String,
      );
}

/// A pair of commonly confused medicine names.
class Lookalike {
  final String a;
  final String b;
  final String note;

  const Lookalike(this.a, this.b, this.note);

  factory Lookalike.fromRow(Map<String, Object?> r) => Lookalike(
      r['a'] as String, r['b'] as String, (r['note'] ?? '') as String);
}
