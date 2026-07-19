import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../models/scan.dart';

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
    await init();
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(path).install();
    await _reload();
  }

  Future<void> delete(ModelOption m) async {
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
