import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Accessibility haptic patterns for visually impaired navigation feedback
class HapticFeedbackHelper {
  static Future<void> lightTap() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static Future<void> mediumTap() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> heavyTap() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> successPattern() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 80, 100, 150]);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  static Future<void> warningPattern() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 200, 150, 200]);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> hazardAlertPattern() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Rapid alarming vibration pattern for immediate obstacles
        await Vibration.vibrate(pattern: [0, 300, 100, 300, 100, 500]);
        return;
      }
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
