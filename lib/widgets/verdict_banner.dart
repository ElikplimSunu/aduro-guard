import 'package:flutter/material.dart';

import '../models/verdict.dart';
import '../theme/tokens.dart';

/// The app's signature element: one loud, unambiguous verdict surface.
/// Everything else on the result screen stays quiet so this carries the story.
class VerdictBanner extends StatelessWidget {
  final Verdict verdict;

  const VerdictBanner({super.key, required this.verdict});

  static const _spec = {
    VerdictStatus.registered: (
      headline: 'In the register',
      icon: Icons.verified_outlined,
      fg: T.success700,
      accent: T.success600,
      bg: T.successSurface,
    ),
    VerdictStatus.expired: (
      headline: 'Expired — do not take',
      icon: Icons.event_busy_outlined,
      fg: T.danger700,
      accent: T.danger600,
      bg: T.dangerSurface,
    ),
    VerdictStatus.recalled: (
      headline: 'Do not take this',
      icon: Icons.report_outlined,
      fg: T.danger700,
      accent: T.danger600,
      bg: T.dangerSurface,
    ),
    VerdictStatus.caution: (
      headline: 'Check this carefully',
      icon: Icons.error_outline,
      fg: T.warning700,
      accent: T.warning600,
      bg: T.warningSurface,
    ),
    VerdictStatus.notFound: (
      headline: 'Not in the register snapshot',
      icon: Icons.help_outline,
      fg: T.warning700,
      accent: T.warning600,
      bg: T.warningSurface,
    ),
    VerdictStatus.unreadable: (
      headline: 'Couldn’t read the pack',
      icon: Icons.visibility_off_outlined,
      fg: T.neutral700,
      accent: T.neutral500,
      bg: T.neutral100,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _spec[verdict.status]!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border(
          left: BorderSide(color: s.accent, width: 5),
          top: BorderSide(color: s.accent.withValues(alpha: 0.14)),
          right: BorderSide(color: s.accent.withValues(alpha: 0.14)),
          bottom: BorderSide(color: s.accent.withValues(alpha: 0.14)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(T.s5, T.s5, T.s5, T.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(s.icon, size: 26, color: s.fg),
              const SizedBox(width: T.s3),
              Expanded(
                child: Text(
                  s.headline,
                  style: T.h2.copyWith(color: s.fg),
                ),
              ),
            ],
          ),
          const SizedBox(height: T.s3),
          for (final r in verdict.reasons) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: T.s2),
              child: Text(r, style: T.body.copyWith(color: T.neutral800)),
            ),
          ],
        ],
      ),
    );
  }
}
