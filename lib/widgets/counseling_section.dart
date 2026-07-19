import 'package:flutter/material.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/prefs.dart';
import '../services/tts.dart';
import '../theme/tokens.dart';

/// "What this means" — Gemma phrases the settled verdict in the user's
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
  String _error = '';

  @override
  void initState() {
    super.initState();
    _generate();
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
      if (mounted) {
        setState(() =>
            _error = 'Guidance is unavailable right now. The verdict above still stands.');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _setLanguage(String lang) {
    if (_language == lang || _generating) return;
    Prefs.instance.language = lang;
    Tts.instance.stop();
    setState(() {
      _language = lang;
      _speaking = false;
    });
    _generate();
  }

  Future<void> _toggleSpeak() async {
    if (_speaking) {
      await Tts.instance.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    await Tts.instance.speak(_text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('What this means', style: T.h3)),
            _LangChip(
                label: 'English',
                selected: _language == 'en',
                onTap: () => _setLanguage('en')),
            const SizedBox(width: T.s2),
            _LangChip(
                label: 'Twi',
                selected: _language == 'tw',
                onTap: () => _setLanguage('tw')),
          ],
        ),
        const SizedBox(height: T.s3),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: T.neutral0,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.neutral200),
          ),
          padding: const EdgeInsets.all(T.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error.isNotEmpty)
                Text(_error, style: T.body.copyWith(color: T.neutral600))
              else if (_text.isEmpty && _generating)
                Row(
                  children: [
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: T.s3),
                    Text('Putting it in plain words…', style: T.small),
                  ],
                )
              else
                Text(_text.trim(), style: T.body.copyWith(height: 1.6)),
              if (!_generating && _text.isNotEmpty) ...[
                const SizedBox(height: T.s4),
                Row(
                  children: [
                    if (_language == 'en')
                      OutlinedButton.icon(
                        onPressed: _toggleSpeak,
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(
                                horizontal: T.s4)),
                        icon: Icon(
                            _speaking
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                            size: 18),
                        label: Text(_speaking ? 'Stop' : 'Read aloud'),
                      )
                    else
                      Text('Twi voice arrives with the online tier.',
                          style: T.caption),
                  ],
                ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rSm),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? T.neutral900 : T.neutral0,
          borderRadius: BorderRadius.circular(T.rSm),
          border: Border.all(
              color: selected ? T.neutral900 : T.neutral300),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: T.s3, vertical: T.s1 + 2),
        child: Text(
          label,
          style: T.caption.copyWith(
              color: selected ? T.neutral0 : T.neutral700,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
