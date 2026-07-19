import 'package:aduro/models/product.dart';
import 'package:aduro/models/scan.dart';
import 'package:aduro/models/verdict.dart';
import 'package:aduro/services/verdict_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 7, 19);
  final engine = VerdictEngine(
    now: () => fixedNow,
    products: const [
      Product(id: 1, name: 'Coartem', generic: 'Artemether + Lumefantrine', manufacturer: 'Novartis'),
      Product(id: 2, name: 'Panadol', generic: 'Paracetamol', manufacturer: 'Haleon (GSK)'),
      Product(id: 3, name: 'Paracetamol', generic: 'Paracetamol'),
      Product(id: 4, name: 'Lonart DS', generic: 'Artemether + Lumefantrine', manufacturer: 'Bliss GVS Pharma'),
      Product(id: 5, name: 'Amatem Softgel', generic: 'Artemether + Lumefantrine', manufacturer: 'Elbe Pharma'),
      Product(id: 6, name: 'Combiart', generic: 'Artemether + Lumefantrine', manufacturer: 'Strides Pharma'),
      Product(id: 7, name: 'Lufart 20mg+120mg Tablets', generic: 'Artemether + Lumefantrine', manufacturer: 'Entrance Pharmaceuticals', regNo: 'FDA/SD.165-8501'),
    ],
    recalls: const [
      Recall(name: 'Naturcold', manufacturer: 'Fraken International (Cameroon)', type: 'alert', reason: 'Contaminated cough syrup.'),
      Recall(name: 'Galvus Met', type: 'unregistered', reason: 'Turkish-labelled pack not registered in Ghana.'),
    ],
    lookalikes: const [
      Lookalike('Coartem', 'Combiart', 'Both are registered brands — confirm which you hold.'),
    ],
  );

  group('expiry parsing', () {
    test('MM/YYYY', () {
      expect(VerdictEngine.parseExpiry('08/2027'), DateTime(2027, 8, 31, 23, 59));
    });
    test('MM/YY', () {
      expect(VerdictEngine.parseExpiry('08/27'), DateTime(2027, 8, 31, 23, 59));
    });
    test('EXP prefix and month name', () {
      expect(VerdictEngine.parseExpiry('EXP: AUG 2027'), DateTime(2027, 8, 31, 23, 59));
    });
    test('DD.MM.YYYY', () {
      expect(VerdictEngine.parseExpiry('15.08.2027'), DateTime(2027, 8, 15, 23, 59));
    });
    test('ISO year first', () {
      expect(VerdictEngine.parseExpiry('2027-08'), DateTime(2027, 8, 31, 23, 59));
    });
    test('usable through its expiry month', () {
      // Now = 2026-07-19; expiry 07/2026 ends 2026-07-31 → not yet expired.
      expect(VerdictEngine.parseExpiry('07/2026')!.isBefore(fixedNow), isFalse);
    });
    test('garbage returns null', () {
      expect(VerdictEngine.parseExpiry('see carton'), isNull);
    });
  });

  group('registration numbers', () {
    test('old FDB prefix and punctuation drift still hit the FDA entry', () {
      // Fuzzy name alone lands short of a strong match here; the reg number
      // printed on the pack (old FDB prefix, as on real Lufart boxes) closes it.
      final v = engine.evaluate(const Extraction(
          productName: 'Lufart Tablets',
          regNo: 'FDB/SD.165-8501',
          expiryRaw: '09/2026'));
      expect(v.status, VerdictStatus.registered);
      expect(v.product!.name, 'Lufart 20mg+120mg Tablets');
    });

    test('a genuine reg number on a wrong-named pack does not upgrade', () {
      final v = engine.evaluate(const Extraction(
          productName: 'Malacure', regNo: 'FDA/SD.165-8501'));
      expect(v.status, isNot(VerdictStatus.registered));
    });

    test('normalizeReg', () {
      expect(VerdictEngine.normalizeReg('FDB/SD.165-8501'),
          VerdictEngine.normalizeReg('fda/sd 165 8501'));
    });
  });

  group('verdicts', () {
    test('registered brand, in date', () {
      final v = engine.evaluate(const Extraction(
          productName: 'Coartem', manufacturer: 'Novartis', expiryRaw: '08/2027'));
      expect(v.status, VerdictStatus.registered);
      expect(v.product!.name, 'Coartem');
    });

    test('brand plus strength still counts as an exact read', () {
      final v = engine.evaluate(const Extraction(
          productName: 'Coartem 20/120',
          manufacturer: 'Novartis',
          expiryRaw: '08/2027'));
      expect(v.status, VerdictStatus.registered);
      expect(v.lookalikeNote, isNotNull); // note stays informational
    });

    test('generic name matches generic row', () {
      final v = engine.evaluate(const Extraction(productName: 'Paracetamol 500mg'));
      expect(v.status, VerdictStatus.registered);
    });

    test('expired trumps registered', () {
      final v = engine.evaluate(const Extraction(
          productName: 'Coartem', expiryRaw: 'EXP 06/2026'));
      expect(v.status, VerdictStatus.expired);
      expect(v.product!.name, 'Coartem'); // still tells you what it is
    });

    test('recalled trumps expired', () {
      final v = engine.evaluate(const Extraction(
          productName: 'Naturcold', expiryRaw: '01/2020'));
      expect(v.status, VerdictStatus.recalled);
      expect(v.recall!.name, 'Naturcold');
    });

    test('unregistered-alert product is flagged', () {
      final v = engine.evaluate(const Extraction(productName: 'Galvus Met'));
      expect(v.status, VerdictStatus.recalled);
    });

    test('near-miss spelling lands in caution, names the neighbour', () {
      final v = engine.evaluate(const Extraction(productName: 'Pamadol'));
      expect(v.status, VerdictStatus.caution);
      expect(v.product!.name, 'Panadol');
    });

    test('unknown product is notFound, honest copy', () {
      final v = engine.evaluate(const Extraction(productName: 'Zykofast Ultra'));
      expect(v.status, VerdictStatus.notFound);
      expect(v.reasons.first, contains('not found'));
    });

    test('exact match with lookalike pair stays registered, carries the note', () {
      final v = engine.evaluate(const Extraction(productName: 'Combiart', expiryRaw: '12/2027'));
      expect(v.status, VerdictStatus.registered);
      expect(v.lookalikeNote, contains('Coartem'));
    });

    test('inexact read of a lookalike-paired name downgrades to caution', () {
      final v = engine.evaluate(const Extraction(productName: 'Combiar', expiryRaw: '12/2027'));
      expect(v.status, VerdictStatus.caution);
    });

    test('unreadable photo', () {
      final v = engine.evaluate(const Extraction(legible: false));
      expect(v.status, VerdictStatus.unreadable);
    });
  });
}
