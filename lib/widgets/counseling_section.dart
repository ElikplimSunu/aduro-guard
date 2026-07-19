import 'package:flutter/material.dart';

import '../main.dart' show AduroApp;
import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/languages.dart';
import '../services/prefs.dart';
import '../services/strings.dart';
import '../services/tts.dart';
import '../theme/tokens.dart';
import 'motion.dart';

/// "What this means": Gemma phrases the settled verdict in the user's
/// language, streamed in as it generates; spoken aloud on request.
class CounselingSection extends StatefulWidget {
  final Extraction extraction;
  final Verdict verdict;
  final int? historyId;

  const CounselingSection({
    super.key,
    required this.extraction,
    required this.verdict,
    this.historyId,
  });

  @override
  State<CounselingSection> createState() => _CounselingSectionState();
}

class _CounselingSectionState extends State<CounselingSection> {
  String _language = Prefs.instance.language;
  String _text = '';
  bool _generating = false;
  bool _speaking = false;
  bool _canSpeak = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _refreshCanSpeak();
    _generate();
  }

  Future<void> _refreshCanSpeak() async {
    final can = await Tts.instance.canSpeak(_language);
    if (mounted) setState(() => _canSpeak = can);
  }

  @override
  void dispose() {
    Tts.instance.stop();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _text = '';
      _error = '';
      _generating = true;
    });
    try {
      await for (final chunk in Gemma.instance.counsel(
        extraction: widget.extraction,
        verdict: widget.verdict,
        language: _language,
      )) {
        if (!mounted) return;
        setState(() => _text += chunk);
      }
      final trimmed = _text.trim();
      if (widget.historyId != null && trimmed.isNotEmpty) {
        await History.instance.updateCounseling(widget.historyId!, trimmed);
      }
    } catch (_) {
      if (mounted) setState(() => _error = S.guidanceUnavailable);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _setLanguage(String lang) {
    if (_language == lang || _generating) return;
    // Flips the whole app's UI language too, not just the counseling.
    AduroApp.setLanguage(context, lang);
    Tts.instance.stop();
    setState(() {
      _language = lang;
      _speaking = false;
    });
    _refreshCanSpeak();
    _generate();
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await Tts.instance.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await Tts.instance.speak(_text.trim(), _language);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.whatThisMeans, style: T.h3),
        const SizedBox(height: T.s2),
        // One horizontal row, scrollable past the edge: verdict pages are
        // long, so the picker must not stack vertically.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final l in langs) ...[
                _LangChip(
                    label: l.endonym,
                    selected: _language == l.code,
                    onTap: () => _setLanguage(l.code)),
                if (l != langs.last) const SizedBox(width: T.s2),
              ],
            ],
          ),
        ),
        const SizedBox(height: T.s3),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: c.hairline),
          ),
          padding: const EdgeInsets.all(T.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error.isNotEmpty)
                Text(_error, style: T.body.copyWith(color: c.inkMuted))
              else if (_text.isEmpty && _generating)
                Row(
                  children: [
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: T.s3),
                    Text(S.puttingPlainWords,
                        style: T.small.copyWith(color: c.inkMuted)),
                  ],
                )
              else
                Text(_text.trim(), style: T.body.copyWith(height: 1.6)),
              if (!_generating && _text.isNotEmpty) ...[
                const SizedBox(height: T.s4),
                if (_canSpeak)
                  OutlinedButton.icon(
                    onPressed: _toggleSpeak,
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding:
                            const EdgeInsets.symmetric(horizontal: T.s4)),
                    icon: FadeSwap(
                      child: Icon(
                          _speaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          key: ValueKey(_speaking),
                          size: 18),
                    ),
                    label: Text(_speaking ? S.stopReading : S.readAloud),
                  )
                else if (langBy(_language).mmsCode != null)
                  Text(S.downloadVoiceHint(langBy(_language).name),
                      style: T.caption.copyWith(color: c.inkMuted))
                else
                  Text(S.voiceRoadmap(langBy(_language).name),
                      style: T.caption.copyWith(color: c.inkMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Pressable(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(T.rSm),
          child: AnimatedContainer(
            duration: M.swap,
            curve: M.curve,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 48),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.ink : c.surface,
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(color: selected ? c.ink : c.hairlineStrong),
            ),
            padding: const EdgeInsets.symmetric(horizontal: T.s3),
            child: ExcludeSemantics(
              child: AnimatedDefaultTextStyle(
                duration: M.swap,
                curve: M.curve,
                style: T.caption.copyWith(
                    color: selected ? c.bg : c.inkMuted,
                    fontWeight: FontWeight.w600),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
