import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/prefs.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import 'motion.dart';

class _Turn {
  final String question; // '' when the question was spoken
  String answer = '';
  bool done = false;
  _Turn(this.question);
}

/// "Ask about this pack": hold the mic and speak, or type. Every answer is
/// grounded in the pack text; off-pack questions get referred, not guessed.
class FollowUpSection extends StatefulWidget {
  final Extraction extraction;
  final Verdict verdict;

  /// Persist the thread against this scan, and show what was asked before.
  final int? historyId;
  final List<QaTurn> initialTurns;

  const FollowUpSection({
    super.key,
    required this.extraction,
    required this.verdict,
    this.historyId,
    this.initialTurns = const [],
  });

  @override
  State<FollowUpSection> createState() => _FollowUpSectionState();
}

class _FollowUpSectionState extends State<FollowUpSection> {
  final _recorder = AudioRecorder();
  final _controller = TextEditingController();
  late final List<_Turn> _turns = [
    for (final t in widget.initialTurns)
      (_Turn(t.question)
        ..answer = t.answer
        ..done = true),
  ];
  bool _recording = false;
  bool _answering = false;

  // Reused across every question in this scan so the model isn't re-fed the
  // full pack facts each time; restarted only if the language changes.
  Future<FollowUpChat>? _chatFuture;
  String? _chatLanguage;

  static final bool _micSupported =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  Future<FollowUpChat> _ensureChat() {
    final lang = Prefs.instance.language;
    if (_chatFuture != null && _chatLanguage == lang) return _chatFuture!;
    _chatFuture?.then((c) => c.close());
    _chatLanguage = lang;
    return _chatFuture = Gemma.instance.startFollowUpChat(
      extraction: widget.extraction,
      verdict: widget.verdict,
      language: lang,
    );
  }

  @override
  void dispose() {
    _chatFuture?.then((c) => c.close());
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
      final chat = await _ensureChat();
      await for (final chunk
          in chat.ask(typedQuestion: question, audioWavBytes: audio)) {
        if (!mounted) return;
        setState(() => turn.answer += chunk);
      }
    } catch (_) {
      turn.answer = S.askFailed;
    } finally {
      if (mounted) {
        setState(() {
          turn.done = true;
          _answering = false;
        });
      }
      _save();
    }
  }

  /// The thread is part of the record: someone who scanned a pack and asked
  /// "can I take this with my other medicine" should find that answer again
  /// later, not have to re-ask an offline model.
  void _save() {
    final id = widget.historyId;
    if (id == null) return;
    History.instance.updateQa(
        id,
        QaTurn.encode([
          for (final t in _turns.where((t) => t.done && t.answer.isNotEmpty))
            QaTurn(t.question, t.answer.trim()),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.askAboutPack, style: T.h3),
        const SizedBox(height: T.s1),
        Text(S.answersFromPack, style: T.small.copyWith(color: c.inkMuted)),
        const SizedBox(height: T.s3),
        for (final t in _turns) _TurnView(turn: t),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: c.hairline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: T.s2, vertical: T.s1),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: T.body.copyWith(color: c.ink),
                  enabled: !_answering,
                  decoration: InputDecoration(
                    hintText: S.typeQuestion,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: T.s3, vertical: T.s3),
                  ),
                  onSubmitted: (_) => _sendTyped(),
                ),
              ),
              IconButton(
                onPressed: _answering ? null : _sendTyped,
                tooltip: S.send,
                icon: const Icon(Icons.send_outlined, size: 20),
              ),
              if (_micSupported)
                Semantics(
                  button: true,
                  label: S.spokenQuestion,
                  hint: S.holdToRecordHint,
                  child: Pressable(
                  child: GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    onLongPressCancel: () => _stopRecording(send: false),
                    child: AnimatedContainer(
                      duration: M.swap,
                      curve: M.curve,
                      constraints:
                          const BoxConstraints(minWidth: 44, minHeight: 44),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _recording ? c.dangerAccent : c.brandPrimary,
                        borderRadius: BorderRadius.circular(T.rSm),
                      ),
                      child: FadeSwap(
                        child: Icon(
                          _recording ? Icons.mic : Icons.mic_none_outlined,
                          key: ValueKey(_recording),
                          color: c.onBrandPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                ),
              const SizedBox(width: T.s1),
            ],
          ),
        ),
        if (_micSupported) ...[
          const SizedBox(height: T.s2),
          FadeSwap(
            child: Text(_recording ? S.listeningLetGo : S.holdAndSpeak,
                key: ValueKey(_recording),
                style: T.caption.copyWith(color: c.inkMuted)),
          ),
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
    final c = context.c;
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
                  color: c.inkFaint),
              const SizedBox(width: T.s2),
              Expanded(
                child: Text(
                  turn.question.isEmpty ? S.spokenQuestion : turn.question,
                  style: T.small
                      .copyWith(color: c.inkMuted, fontWeight: FontWeight.w600),
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
                Text(S.listeningToPack,
                    style: T.small.copyWith(color: c.inkMuted)),
              ],
            )
          else
            Text(turn.answer.trim(),
                style: T.body.copyWith(height: 1.55, color: c.ink)),
        ],
      ),
    );
  }
}
