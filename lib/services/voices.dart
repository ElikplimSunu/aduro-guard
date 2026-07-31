import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Offline voice models: VITS voices (ONNX) per language, downloaded once and
/// stored under `documents/voices/{code}/`. Roughly 115 MB each.
///
/// These come from Meta's MMS project as ready-made ONNX exports. Languages
/// MMS does not cover ship as text; see docs/voices.md for the Dagbani export
/// attempt and exactly where it stops. The _ownBase branch below is the hook
/// for voices we export ourselves once one of them actually runs.
class Voices {
  Voices._();
  static final instance = Voices._();

  static const _mmsBase =
      'https://huggingface.co/willwade/mms-tts-multilingual-models-onnx/resolve/main';
  static const _ownBase =
      'https://github.com/ElikplimSunu/aduro-guard/releases/download/voices-v1';

  /// Where each file for [code] lives. MMS voices sit in per-language folders;
  /// our own exports are flat release assets, so the code becomes a prefix.
  static ({String model, String tokens}) _urls(String code) =>
      _mmsVoices.contains(code)
          ? (model: '$_mmsBase/$code/model.onnx',
              tokens: '$_mmsBase/$code/tokens.txt')
          : (model: '$_ownBase/$code-model.onnx',
              tokens: '$_ownBase/$code-tokens.txt');

  static const _mmsVoices = {'aka', 'ewe', 'hau'};

  Future<Directory> dirFor(String mms) async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/voices/$mms');
  }

  Future<bool> isInstalled(String mms) async {
    final dir = await dirFor(mms);
    final model = File('${dir.path}/model.onnx');
    final tokens = File('${dir.path}/tokens.txt');
    // A partial download is not an install; the real model is >100 MB.
    return tokens.existsSync() &&
        model.existsSync() &&
        model.lengthSync() > 1000000;
  }

  /// Downloads tokens + model, emitting 0-100 progress.
  Stream<int> download(String mms) async* {
    final dir = await dirFor(mms);
    dir.createSync(recursive: true);
    final client = HttpClient();
    try {
      final urls = _urls(mms);
      final tokensReq = await client.getUrl(Uri.parse(urls.tokens));
      final tokensRes = await tokensReq.close();
      if (tokensRes.statusCode != 200) {
        throw HttpException('tokens ${tokensRes.statusCode}');
      }
      final tokensBytes =
          await tokensRes.fold<List<int>>([], (a, b) => a..addAll(b));
      File('${dir.path}/tokens.txt').writeAsBytesSync(tokensBytes);
      yield 1;

      final modelReq = await client.getUrl(Uri.parse(urls.model));
      final modelRes = await modelReq.close();
      if (modelRes.statusCode != 200) {
        throw HttpException('model ${modelRes.statusCode}');
      }
      final total = modelRes.contentLength;
      final tmp = File('${dir.path}/model.onnx.part');
      final sink = tmp.openWrite();
      var received = 0;
      var lastEmit = 0;
      try {
        await for (final chunk in modelRes) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            final p = 1 + (received * 99 ~/ total);
            if (p > lastEmit) {
              lastEmit = p;
              yield p;
            }
          }
        }
      } finally {
        await sink.close();
      }
      tmp.renameSync('${dir.path}/model.onnx');
      yield 100;
    } finally {
      client.close();
    }
  }

  Future<void> delete(String mms) async {
    final dir = await dirFor(mms);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}
