import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Offline voice models: Meta MMS VITS voices (ONNX) per language, downloaded
/// once and stored under `documents/voices/{mms}/`. Roughly 115 MB each.
/// Source repo: willwade/mms-tts-multilingual-models-onnx on Hugging Face.
class Voices {
  Voices._();
  static final instance = Voices._();

  static const _base =
      'https://huggingface.co/willwade/mms-tts-multilingual-models-onnx/resolve/main';

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
      final tokensReq =
          await client.getUrl(Uri.parse('$_base/$mms/tokens.txt'));
      final tokensRes = await tokensReq.close();
      if (tokensRes.statusCode != 200) {
        throw HttpException('tokens ${tokensRes.statusCode}');
      }
      final tokensBytes =
          await tokensRes.fold<List<int>>([], (a, b) => a..addAll(b));
      File('${dir.path}/tokens.txt').writeAsBytesSync(tokensBytes);
      yield 1;

      final modelReq = await client.getUrl(Uri.parse('$_base/$mms/model.onnx'));
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
