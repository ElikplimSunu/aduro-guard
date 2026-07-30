import 'package:flutter/material.dart';

import '../models/verdict.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';

/// The translated headline for a verdict status; shared with history and
/// the screen-reader announcement on the result screen.
String verdictHeadline(VerdictStatus status) => switch (status) {
      VerdictStatus.registered => S.vRegistered,
      VerdictStatus.expired => S.vExpired,
      VerdictStatus.recalled => S.vRecalled,
      VerdictStatus.caution => S.vCaution,
      VerdictStatus.notFound => S.vNotFound,
      VerdictStatus.unreadable => S.vUnreadable,
    };

/// The verdict explanation in the current UI language, rebuilt from the
/// verdict's structured fields. The engine's English [Verdict.reasons] stay
/// the canonical record (history, model grounding); records without a kind
/// (old history rows) fall back to them.
List<String> localizedReasons(Verdict v) {
  final k = v.kind;
  if (k == null) return v.reasons;
  String my(DateTime d) => '${d.month}/${d.year}';
  final name = v.product?.name ?? '';
  final maker = v.product?.manufacturer ?? '';
  return switch (k) {
    VerdictKind.unreadable => [S.rUnreadable],
    VerdictKind.recalled => [
        S.rRecalled(v.recall?.name ?? v.readName),
        if ((v.recall?.reason ?? '').isNotEmpty) v.recall!.reason,
        S.rRecalledAction,
      ],
    VerdictKind.expired => [
        if (v.expiryDate != null) S.rExpired(my(v.expiryDate!)),
        if (name.isNotEmpty) S.rExpiredButListed(name),
        S.rExpiredAction,
      ],
    VerdictKind.registered => [
        S.rFoundAs(name, maker),
        if (v.expiryDate != null)
          S.rStillInDate(my(v.expiryDate!))
        else
          S.rNoExpiryRead,
        ?v.lookalikeNote,
      ],
    VerdictKind.cautionLookalike => [
        S.rFoundAs(name, maker),
        ?v.lookalikeNote,
        S.rSpellingTrick,
      ],
    VerdictKind.cautionName => [
        S.rCloseName(v.readName, name),
        S.rSpellingTrick,
        ?v.lookalikeNote,
      ],
    VerdictKind.cautionRegMismatch => [
        S.rRegMismatch(name, v.packRegNo, v.product?.regNo ?? ''),
        v.regDrift ? S.rRegDriftHint : S.rRegCounterfeitHint,
        S.rVerifyFda,
      ],
    VerdictKind.notFound => [
        S.rNotFound(v.readName),
        S.rNotProofFake,
        S.rVerifyFda,
      ],
  };
}

/// The app's signature element: one loud, unambiguous verdict surface.
/// Everything else on the result screen stays quiet so this carries the story.
class VerdictBanner extends StatelessWidget {
  final Verdict verdict;

  const VerdictBanner({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final headline = verdictHeadline(verdict.status);
    final (icon, accent, fg, bg) = switch (verdict.status) {
      VerdictStatus.registered => (
          Icons.verified_outlined,
          c.successAccent,
          c.successText,
          c.successSurface,
        ),
      VerdictStatus.expired => (
          Icons.event_busy_outlined,
          c.dangerAccent,
          c.dangerText,
          c.dangerSurface,
        ),
      VerdictStatus.recalled => (
          Icons.report_outlined,
          c.dangerAccent,
          c.dangerText,
          c.dangerSurface,
        ),
      VerdictStatus.caution => (
          Icons.error_outline,
          c.warningAccent,
          c.warningText,
          c.warningSurface,
        ),
      VerdictStatus.notFound => (
          Icons.help_outline,
          c.warningAccent,
          c.warningText,
          c.warningSurface,
        ),
      VerdictStatus.unreadable => (
          Icons.visibility_off_outlined,
          c.muteAccent,
          c.muteText,
          c.muteSurface,
        ),
    };

    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(T.rLg),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // The signature detail: a solid accent spine on the left edge.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 5,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(T.s5 + 5, T.s5, T.s5, T.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(child: Icon(icon, size: 26, color: fg)),
                      const SizedBox(width: T.s3),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child:
                              Text(headline, style: T.h2.copyWith(color: fg)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: T.s3),
                  for (final r in localizedReasons(verdict))
                    Padding(
                      padding: const EdgeInsets.only(bottom: T.s2),
                      child: Text(r, style: T.body.copyWith(color: c.ink)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
