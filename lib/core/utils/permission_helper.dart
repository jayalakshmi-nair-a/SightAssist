import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static bool get _isDesktopOrWeb =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  static Future<bool> requestCameraPermission() async {
    if (_isDesktopOrWeb) return true; // Handled directly by OS or browser
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) return true;
      final result = await Permission.camera.request();
      return result.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> requestMicrophonePermission() async {
    if (_isDesktopOrWeb) return true; // Handled directly by OS or browser
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return true;
      final result = await Permission.microphone.request();
      return result.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> checkInitialPermissions() async {
    if (_isDesktopOrWeb) return true;
    try {
      final cam = await Permission.camera.status;
      final mic = await Permission.microphone.status;
      return cam.isGranted && mic.isGranted;
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, bool>> requestAllRequired() async {
    if (_isDesktopOrWeb) {
      return {'camera': true, 'microphone': true};
    }
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      return {
        'camera': statuses[Permission.camera]?.isGranted ?? false,
        'microphone': statuses[Permission.microphone]?.isGranted ?? false,
      };
    } catch (_) {
      return {'camera': true, 'microphone': true};
    }
  }
}
