import 'package:aduro/models/verdict.dart';
import 'package:aduro/services/prefs.dart';
import 'package:aduro/services/strings.dart';
import 'package:aduro/theme/theme.dart';
import 'package:aduro/widgets/verdict_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strings flip with the selected language and fall back to English', () {
    expect(S.scanAMedicine, 'Scan a medicine');
    Prefs.instance.language = 'tw';
    expect(S.scanAMedicine, 'Hwɛ aduro bi');
    Prefs.instance.language = 'ee'; // no Ewe chrome yet: English fallback
    expect(S.scanAMedicine, 'Scan a medicine');
    Prefs.instance.language = 'en';
  });

  testWidgets('verdict banner exposes its headline to screen readers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: VerdictBanner(
          verdict: Verdict(
            status: VerdictStatus.registered,
            reasons: ['Found in the register snapshot.'],
          ),
        ),
      ),
    ));
    final headline = tester.getSemantics(find.text('In the register'));
    expect(headline.flagsCollection.isHeader, isTrue);
    final reason =
        tester.getSemantics(find.text('Found in the register snapshot.'));
    expect(reason.label, contains('Found in the register'));
    semantics.dispose();
  });
}
