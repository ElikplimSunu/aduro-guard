import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/prefs.dart';
import '../theme/tokens.dart';

class _Turn {
  final String question; // '' when the question was spoken
  String answer = '';
  bool done = false;
  _Turn(this.question);
}

/// "Ask about this pack" — hold the mic and speak, or type. Every answer is
/// grounded in the pack text; off-pack questions get referred, not guessed.
class FollowUpSection extends StatefulWidget {
  final Extraction extraction;
  final Verdict verdict;

  const FollowUpSection(
      {super.key, required this.extraction, required this.verdict});

  @override
  State<FollowUpSection> createState() => _FollowUpSectionState();
}

class _FollowUpSectionState extends State<FollowUpSection> {
  final _recorder = AudioRecorder();
  final _controller = TextEditingController();
  final List<_Turn> _turns = [];
  bool _recording = false;
  bool _answering = false;

  static final bool _micSupported =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  @override
  void dispose() {
    _recorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_answering || _recording) return;
    if (!await _recorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    await _recorder.start(
      const RecordConfig(
          encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: '${dir.path}/question.wav',
    );
    setState(() => _recording = true);
  }

  Future<void> _stopRecording({bool send = true}) async {
    if (!_recording) return;
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (!send || path == null) return;
    final bytes = await File(path).readAsBytes();
    // Anything under ~0.4s of 16kHz mono is a slip of the finger, not a question.
    if (bytes.length < 16000) return;
    _ask(audio: bytes);
  }

  Future<void> _sendTyped() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _answering) return;
    _controller.clear();
    _ask(question: q);
  }

  Future<void> _ask({String? question, Uint8List? audio}) async {
    final turn = _Turn(question ?? '');
    setState(() {
      _turns.add(turn);
      _answering = true;
    });
    try {
      await for (final chunk in Gemma.instance.ask(
        extraction: widget.extraction,
        verdict: widget.verdict,
        typedQuestion: question,
        audioWavBytes: audio,
        language: Prefs.instance.language,
      )) {
        if (!mounted) return;
        setState(() => turn.answer += chunk);
      }
    } catch (_) {
      turn.answer = 'That didn’t work — ask again.';
    } finally {
      if (mounted) {
        setState(() {
          turn.done = true;
          _answering = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ask about this pack', style: T.h3),
        const SizedBox(height: T.s1),
        Text('Answers come only from what the pack itself says.',
            style: T.small),
        const SizedBox(height: T.s3),
        for (final t in _turns) _TurnView(turn: t),
        Container(
          decoration: BoxDecoration(
            color: T.neutral0,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.neutral200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: T.s2, vertical: T.s1),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: T.body,
                  enabled: !_answering,
                  decoration: const InputDecoration(
                    hintText: 'Type a question…',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: T.s3, vertical: T.s3),
                  ),
                  onSubmitted: (_) => _sendTyped(),
                ),
              ),
              IconButton(
                onPressed: _answering ? null : _sendTyped,
                tooltip: 'Send',
                icon: const Icon(Icons.send_outlined, size: 20),
              ),
              if (_micSupported)
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  onLongPressCancel: () => _stopRecording(send: false),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _recording ? T.danger600 : T.brand700,
                      borderRadius: BorderRadius.circular(T.rSm),
                    ),
                    padding: const EdgeInsets.all(T.s2 + 2),
                    child: Icon(
                      _recording ? Icons.mic : Icons.mic_none_outlined,
                      color: T.neutral0,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: T.s1),
            ],
          ),
        ),
        if (_micSupported) ...[
          const SizedBox(height: T.s2),
          Text(
              _recording
                  ? 'Listening… let go to send.'
                  : 'Hold the gold button and speak your question.',
              style: T.caption),
        ],
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  final _Turn turn;

  const _TurnView({required this.turn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: T.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  turn.question.isEmpty
                      ? Icons.mic_none_outlined
                      : Icons.chat_bubble_outline,
                  size: 15,
                  color: T.neutral500),
              const SizedBox(width: T.s2),
              Expanded(
                child: Text(
                  turn.question.isEmpty ? 'Spoken question' : turn.question,
                  style: T.small.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: T.s2),
          if (turn.answer.isEmpty && !turn.done)
            Row(
              children: [
                const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: T.s3),
                Text('Listening to the pack…', style: T.small),
              ],
            )
          else
            Text(turn.answer.trim(), style: T.body.copyWith(height: 1.55)),
        ],
      ),
    );
  }
}
