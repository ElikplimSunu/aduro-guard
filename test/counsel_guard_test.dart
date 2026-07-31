import 'package:aduro/models/verdict.dart';
import 'package:aduro/services/counseling.dart';
import 'package:aduro/services/gemma.dart';
import 'package:aduro/services/languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two checks that stop bad counseling reaching a user, plus the
/// reviewed text that replaces it.
void main() {
  group('repetition loop', () {
    test('catches a repeating phrase, not just a repeating word', () {
      // Verbatim from a Twi run on the Galaxy S24: the model cycles a
      // five-word phrase forever. A unique-word count never catches this.
      const looped =
          'Aduro Guard anaa nti sɛ, a medicine no FDA register mu sɛ registered. '
          'A no nti sɛ a no yɛn nti sɛ a no yɛn nti sɛ a no yɛn nti sɛ a no yɛn '
          'nti sɛ a no yɛn nti sɛ a no yɛn nti sɛ a no yɛn nti sɛ a no yɛn';
      expect(Gemma.isRepetitionLoop(looped), isTrue);
    });

    test('leaves healthy prose alone', () {
      expect(
          Gemma.isRepetitionLoop(counselingTemplate(
              VerdictStatus.registered, 'tw')),
          isFalse);
      expect(
          Gemma.isRepetitionLoop(
              counselingTemplate(VerdictStatus.caution, 'en')),
          isFalse);
    });
  });

  group('language drift', () {
    test('English answer under a local-language heading is caught', () {
      // Verbatim from an Ewe run: fluent English, wrong language.
      const drifted =
          'Aduro Guard here. The verdict says this medicine is registered. '
          'It is found in the Ghana FDA register. The pack says it is '
          'Melatonin 5mg. Check the expiry date yourself before you take it.';
      expect(Gemma.looksEnglish(drifted), isTrue);
    });

    test('code-switched Twi keeping FDA and medicine names is not English',
        () {
      expect(
          Gemma.looksEnglish(
              counselingTemplate(VerdictStatus.registered, 'tw')),
          isFalse);
    });
  });

  test('fallback counseling carries the scan expiry in every language', () {
    final v = Verdict(
        status: VerdictStatus.registered, expiryDate: DateTime(2027, 12, 31));
    for (final l in langs) {
      final t = counselingText(v, l.code);
      expect(t, contains('12/2027'), reason: l.code);
      expect(t, isNot(contains('{expiry}')), reason: l.code);
    }
    const bare = Verdict(status: VerdictStatus.registered);
    expect(counselingText(bare, 'tw'), isNot(contains('{expiry}')));
  });

  test('every language has reviewed text for every verdict', () {
    for (final l in langs) {
      for (final s in VerdictStatus.values) {
        expect(counselingTemplate(s, l.code), isNotEmpty,
            reason: 'missing ${l.code}/${s.name}');
      }
    }
  });
}
