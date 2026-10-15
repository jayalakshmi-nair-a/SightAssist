import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../core/localization/app_localizations.dart';
import '../models/voice_command.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastRecognizedWords = '';
  VoiceCommand? _lastParsedCommand;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastRecognizedWords => _lastRecognizedWords;
  VoiceCommand? get lastParsedCommand => _lastParsedCommand;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speechToText.initialize(
        onError: (val) {
          _isListening = false;
          print('SpeechService onError: $val');
          notifyListeners();
        },
        onStatus: (status) {
          _isListening = status == 'listening';
          notifyListeners();
        },
      );
      notifyListeners();
      return _isAvailable;
    } catch (e) {
      print('SpeechService initialize error: $e');
      _isAvailable = false;
      return false;
    }
  }

  Future<void> startListening({
    required AppLanguage language,
    required Function(VoiceCommand) onCommandIdentified,
  }) async {
    if (!_isAvailable) {
      bool initialized = await initialize();
      if (!initialized) return;
    }

    _lastRecognizedWords = '';
    _lastParsedCommand = null;

    try {
      await _speechToText.listen(
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
        onResult: (SpeechRecognitionResult result) {
          _lastRecognizedWords = result.recognizedWords;
          if (result.recognizedWords.isNotEmpty) {
            final command = VoiceCommand.parse(result.recognizedWords);
            _lastParsedCommand = command;
            notifyListeners();

            if (result.finalResult || command.intent != CommandIntent.unknown) {
              onCommandIdentified(command);
            }
          }
        },
      );
      _isListening = true;
      notifyListeners();
    } catch (e) {
      print("Error starting speech listening: $e");
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
    _isListening = false;
    notifyListeners();
  }
}
