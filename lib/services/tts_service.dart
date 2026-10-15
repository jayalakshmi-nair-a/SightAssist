import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/localization/app_localizations.dart';

enum TtsState { playing, stopped, paused }

class TtsService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  TtsState _ttsState = TtsState.stopped;
  String _lastSpokenText = '';

  TtsState get ttsState => _ttsState;
  bool get isSpeaking => _ttsState == TtsState.playing;
  String get lastSpokenText => _lastSpokenText;

  Future<void> initialize({
    AppLanguage language = AppLanguage.english,
    double rate = 0.5,
    double pitch = 1.0,
    double volume = 1.0,
  }) async {
    try {
      await _flutterTts.setLanguage(language.ttsLocale);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setVolume(volume);

      _flutterTts.setStartHandler(() {
        _ttsState = TtsState.playing;
        Future.microtask(() => notifyListeners());
      });

      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.stopped;
        Future.microtask(() => notifyListeners());
      });

      _flutterTts.setErrorHandler((msg) {
        _ttsState = TtsState.stopped;
        print("TtsService Error: $msg");
        Future.microtask(() => notifyListeners());
      });
    } catch (e) {
      print("Error initializing TtsService: $e");
    }
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (text.trim().isEmpty) return;
    try {
      if (interrupt && isSpeaking) {
        await stop();
      }
      _lastSpokenText = text;
      _ttsState = TtsState.playing;
      notifyListeners();

      await _flutterTts.speak(text);
    } catch (e) {
      print("TtsService speak error: $e");
      _ttsState = TtsState.stopped;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _ttsState = TtsState.stopped;
      notifyListeners();
    } catch (e) {
      print("TtsService stop error: $e");
    }
  }

  Future<void> replay() async {
    if (_lastSpokenText.isNotEmpty) {
      await speak(_lastSpokenText);
    }
  }

  Future<void> updateLanguage(AppLanguage language) async {
    try {
      await _flutterTts.setLanguage(language.ttsLocale);
    } catch (e) {
      print("Error updating TTS language: $e");
    }
  }

  Future<void> updateSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.1, 1.0));
    } catch (e) {
      print("Error updating speech rate: $e");
    }
  }

  Future<void> updatePitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      print("Error updating speech pitch: $e");
    }
  }

  Future<void> updateVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print("Error updating speech volume: $e");
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
