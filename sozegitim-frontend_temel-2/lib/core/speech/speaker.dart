import 'package:flutter_tts/flutter_tts.dart';

/// Kelimeleri cihazın kendi ses motoruyla İngilizce okur.
class Speaker {
  Speaker._();

  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.speak(text);
    } catch (_) {
      // Ses motoru olmayan cihazlarda sessizce devam edilir
    }
  }
}
