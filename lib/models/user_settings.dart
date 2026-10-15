import '../core/localization/app_localizations.dart';

class UserSettings {
  final AppLanguage language;
  final double speechRate; // 0.3 - 1.0 (default 0.5)
  final double speechPitch; // 0.5 - 2.0 (default 1.0)
  final double speechVolume; // 0.1 - 1.0 (default 1.0)
  final bool hapticFeedbackEnabled;
  final bool highContrastMode;
  final bool autoReadoutEnabled;
  final bool continuousListening;
  final String proxyServerUrl;

  UserSettings({
    this.language = AppLanguage.english,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.speechVolume = 1.0,
    this.hapticFeedbackEnabled = true,
    this.highContrastMode = true,
    this.autoReadoutEnabled = true,
    this.continuousListening = false,
    this.proxyServerUrl = 'http://localhost:5000',
  });

  UserSettings copyWith({
    AppLanguage? language,
    double? speechRate,
    double? speechPitch,
    double? speechVolume,
    bool? hapticFeedbackEnabled,
    bool? highContrastMode,
    bool? autoReadoutEnabled,
    bool? continuousListening,
    String? proxyServerUrl,
  }) {
    return UserSettings(
      language: language ?? this.language,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      speechVolume: speechVolume ?? this.speechVolume,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      autoReadoutEnabled: autoReadoutEnabled ?? this.autoReadoutEnabled,
      continuousListening: continuousListening ?? this.continuousListening,
      proxyServerUrl: proxyServerUrl ?? this.proxyServerUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language.code,
      'speechRate': speechRate,
      'speechPitch': speechPitch,
      'speechVolume': speechVolume,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'highContrastMode': highContrastMode,
      'autoReadoutEnabled': autoReadoutEnabled,
      'continuousListening': continuousListening,
      'proxyServerUrl': proxyServerUrl,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      language: AppLanguage.fromCode(json['language'] ?? 'en'),
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      speechPitch: (json['speechPitch'] as num?)?.toDouble() ?? 1.0,
      speechVolume: (json['speechVolume'] as num?)?.toDouble() ?? 1.0,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
      highContrastMode: json['highContrastMode'] ?? true,
      autoReadoutEnabled: json['autoReadoutEnabled'] ?? true,
      continuousListening: json['continuousListening'] ?? false,
      proxyServerUrl: json['proxyServerUrl'] ?? 'http://localhost:5000',
    );
  }
}
