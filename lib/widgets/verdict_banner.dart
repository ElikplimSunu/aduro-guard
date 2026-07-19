import 'package:flutter/material.dart';

import '../models/verdict.dart';
import '../theme/tokens.dart';

/// The app's signature element: one loud, unambiguous verdict surface.
/// Everything else on the result screen stays quiet so this carries the story.
class VerdictBanner extends StatelessWidget {
  final Verdict verdict;

  const VerdictBanner({super.key, required this.verdict});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (headline, icon, accent, fg, bg) = switch (verdict.status) {
      VerdictStatus.registered => (
          'In the register',
          Icons.verified_outlined,
          c.successAccent,
          c.successText,
          c.successSurface,
        ),
      VerdictStatus.expired => (
          'Expired',
          Icons.event_busy_outlined,
          c.dangerAccent,
          c.dangerText,
          c.dangerSurface,
        ),
      VerdictStatus.recalled => (
          'Do not take this',
          Icons.report_outlined,
          c.dangerAccent,
          c.dangerText,
          c.dangerSurface,
        ),
      VerdictStatus.caution => (
          'Check this carefully',
          Icons.error_outline,
          c.warningAccent,
          c.warningText,
          c.warningSurface,
        ),
      VerdictStatus.notFound => (
          'Not in the register snapshot',
          Icons.help_outline,
          c.warningAccent,
          c.warningText,
          c.warningSurface,
        ),
      VerdictStatus.unreadable => (
          'Couldn’t read the pack',
          Icons.visibility_off_outlined,
          c.muteAccent,
          c.muteText,
          c.muteSurface,
        ),
    };

    return Container(
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
                    Icon(icon, size: 26, color: fg),
                    const SizedBox(width: T.s3),
                    Expanded(
                      child: Text(headline, style: T.h2.copyWith(color: fg)),
                    ),
                  ],
                ),
                const SizedBox(height: T.s3),
                for (final r in verdict.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: T.s2),
                    child: Text(r, style: T.body.copyWith(color: c.ink)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
