import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'languages.dart';
import 'voices.dart';

/// Speaks counseling text aloud, fully offline.
/// English uses the device voice; Twi, Ewe and Hausa use downloaded MMS
/// voices synthesized on-device with sherpa-onnx.
class Tts {
  Tts._();
  static final instance = Tts._();

  final _device = FlutterTts();
  final _player = AudioPlayer();
  bool _deviceReady = false;
  bool speaking = false;

  Future<void> _initDevice() async {
    if (_deviceReady) return;
    await _device.setLanguage('en-GB');
    await _device.setSpeechRate(0.48); // measured, counseling pace
    _device.setCompletionHandler(() => speaking = false);
    _device.setCancelHandler(() => speaking = false);
    _player.onPlayerComplete.listen((_) => speaking = false);
    _deviceReady = true;
  }

  /// Whether "read aloud" can work right now for this language.
  Future<bool> canSpeak(String langCode) async {
    if (langCode == 'en') return true;
    final mms = langBy(langCode).mmsCode;
    if (mms == null) return false;
    return Voices.instance.isInstalled(mms);
  }

  Future<void> speak(String text, String langCode) async {
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
    try {
      final dir = await Voices.instance.dirFor(mms);
      final docs = await getApplicationDocumentsDirectory();
      final out = '${docs.path}/speech.wav';
      // ponytail: the whole synth runs in a worker isolate that loads the
      // model fresh each time (adds ~1s). Keeps the UI smooth with zero
      // shared state; a persistent worker is the upgrade if latency matters.
      await Isolate.run(() {
        sherpa.initBindings();
        final tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
          model: sherpa.OfflineTtsModelConfig(
            vits: sherpa.OfflineTtsVitsModelConfig(
              model: '${dir.path}/model.onnx',
              tokens: '${dir.path}/tokens.txt',
            ),
            numThreads: 2,
            debug: false,
          ),
        ));
        try {
          final audio = tts.generate(text: text, sid: 0, speed: 1.0);
          sherpa.writeWave(
              filename: out,
              samples: audio.samples,
              sampleRate: audio.sampleRate);
        } finally {
          tts.free();
        }
      });
      if (!speaking) return; // stopped while synthesizing
      await _player.play(DeviceFileSource(out));
    } catch (_) {
      speaking = false;
    }
  }

  Future<void> stop() async {
    speaking = false;
    await _device.stop();
    await _player.stop();
  }
}
