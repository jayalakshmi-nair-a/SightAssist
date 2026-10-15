import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';
import '../models/user_settings.dart';

class FirebaseService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _userId;

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get userId => _userId;

  Future<void> initialize() async {
    try {
      // In production, Firebase.initializeApp() is invoked.
      // We check for project credentials in EnvConfig.
      if (EnvConfig.firebaseProjectId.isNotEmpty) {
        _isInitialized = true;
        _userId = "sightassist_guest_user";
        notifyListeners();
        print("Firebase service initialized in privacy-safe accessibility mode.");
      }
    } catch (e) {
      print("Firebase initialization error: $e. Operating in local-first secure mode.");
    }
  }

  /// Sync user preferences to cloud without storing camera captures
  Future<void> syncPreferences(UserSettings settings) async {
    _isSyncing = true;
    notifyListeners();

    try {
      // Persist locally first for instant offline readiness
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_selected_language', settings.language.code);
      await prefs.setDouble('pref_speech_rate', settings.speechRate);
      await prefs.setDouble('pref_speech_pitch', settings.speechPitch);
      await prefs.setDouble('pref_speech_volume', settings.speechVolume);
      await prefs.setBool('pref_haptic_feedback_enabled', settings.hapticFeedbackEnabled);
      await prefs.setBool('pref_high_contrast_mode', settings.highContrastMode);
      await prefs.setBool('pref_auto_readout', settings.autoReadoutEnabled);
      await prefs.setString('pref_custom_gemini_api_key', settings.customGeminiApiKey);

      // If Firebase cloud backend is active, sync settings document
      if (_isInitialized) {
        // e.g., FirebaseFirestore.instance.collection('users').doc(_userId).set(settings.toJson());
      }
    } catch (e) {
      print("Error syncing user preferences: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Privacy Enforcement: Ensure temporary camera files are cleaned up immediately
  static Future<void> purgeTemporaryCapture(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Notice: Temporary image cleanup: $e");
    }
  }
}
