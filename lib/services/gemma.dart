import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import 'counseling.dart';
import 'languages.dart';

/// A downloadable Gemma 4 model build. Both are ungated on Hugging Face.
class ModelOption {
  final String fileName; // doubles as the plugin's modelId
  final String displayName;
  final String url;
  final String sizeLabel;
  final int sizeBytes;
  final String blurb;

  const ModelOption({
    required this.fileName,
    required this.displayName,
    required this.url,
    required this.sizeLabel,
    required this.sizeBytes,
    required this.blurb,
  });
}

const e2b = ModelOption(
  fileName: 'gemma-4-E2B-it.litertlm',
  displayName: 'Gemma 4 E2B',
  url:
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
  sizeLabel: '2.4 GB',
  sizeBytes: 2600000000,
  blurb: 'Recommended. Runs on phones with 4–6 GB memory.',
);

const e4b = ModelOption(
  fileName: 'gemma-4-E4B-it.litertlm',
  displayName: 'Gemma 4 E4B',
  url:
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
  sizeLabel: '4.3 GB',
  sizeBytes: 4700000000,
  blurb: 'Stronger reading on hard packs. Needs 8 GB memory.',
);

const modelOptions = [e2b, e4b];

/// On-device Gemma 4: model install/lifecycle, vision extraction, counseling,
/// and audio Q&A. All inference is offline; the network is used only for the
/// one-time model download.
class Gemma {
  Gemma._();
  static final instance = Gemma._();

  /// Real inference needs Android/iOS or an Apple-Silicon Mac. On this
  /// project's Intel-Mac dev machine (or with --dart-define=FAKE_GEMMA=true)
  /// the service serves canned responses so the full UI remains buildable.
  static final bool fake = const bool.fromEnvironment('FAKE_GEMMA') ||
      (!kIsWeb && Platform.isMacOS && Platform.version.contains('x64'));

  InferenceModel? _model;
  Future<InferenceModel>? _modelFuture;
  bool _initialized = false;
  bool _warming = false;

  Future<void> init() async {
    if (_initialized || fake) return;
    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
    );
    _initialized = true;
  }

  Future<bool> isInstalled(ModelOption m) async {
    if (fake) return true;
    await init();
    return FlutterGemma.isModelInstalled(m.fileName);
  }

  /// True when any usable model is present.
  Future<ModelOption?> installedModel() async {
    for (final m in modelOptions) {
      if (await isInstalled(m)) return m;
    }
    return null;
  }

  /// Downloads and activates [m], emitting 0–100 progress.
  Stream<int> download(ModelOption m) {
    if (fake) {
      return Stream<int>.periodic(
              const Duration(milliseconds: 60), (i) => (i + 1) * 4)
          .take(25);
    }
    final controller = StreamController<int>();
    () async {
      try {
        await init();
        await FlutterGemma.installModel(
          modelType: ModelType.gemma4,
          fileType: ModelFileType.litertlm,
        )
            .fromNetwork(m.url)
            .withProgress((p) {
              if (!controller.isClosed) controller.add(p);
            })
            .install();
        await _reload();
        if (!controller.isClosed) {
          controller.add(100);
          await controller.close();
        }
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
          await controller.close();
        }
      }
    }();
    return controller.stream;
  }

  /// Installs a model file already on disk (e.g. copied over USB).
  Future<void> importFile(String path) async {
    if (fake) return;
    await init();
    if (!path.endsWith('.litertlm')) {
      throw ArgumentError('Expected a .litertlm file');
    }
    // On mobile the picker hands back a purgeable cache copy, and
    // flutter_gemma references fromFile paths in place, so move the file
    // somewhere permanent first. On desktop the path is the user's own
    // file: leave it where it is.
    var installPath = path;
    if (Platform.isAndroid || Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final dest = File('${docs.path}/models/${path.split('/').last}');
      await dest.parent.create(recursive: true);
      try {
        await File(path).rename(dest.path);
      } on FileSystemException {
        // Cross-volume fallback; dart:io copy streams natively.
        await File(path).copy(dest.path);
        await File(path).delete();
      }
      installPath = dest.path;
    }
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(installPath).install();
    await _reload();
  }

  Future<void> delete(ModelOption m) async {
    if (fake) return;
    await init();
    await FlutterGemma.uninstallModel(m.fileName);
    _model = null;
    _modelFuture = null;
  }

  Future<void> _reload() async {
    await _model?.close();
    _model = null;
    _modelFuture = null;
  }

  // Caches the in-flight Future (not just the resolved model) so concurrent
  // callers — e.g. a warmUp() still loading when a real scan starts — share
  // one FlutterGemma.getActiveModel() call instead of racing two.
  Future<InferenceModel> _ensureModel() {
    return _modelFuture ??= () async {
      await init();
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 4096,
        preferredBackend: PreferredBackend.gpu,
        supportImage: true,
        supportAudio: true,
        maxNumImages: 1,
        enableSpeculativeDecoding: true,
      );
      _model = model;
      return model;
    }();
  }

  /// Preloads model weights and forces first-inference costs (GPU shader
  /// compilation, JIT) to happen now instead of on the user's first real
  /// scan. Safe to call speculatively and to call more than once; never
  /// throws — a warmup failure just means the first scan pays the cost it
  /// would have paid anyway.
  Future<void> warmUp() async {
    if (fake || _warming) return;
    _warming = true;
    try {
      final model = await _ensureModel();
      final session = await model.createSession(maxOutputTokens: 1);
      try {
        await session.addQueryChunk(Message.text(text: 'Hi', isUser: true));
        await session.getResponse();
      } finally {
        await session.close();
      }
    } catch (_) {
      // Best-effort; the real scan will retry and surface errors there.
    } finally {
      _warming = false;
    }
  }

  // ── Vision extraction ──────────────────────────────────────────────────

  static const _extractionPrompt = '''
You are reading a photo of a medicine package sold in Ghana.

Extract exactly these fields and answer with ONE JSON object, nothing else:
{"legible": true, "product_name": "", "manufacturer": "", "batch_number": "", "expiry_date": "", "registration_number": "", "pack_text": ""}

Rules:
- product_name: the main brand or product name as printed, largest text on the pack. Include the strength if printed next to it (e.g. "Coartem 20/120").
- manufacturer: the company that made it, often near "Manufactured by". Use "" if not visible.
- batch_number: the value after "BN", "Batch No", "B.No" or "LOT". "" if not visible.
- expiry_date: EXACTLY as printed after "EXP", "Expiry" or "Exp. Date" (e.g. "08/2027"). Do not reformat. "" if not visible.
- registration_number: the FDA registration number if printed. "" if none.
- pack_text: every other legible line on the pack, joined with "; ".
- If the photo is not a medicine package, or no text is readable, answer {"legible": false}.
Answer with only the JSON object.''';

  /// One-shot vision pass over a pack photo → structured Extraction.
  Future<Extraction> extract(Uint8List imageBytes) async {
    if (fake) {
      await Future<void>.delayed(const Duration(seconds: 2));
      return Extraction.fromJson({
        'product_name': 'Coartem 20/120',
        'manufacturer': 'Novartis',
        'batch_number': 'F2710A',
        'expiry_date': '08/2027',
        'pack_text':
            'Artemether 20mg / Lumefantrine 120mg; 24 tablets; Keep out of reach of children; Store below 30°C',
        'legible': true,
      });
    }
    final model = await _ensureModel();
    final session = await model.createSession(
      temperature: 0.1,
      enableVisionModality: true,
      maxOutputTokens: 512,
    );
    try {
      await session.addQueryChunk(
        Message.withImage(text: _extractionPrompt, imageBytes: imageBytes, isUser: true),
      );
      // Streamed rather than a single getResponse(): the prompt puts
      // "legible" first, so an unreadable-photo answer completes as a tiny
      // JSON object within the first few tokens. Detecting that early and
      // calling stopGeneration() skips waiting out the rest of the
      // 512-token budget on the blurry/blank-photo path.
      final buffer = StringBuffer();
      await for (final chunk in session.getResponseAsync()) {
        buffer.write(chunk);
        final partial = _parseJson(buffer.toString());
        if (partial != null && partial['legible'] == false) {
          await session.stopGeneration();
          return const Extraction(legible: false);
        }
      }
      final json = _parseJson(buffer.toString());
      if (json == null) return const Extraction(legible: false);
      return Extraction.fromJson(json);
    } finally {
      await session.close();
    }
  }

  // ── Counseling ─────────────────────────────────────────────────────────

  /// Streams short plain-language guidance grounded in the verdict + pack.
  /// The verdict is settled fact from the database; the model only phrases it.
  Stream<String> counsel({
    required Extraction extraction,
    required Verdict verdict,
    required String language, // a code from languages.dart
  }) async* {
    if (fake) {
      final canned = language == 'tw'
          ? 'Saa aduro yi wɔ FDA nhoma no mu, na ne bere nntwaam ɛ. Fa no sɛnea adaka no kyerɛ. Fa sie baabi a ɛnyɛ hyew na mma mmofra nsa nnka. Sɛ ɛka wo a, kɔhwɛ pharmacist.'
          : 'This pack is in the FDA register and its expiry date has not passed. Take it exactly as the pack instructs. Store it below 30°C and keep it away from children. If you do not feel better, talk to a pharmacist or clinic.';
      for (final w in canned.split(' ')) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        yield '$w ';
      }
      return;
    }

    final lang = langBy(language);
    // Languages the model cannot hold skip generation entirely: asking costs
    // 15 seconds and returns English under an Ewe or Dagbani heading.
    if (!lang.counselFromModel) {
      yield counselingTemplate(verdict.status, language);
      return;
    }

    final model = await _ensureModel();

    // Generate, then check what actually came back. A repetition collapse in
    // the right language is a sampling accident, so one retry with a
    // different seed is worth the wait; wrong-language output is a capability
    // limit no retry fixes. Either failure ends the same way: [resetSignal]
    // tells the UI to clear the bad text, and reviewed wording from
    // counseling.dart takes its place. The user never sees the failure.
    for (var attempt = 0; attempt < 2; attempt++) {
      final strict = attempt == 1;
      final prompt = '''
You are Aduro Guard, a medicine safety helper used in Ghana.

A scan of a medicine pack produced this verdict. The verdict was decided by the Ghana FDA register database. It is settled fact; your job is only to explain it simply.

VERDICT: ${verdict.status.name}
${verdict.reasons.map((r) => '- $r').join('\n')}

WHAT THE PACK SAYS:
- Product: ${extraction.productName}
- Made by: ${extraction.manufacturer}
- Expiry: ${extraction.expiryRaw}
- Other pack text: ${extraction.packText}

${lang.promptLine}${strict ? '\nIMPORTANT: your previous answer was rejected because it was in the wrong language or repeated itself. Write the whole answer in the required language, naturally, without repeating any phrase.' : ''}
Rules:
- 3 to 5 short sentences, simple words. No dashes; use plain full sentences.
- Start by saying what the verdict means for the user.
- Use ONLY facts from the verdict and pack text above. Never invent doses, uses, or claims that are not printed on the pack.
- Do not diagnose. For health questions the answer is a pharmacist or clinic.
- Finish with the single clearest next step.
${lang.exemplar ?? ''}

Your guidance:''';

      final session = await model.createSession(
        temperature: strict ? 0.8 : 0.6,
        topK: strict ? 64 : 40,
        randomSeed: strict ? 7 : 1,
        maxOutputTokens: 256,
      );
      final buf = StringBuffer();
      var looped = false;
      try {
        await session.addQueryChunk(Message.text(text: prompt, isUser: true));
        await for (final chunk in session.getResponseAsync()) {
          buf.write(chunk);
          if (isRepetitionLoop(buf.toString())) {
            looped = true;
            await session.stopGeneration();
            break;
          }
          yield chunk;
        }
      } finally {
        await session.close();
      }
      final wrongLanguage =
          language != 'en' && looksEnglish(buf.toString());
      if (!looped && !wrongLanguage) return;
      yield resetSignal;
      if (wrongLanguage || strict) {
        yield counselingTemplate(verdict.status, language);
        return;
      }
    }
  }

  /// Emitted mid-stream when a rejected first counseling attempt is being
  /// replaced: the listening UI should clear its text and keep streaming.
  static const resetSignal = '\u0000';

  /// True when the tail of [s] has collapsed into a repetition loop. Small
  /// models fail on low-resource text by cycling a whole PHRASE, not just one
  /// word ("sɛ a no yɛn nti sɛ a no yɛn nti ..."), so this looks for any
  /// block of up to 6 words repeating three times at the end of the stream.
  static bool isRepetitionLoop(String s) {
    final w = s.trim().split(RegExp(r'\s+'));
    if (w.length < 12) return false;
    for (var k = 1; k <= 6; k++) {
      if (w.length < k * 3) break;
      final tail = w.sublist(w.length - k * 3);
      var cycles = true;
      for (var i = 0; i < k && cycles; i++) {
        if (tail[i] != tail[i + k] || tail[i] != tail[i + 2 * k]) {
          cycles = false;
        }
      }
      if (cycles) return true;
    }
    return false;
  }

  /// Heuristic: does this read as English prose? Function words only, so
  /// code-switched Twi keeping tech nouns (register, pharmacist) stays under
  /// the threshold while full English sentences go well over it.
  static bool looksEnglish(String s) {
    const fn = {
      'the', 'you', 'must', 'this', 'that', 'is', 'are', 'and', 'not',
      'with', 'your', 'it', 'of', 'to', 'for', 'before', 'was', 'has',
      'have', 'can', 'will', 'means', 'check', 'take', 'go', 'do',
    };
    final words = s
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length > 1)
        .toList();
    if (words.length < 10) return false;
    final hits = words.where(fn.contains).length;
    return hits / words.length > 0.22;
  }

  // ── Follow-up Q&A (typed or spoken) ────────────────────────────────────

  /// Starts a reusable multi-turn conversation for follow-up questions about
  /// one scanned pack. The pack facts are folded into the first question
  /// only, then persist in the chat's own history — so a second or third
  /// question in the same scan reuses the session (its KV-cache) instead of
  /// re-stating the whole pack from scratch, and the model can refer back to
  /// an earlier answer. Start a new chat (and let this one be garbage
  /// collected) if the pack facts change (a second photo merged in) or the
  /// language changes.
  Future<FollowUpChat> startFollowUpChat({
    required Extraction extraction,
    required Verdict verdict,
    required String language,
  }) async {
    if (fake) return FollowUpChat._fake();
    final model = await _ensureModel();
    final lang = langBy(language);
    final facts = '''
You are Aduro Guard, a medicine safety helper used in Ghana. The user scanned a medicine pack and now asks a question about it.

THE PACK (everything known about it):
- Product: ${extraction.productName}
- Made by: ${extraction.manufacturer}
- Batch: ${extraction.batchNumber}
- Expiry: ${extraction.expiryRaw}
- Pack text: ${extraction.packText}
- Register verdict: ${verdict.status.name}. ${verdict.reasons.join(' ')}

Rules for every answer below:
- Answer ONLY from the pack facts and verdict above. 2 to 4 short sentences, no dashes.
- If the answer is not printed on the pack (child doses, pregnancy, mixing with other medicines, what to treat), say plainly that the pack does not say, and that a pharmacist or clinic should answer it. Do not guess.
- ${lang.promptLine}''';
    final chat = await model.createChat(
      temperature: 0.4,
      topK: 40,
      supportAudio: true,
      maxOutputTokens: 192,
    );
    return FollowUpChat._(chat, facts);
  }

  /// Pulls the first JSON object out of model output, tolerating code fences
  /// and stray prose. Returns null when nothing decodable is found.
  static Map<String, Object?>? _parseJson(String raw) {
    var s = raw.replaceAll(RegExp(r'```[a-z]*', caseSensitive: false), '').trim();
    final start = s.indexOf('{');
    if (start < 0) return null;
    var depth = 0;
    for (var i = start; i < s.length; i++) {
      if (s[i] == '{') depth++;
      if (s[i] == '}') {
        depth--;
        if (depth == 0) {
          s = s.substring(start, i + 1);
          break;
        }
      }
    }
    for (final candidate in [s, s.replaceAll(RegExp(r',\s*}'), '}')]) {
      try {
        final decoded = jsonDecode(candidate);
        if (decoded is Map<String, Object?>) return decoded;
        if (decoded is Map) return decoded.cast<String, Object?>();
      } catch (_) {/* try next repair */}
    }
    return null;
  }
}

/// One scan's reusable follow-up conversation, returned by
/// [Gemma.startFollowUpChat]. Call [ask] once per question; the pack facts
/// are sent only with the first question, then live in the chat's own
/// history for every question after that.
class FollowUpChat {
  FollowUpChat._(InferenceChat chat, String factsPreamble)
      : _chat = chat,
        _factsPreamble = factsPreamble,
        _fake = false;
  FollowUpChat._fake()
      : _chat = null,
        _factsPreamble = null,
        _fake = true;

  final InferenceChat? _chat;
  String? _factsPreamble;
  final bool _fake;

  Stream<String> ask({String? typedQuestion, Uint8List? audioWavBytes}) async* {
    assert(typedQuestion != null || audioWavBytes != null);
    if (_fake) {
      const canned =
          'The pack says to store it below 30°C, away from children. Anything beyond what the pack states, like use in pregnancy, is a question for your pharmacist.';
      for (final w in canned.split(' ')) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        yield '$w ';
      }
      return;
    }
    final questionLine = audioWavBytes != null
        ? 'The question was spoken aloud and is attached as audio. First understand it, then answer it.'
        : 'Question: $typedQuestion';
    final preamble = _factsPreamble;
    _factsPreamble = null; // the pack facts are sent only once
    final text = preamble == null ? questionLine : '$preamble\n$questionLine';
    await _chat!.addQueryChunk(audioWavBytes != null
        ? Message.withAudio(text: text, audioBytes: audioWavBytes, isUser: true)
        : Message.text(text: text, isUser: true));
    await for (final r in _chat.generateChatResponseAsync()) {
      if (r is TextResponse) yield r.token;
    }
  }

  Future<void> close() async {
    if (_chat != null) await _chat.close();
  }
}
