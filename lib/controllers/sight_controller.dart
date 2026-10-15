import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/language_manager.dart';
import '../core/utils/haptic_feedback_helper.dart';
import '../core/utils/sound_effects.dart';
import '../models/currency_info.dart';
import '../models/hazard_info.dart';
import '../models/medicine_info.dart';
import '../models/ocr_result.dart';
import '../models/scene_description.dart';
import '../models/user_settings.dart';
import '../models/voice_command.dart';
import '../services/camera_service.dart';
import '../services/currency_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/hazard_service.dart';
import '../services/medicine_service.dart';
import '../services/ocr_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';

enum VisionMode {
  none,
  sceneUnderstanding,
  ocrReading,
  medicineAssistance,
  currencyRecognition,
  hazardDetection
}

class SightController extends ChangeNotifier {
  final CameraService cameraService;
  final SpeechService speechService;
  final TtsService ttsService;
  final GeminiService geminiService;
  final OcrService ocrService;
  final CurrencyService currencyService;
  final MedicineService medicineService;
  final HazardService hazardService;
  final FirebaseService firebaseService;
  final LanguageManager languageManager;

  VisionMode _currentMode = VisionMode.none;
  bool _isProcessing = false;
  String _statusMessage = '';
  String _resultTitle = '';
  String _resultContent = '';
  XFile? _lastCapturedImage;
  UserSettings _settings = UserSettings();

  SightController({
    required this.cameraService,
    required this.speechService,
    required this.ttsService,
    required this.geminiService,
    required this.ocrService,
    required this.currencyService,
    required this.medicineService,
    required this.hazardService,
    required this.firebaseService,
    required this.languageManager,
  });

  VisionMode get currentMode => _currentMode;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;
  String get resultTitle => _resultTitle;
  String get resultContent => _resultContent;
  XFile? get lastCapturedImage => _lastCapturedImage;
  UserSettings get settings => _settings;
  AppLanguage get currentLanguage => languageManager.currentLanguage;

  Future<void> initialize() async {
    await languageManager.initialize();
    await firebaseService.initialize();
    await ttsService.initialize(
      language: currentLanguage,
      rate: _settings.speechRate,
      pitch: _settings.speechPitch,
      volume: _settings.speechVolume,
    );
    await speechService.initialize();
    await geminiService.checkProxyHealth(_settings.proxyServerUrl);
  }

  /// Trigger voice command listening
  Future<void> startVoiceListening() async {
    await HapticFeedbackHelper.mediumTap();
    await SoundEffects.playClick();
    await ttsService.stop();

    _statusMessage = languageManager.getText('listening');
    notifyListeners();

    await speechService.startListening(
      language: currentLanguage,
      onCommandIdentified: (command) {
        handleVoiceCommand(command);
      },
    );
  }

  Future<void> stopVoiceListening() async {
    await speechService.stopListening();
    _statusMessage = '';
    notifyListeners();
  }

  /// Process natural language intent
  Future<void> handleVoiceCommand(VoiceCommand command) async {
    await speechService.stopListening();
    await HapticFeedbackHelper.lightTap();

    switch (command.intent) {
      case CommandIntent.describeSurroundings:
        executeVisionAction(VisionMode.sceneUnderstanding);
        break;
      case CommandIntent.readText:
        executeVisionAction(VisionMode.ocrReading);
        break;
      case CommandIntent.identifyMedicine:
        executeVisionAction(VisionMode.medicineAssistance);
        break;
      case CommandIntent.recognizeCurrency:
        executeVisionAction(VisionMode.currencyRecognition);
        break;
      case CommandIntent.detectHazards:
        executeVisionAction(VisionMode.hazardDetection);
        break;
      case CommandIntent.stopSpeech:
        await ttsService.stop();
        break;
      case CommandIntent.repeatResult:
        await ttsService.replay();
        break;
      case CommandIntent.openSettings:
        // Will be routed in UI if needed
        break;
      case CommandIntent.help:
        await speakCurrentLanguage(
          'SightAssist commands: You can say "Describe surroundings", "Read text", "Identify medicine", "Recognize currency", or "Detect obstacles".'
        );
        break;
      case CommandIntent.unknown:
        await speakCurrentLanguage(
          'Command not understood. Please speak again or tap the screen.'
        );
        break;
    }
  }

  /// Coordinates capture and processing for any vision mode
  Future<void> executeVisionAction(VisionMode mode) async {
    _currentMode = mode;
    _isProcessing = true;
    _statusMessage = languageManager.getText('analyzing');
    notifyListeners();

    // Give spoken feedback: "Analyzing..."
    await speakCurrentLanguage(_statusMessage, interrupt: true);
    await HapticFeedbackHelper.lightTap();

    // Capture camera frame
    XFile? captureFile = await cameraService.takePicture();
    if (captureFile == null) {
      _isProcessing = false;
      _statusMessage = languageManager.getText('repositionCamera');
      notifyListeners();
      await speakCurrentLanguage(_statusMessage);
      return;
    }

    _lastCapturedImage = captureFile;
    notifyListeners();

    // Delegate to the specific AI vision service
    switch (mode) {
      case VisionMode.sceneUnderstanding:
        await _processSceneUnderstanding(captureFile);
        break;
      case VisionMode.ocrReading:
        await _processOcrReading(captureFile);
        break;
      case VisionMode.medicineAssistance:
        await _processMedicineAssistance(captureFile);
        break;
      case VisionMode.currencyRecognition:
        await _processCurrencyRecognition(captureFile);
        break;
      case VisionMode.hazardDetection:
        await _processHazardDetection(captureFile);
        break;
      case VisionMode.none:
        break;
    }

    _isProcessing = false;
    notifyListeners();

    // Privacy rule: Purge temporary capture file from local disk
    await FirebaseService.purgeTemporaryCapture(captureFile.path);
  }

  Future<void> _processSceneUnderstanding(XFile file) async {
    _resultTitle = languageManager.getText('btnSurroundings');
    final SceneDescription scene = await geminiService.describeScene(
      imageFile: file,
      language: currentLanguage,
    );
    _resultContent = scene.spokenSummary;
    notifyListeners();
    await speakCurrentLanguage(scene.spokenSummary);
    await HapticFeedbackHelper.successPattern();
  }

  Future<void> _processOcrReading(XFile file) async {
    _resultTitle = languageManager.getText('btnReadText');
    final OcrResult ocr = await ocrService.extractText(
      imageFile: file,
      language: currentLanguage,
    );
    _resultContent = ocr.spokenText;
    notifyListeners();
    await speakCurrentLanguage(ocr.spokenText);
    await HapticFeedbackHelper.successPattern();
  }

  Future<void> _processMedicineAssistance(XFile file) async {
    _resultTitle = languageManager.getText('btnMedicine');
    final MedicineInfo medicine = await medicineService.analyzeMedicine(
      imageFile: file,
      language: currentLanguage,
    );
    _resultContent = medicine.spokenSummary;
    notifyListeners();
    await speakCurrentLanguage(medicine.spokenSummary);
    await HapticFeedbackHelper.successPattern();
  }

  Future<void> _processCurrencyRecognition(XFile file) async {
    _resultTitle = languageManager.getText('btnCurrency');
    final CurrencyInfo currency = await currencyService.recognizeCurrency(
      imageFile: file,
      language: currentLanguage,
    );
    _resultContent = currency.spokenSummary;
    notifyListeners();
    await speakCurrentLanguage(currency.spokenSummary);
    if (currency.requiresReposition) {
      await HapticFeedbackHelper.warningPattern();
    } else {
      await HapticFeedbackHelper.successPattern();
    }
  }

  Future<void> _processHazardDetection(XFile file) async {
    _resultTitle = languageManager.getText('btnHazards');
    final HazardAssessment hazard = await hazardService.detectHazards(
      imageFile: file,
      language: currentLanguage,
    );
    _resultContent = hazard.spokenPriorityAlert;
    notifyListeners();

    if (hazard.highestUrgency == HazardUrgency.critical) {
      await HapticFeedbackHelper.hazardAlertPattern();
    } else if (hazard.highestUrgency == HazardUrgency.warning) {
      await HapticFeedbackHelper.warningPattern();
    } else {
      await HapticFeedbackHelper.successPattern();
    }

    await speakCurrentLanguage(hazard.spokenPriorityAlert);
  }

  Future<void> speakCurrentLanguage(String text, {bool interrupt = true}) async {
    await ttsService.speak(text, interrupt: interrupt);
  }

  Future<void> setLanguage(AppLanguage language) async {
    await languageManager.setLanguage(language);
    await ttsService.updateLanguage(language);
    _settings = _settings.copyWith(language: language);
    await firebaseService.syncPreferences(_settings);
    notifyListeners();
    await speakCurrentLanguage(languageManager.getText('welcomeVoice'));
  }

  Future<void> updateSpeechRate(double rate) async {
    _settings = _settings.copyWith(speechRate: rate);
    await ttsService.updateSpeechRate(rate);
    await firebaseService.syncPreferences(_settings);
    notifyListeners();
  }

  Future<void> updateSpeechPitch(double pitch) async {
    _settings = _settings.copyWith(speechPitch: pitch);
    await ttsService.updatePitch(pitch);
    await firebaseService.syncPreferences(_settings);
    notifyListeners();
  }

  Future<void> updateProxyUrl(String proxyUrl) async {
    _settings = _settings.copyWith(proxyServerUrl: proxyUrl);
    geminiService.setProxyUrl(proxyUrl);
    await firebaseService.syncPreferences(_settings);
    notifyListeners();
  }
}
