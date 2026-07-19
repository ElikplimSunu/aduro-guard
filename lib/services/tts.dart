import 'package:flutter_tts/flutter_tts.dart';

/// Speaks counseling text aloud with the device voice.
/// English only for now — no on-device Twi voice exists; the roadmap pairs
/// Twi text with Khaya TTS when online.
class Tts {
  Tts._();
  static final instance = Tts._();

  final _tts = FlutterTts();
  bool _ready = false;
  bool speaking = false;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.48); // measured, counseling pace
    _tts.setCompletionHandler(() => speaking = false);
    _tts.setCancelHandler(() => speaking = false);
    _ready = true;
  }

  Future<void> speak(String text) async {
    await _init();
    speaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    speaking = false;
    await _tts.stop();
  }
}
