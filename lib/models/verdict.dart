import 'product.dart';

enum VerdictStatus {
  registered, // found in register snapshot, nothing wrong
  expired, // pack expiry date has passed
  recalled, // matches an FDA recall/alert entry
  caution, // near-miss name, lookalike risk, or low-confidence read
  notFound, // not in this snapshot — verify before use
  unreadable, // photo could not be read
}

/// The deterministic outcome of checking an Extraction against the snapshot.
/// Produced entirely by code — the model never decides this.
class Verdict {
  final VerdictStatus status;
  final Product? product; // best register match, if any
  final Recall? recall;
  final List<String> reasons; // plain-language, ordered, shown in UI
  final String? lookalikeNote;
  final double matchScore; // 0..1 similarity of the register match
  final DateTime? expiryDate; // parsed pack expiry, if read

  const Verdict({
    required this.status,
    this.product,
    this.recall,
    this.reasons = const [],
    this.lookalikeNote,
    this.matchScore = 0,
    this.expiryDate,
  });
}
