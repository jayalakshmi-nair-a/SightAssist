import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      // In production or test environments where .env is not packaged, fallback gracefully
      print("Notice: .env file not loaded or not found ($e). Using system/preferences fallback.");
    }
  }

  static String get proxyServerUrl {
    return dotenv.env['PROXY_SERVER_URL'] ?? 'http://localhost:5000';
  }

  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static String get geminiModel {
    return dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';
  }

  static String get firebaseApiKey {
    return dotenv.env['FIREBASE_API_KEY'] ?? '';
  }

  static String get firebaseProjectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? 'sightassist-app';
  }

  static bool get isDebugSpeech {
    return dotenv.env['ENABLE_DEBUG_SPEECH'] == 'true';
  }
}
