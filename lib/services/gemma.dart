import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../models/scan.dart';
import '../models/verdict.dart';

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
  bool _initialized = false;

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
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(path).install();
    await _reload();
  }

  Future<void> delete(ModelOption m) async {
    if (fake) return;
    await init();
    await FlutterGemma.uninstallModel(m.fileName);
    _model = null;
  }

  Future<void> _reload() async {
    await _model?.close();
    _model = null;
  }

  Future<InferenceModel> _ensureModel() async {
    if (_model != null) return _model!;
    await init();
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 4096,
      preferredBackend: PreferredBackend.gpu,
      supportImage: true,
      supportAudio: true,
      maxNumImages: 1,
    );
    return _model!;
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
      final raw = await session.getResponse();
      final json = _parseJson(raw);
      if (json == null) return const Extraction(legible: false);
      return Extraction.fromJson(json);
    } finally {
      await session.close();
    }
  }

  // ── Counseling ─────────────────────────────────────────────────────────

  static const _twiExemplar = '''
Example of the tone for Twi (this one is for a registered, in-date pack):
"Saa Coartem yi wɔ FDA nhoma no mu, na ne bere nntwaam ɛ. Fa no sɛnea wɔakyerɛ wɔ adaka no so pɛpɛɛpɛ. Fa sie baabi a ɛnyɛ hyew, na mma mmofra nsa nnka. Sɛ wonte nka yiye wɔ akyi a, kɔhwɛ pharmacist anaa clinic."''';

  static const _enExemplar = '''
Example of the tone for English (this one is for a registered, in-date pack):
"This pack is in the FDA register and its expiry date has not passed. Take it exactly as the pack instructs. Store it below 30°C, away from children. If you do not feel better, talk to a pharmacist or clinic."''';

  /// Streams short plain-language guidance grounded in the verdict + pack.
  /// The verdict is settled fact from the database — the model only phrases it.
  Stream<String> counsel({
    required Extraction extraction,
    required Verdict verdict,
    required String language, // 'en' | 'tw'
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

    final model = await _ensureModel();
    final languageLine = language == 'tw'
        ? 'Write in everyday Asante Twi as spoken in Ghana. Keep medicine names, numbers and "FDA" in English.'
        : 'Write in plain everyday English.';
    final prompt = '''
You are Aduro Guard, a medicine safety helper used in Ghana.

A scan of a medicine pack produced this verdict. The verdict was decided by the Ghana FDA register database — it is settled fact; your job is only to explain it simply.

VERDICT: ${verdict.status.name}
${verdict.reasons.map((r) => '- $r').join('\n')}

WHAT THE PACK SAYS:
- Product: ${extraction.productName}
- Made by: ${extraction.manufacturer}
- Expiry: ${extraction.expiryRaw}
- Other pack text: ${extraction.packText}

$languageLine
Rules:
- 3 to 5 short sentences, simple words.
- Start by saying what the verdict means for the user.
- Use ONLY facts from the verdict and pack text above. Never invent doses, uses, or claims that are not printed on the pack.
- Do not diagnose. For health questions the answer is a pharmacist or clinic.
- Finish with the single clearest next step.
${language == 'tw' ? _twiExemplar : _enExemplar}

Your guidance:''';

    final session = await model.createSession(
      temperature: 0.6,
      topK: 40,
      maxOutputTokens: 256,
    );
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      yield* session.getResponseAsync();
    } finally {
      await session.close();
    }
  }

  // ── Follow-up Q&A (typed or spoken) ────────────────────────────────────

  /// Answers a question about the scanned pack — and only the pack.
  /// Pass [audioWavBytes] (16kHz mono WAV) for a spoken question, or
  /// [typedQuestion] for text. Questions beyond the pack get a referral, not
  /// an answer; that rule lives in the prompt and the demo shows it off.
  Stream<String> ask({
    required Extraction extraction,
    required Verdict verdict,
    String? typedQuestion,
    Uint8List? audioWavBytes,
    required String language,
  }) async* {
    assert(typedQuestion != null || audioWavBytes != null);
    if (fake) {
      const canned =
          'The pack says to store it below 30°C, away from children. Anything beyond what the pack states — like use in pregnancy — is a question for your pharmacist.';
      for (final w in canned.split(' ')) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        yield '$w ';
      }
      return;
    }

    final model = await _ensureModel();
    final languageLine = language == 'tw'
        ? 'Answer in everyday Asante Twi, keeping medicine names and numbers in English.'
        : 'Answer in plain everyday English.';
    final prompt = '''
You are Aduro Guard, a medicine safety helper used in Ghana. The user scanned a medicine pack and now asks a question about it.

THE PACK (everything known about it):
- Product: ${extraction.productName}
- Made by: ${extraction.manufacturer}
- Batch: ${extraction.batchNumber}
- Expiry: ${extraction.expiryRaw}
- Pack text: ${extraction.packText}
- Register verdict: ${verdict.status.name} — ${verdict.reasons.join(' ')}

Rules:
- Answer ONLY from the pack facts and verdict above. 2 to 4 short sentences.
- If the answer is not printed on the pack (child doses, pregnancy, mixing with other medicines, what to treat), say plainly that the pack does not say, and that a pharmacist or clinic should answer it. Do not guess.
- $languageLine
${audioWavBytes != null ? 'The question was spoken aloud and is attached as audio. First understand it, then answer it.' : 'Question: $typedQuestion'}

Your answer:''';

    final session = await model.createSession(
      temperature: 0.4,
      topK: 40,
      enableAudioModality: audioWavBytes != null,
      maxOutputTokens: 192,
    );
    try {
      await session.addQueryChunk(audioWavBytes != null
          ? Message.withAudio(
              text: prompt, audioBytes: audioWavBytes, isUser: true)
          : Message.text(text: prompt, isUser: true));
      yield* session.getResponseAsync();
    } finally {
      await session.close();
    }
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
