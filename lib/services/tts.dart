import 'dart:async';
import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'languages.dart';
import 'voices.dart';

/// Runs inside the persistent TTS worker isolate. Keeps at most one loaded
/// sherpa-onnx voice resident, reloading only when the requested language
/// (mms code) differs from what's cached, so repeat "listen" taps skip the
/// ~1s isolate-spawn + model-load cost that used to be paid on every call.
void _ttsWorkerMain(SendPort mainSendPort) {
  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  sherpa.initBindings();
  String? loadedMms;
  sherpa.OfflineTts? tts;

  void ensureLoaded(String mms, String modelPath, String tokensPath) {
    if (loadedMms == mms && tts != null) return;
    tts?.free();
    tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
      model: sherpa.OfflineTtsModelConfig(
        vits: sherpa.OfflineTtsVitsModelConfig(
          model: modelPath,
          tokens: tokensPath,
        ),
        numThreads: 2,
        debug: false,
      ),
    ));
    loadedMms = mms;
  }

  commandPort.listen((dynamic message) {
    final map = message as Map<String, Object?>;
    final replyPort = map['reply'] as SendPort;
    final cmd = map['cmd'] as String;
    try {
      switch (cmd) {
        case 'warm':
          ensureLoaded(map['mms'] as String, map['modelPath'] as String,
              map['tokensPath'] as String);
          replyPort.send(null);
        case 'speak':
          ensureLoaded(map['mms'] as String, map['modelPath'] as String,
              map['tokensPath'] as String);
          final audio =
              tts!.generate(text: map['text'] as String, sid: 0, speed: 1.0);
          sherpa.writeWave(
            filename: map['outPath'] as String,
            samples: audio.samples,
            sampleRate: audio.sampleRate,
          );
          replyPort.send(null);
        case 'dispose':
          tts?.free();
          tts = null;
          loadedMms = null;
          replyPort.send(null);
        default:
          replyPort.send('unknown command: $cmd');
      }
    } catch (e) {
      replyPort.send(e.toString());
    }
  });
}

/// Speaks counseling text aloud, fully offline.
/// English uses the device voice; Twi, Ewe and Hausa use downloaded MMS
/// voices synthesized on-device with sherpa-onnx, via a persistent worker
/// isolate that keeps the current language's voice model warm so repeat
/// "listen" taps don't re-pay the ~1s model load.
class Tts {
  Tts._();
  static final instance = Tts._();

  final _device = FlutterTts();
  final _player = AudioPlayer();
  bool _deviceReady = false;
  bool speaking = false;
  bool _busy = false;

  Future<SendPort>? _workerPort;
  String? _warmMms;

  Future<void> _initDevice() async {
    if (_deviceReady) return;
    await _device.setLanguage('en-GB');
    await _device.setSpeechRate(0.48); // measured, counseling pace
    _device.setCompletionHandler(() => speaking = false);
    _device.setCancelHandler(() => speaking = false);
    _player.onPlayerComplete.listen((_) => speaking = false);
    _deviceReady = true;
  }

  Future<SendPort> _ensureWorker() {
    return _workerPort ??= () async {
      final receive = ReceivePort();
      await Isolate.spawn(_ttsWorkerMain, receive.sendPort);
      return await receive.first as SendPort;
    }();
  }

  Future<Object?> _send(Map<String, Object?> message) async {
    final commandPort = await _ensureWorker();
    final reply = ReceivePort();
    commandPort.send({...message, 'reply': reply.sendPort});
    final result = await reply.first;
    reply.close();
    return result;
  }

  /// Whether "read aloud" can work right now for this language.
  Future<bool> canSpeak(String langCode) async {
    if (langCode == 'en') return true;
    final mms = langBy(langCode).mmsCode;
    if (mms == null) return false;
    return Voices.instance.isInstalled(mms);
  }

  /// Preloads the voice model for [langCode] without speaking, so the next
  /// "listen" tap in that language is fast. Safe to call speculatively (app
  /// start, language switch, or while a scan is being processed); a no-op for
  /// English (the device voice needs no warmup), an uninstalled voice, or a
  /// language that's already warm.
  Future<void> warmUp(String langCode) async {
    if (langCode == 'en') return;
    final mms = langBy(langCode).mmsCode;
    if (mms == null || _warmMms == mms) return;
    if (!await Voices.instance.isInstalled(mms)) return;
    try {
      final dir = await Voices.instance.dirFor(mms);
      await _send({
        'cmd': 'warm',
        'mms': mms,
        'modelPath': '${dir.path}/model.onnx',
        'tokensPath': '${dir.path}/tokens.txt',
      });
      _warmMms = mms;
    } catch (_) {
      // Best-effort; a real speak() call will retry and surface errors there.
    }
  }

  Future<void> speak(String text, String langCode) async {
    if (_busy) return; // a previous speak() is still in flight
    _busy = true;
    try {
      await _initDevice();
      speaking = true;
      if (langCode == 'en') {
        await _device.speak(text);
        return;
      }
      final mms = langBy(langCode).mmsCode;
      if (mms == null) {
        speaking = false;
        return;
      }
      final dir = await Voices.instance.dirFor(mms);
      final docs = await getApplicationDocumentsDirectory();
      final out = '${docs.path}/speech.wav';
      // Cached across calls: the worker isolate reuses its loaded voice
      // model whenever mms matches what it already has resident.
      final error = await _send({
        'cmd': 'speak',
        'mms': mms,
        'modelPath': '${dir.path}/model.onnx',
        'tokensPath': '${dir.path}/tokens.txt',
        'text': text,
        'outPath': out,
      });
      if (error != null) throw StateError(error.toString());
      _warmMms = mms;
      if (!speaking) return; // stopped while synthesizing
      await _player.play(DeviceFileSource(out));
    } catch (_) {
      speaking = false;
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    speaking = false;
    await _device.stop();
    await _player.stop();
  }
}
