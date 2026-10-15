class AppConfig {
  static const String appName = 'SightAssist';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Audio & Accessibility Constants
  static const double defaultSpeechRate = 0.5;
  static const double defaultSpeechPitch = 1.0;
  static const double defaultSpeechVolume = 1.0;

  // Camera capture dimensions
  static const int optimalImageWidth = 1024;
  static const int optimalImageQuality = 85;

  // Maximum speech duration limits
  static const int speechTimeoutSeconds = 8;
  static const int continuousListeningIntervalSeconds = 4;
}
