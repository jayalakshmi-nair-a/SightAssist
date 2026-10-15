import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/image_preprocessor.dart';
import '../models/scene_description.dart';

class GeminiService extends ChangeNotifier {
  String? _customProxyUrl;
  bool _isProxyConnected = false;

  void setProxyUrl(String url) {
    _customProxyUrl = url;
    checkProxyHealth();
  }

  String get activeProxyUrl {
    if (_customProxyUrl != null && _customProxyUrl!.trim().isNotEmpty) {
      return _customProxyUrl!.trim();
    }
    return EnvConfig.proxyServerUrl;
  }

  bool get isProxyConnected => _isProxyConnected;

  /// Returns true if API key is configured (handled on proxy backend or in env)
  bool get hasApiKey => true;

  /// Active API key accessor (kept secure on backend proxy, returns env key for legacy callers)
  String get activeApiKey => EnvConfig.geminiApiKey;

  /// Pings the backend proxy server to verify real-time API connection
  Future<bool> checkProxyHealth([String? urlOverride]) async {
    final targetUrl = urlOverride ?? activeProxyUrl;
    try {
      final uri = Uri.parse('$targetUrl/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _isProxyConnected = body['status'] == 'ok';
      } else {
        _isProxyConnected = false;
      }
    } catch (e) {
      _isProxyConnected = false;
    }
    notifyListeners();
    return _isProxyConnected;
  }

  /// Analyzes an image via the Real-Time Backend Proxy Server (API Key stored securely in .env)
  Future<SceneDescription> describeScene({
    required XFile imageFile,
    required AppLanguage language,
    String? prompt,
  }) async {
    final Uint8List optimizedBytes = await ImagePreprocessor.prepareForGemini(imageFile);
    final base64Img = base64Encode(optimizedBytes);

    try {
      final proxyUri = Uri.parse('$activeProxyUrl/api/describe-scene');
      final payload = <String, dynamic>{
        'image': base64Img,
        'language': language.displayName,
      };
      if (prompt != null && prompt.trim().isNotEmpty) {
        payload['prompt'] = prompt.trim();
      }

      final response = await http.post(
        proxyUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['spokenSummary'] != null) {
          _isProxyConnected = true;
          notifyListeners();
          return SceneDescription(
            spokenSummary: data['spokenSummary'].toString().trim(),
            safetyAssessment: 'RealTimeProxy Active',
          );
        } else if (data['error'] != null) {
          return SceneDescription(
            spokenSummary: 'Server Error: ${data['error']}',
            safetyAssessment: 'Error',
          );
        }
      }
    } catch (proxyError) {
      print("[GeminiService] Proxy server connection error: $proxyError.");
      _isProxyConnected = false;
      notifyListeners();
    }

    return SceneDescription(
      spokenSummary: _getMissingServerMessage(language),
      safetyAssessment: 'Server Offline',
    );
  }

  /// Specialized query for general visual question answering via Proxy Server
  Future<String> askVisualQuestion({
    required XFile imageFile,
    required String question,
    required AppLanguage language,
  }) async {
    final Uint8List optimizedBytes = await ImagePreprocessor.prepareForGemini(imageFile);
    final base64Img = base64Encode(optimizedBytes);

    try {
      final response = await http.post(
        Uri.parse('$activeProxyUrl/api/ask-question'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Img,
          'question': question,
          'language': language.displayName,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['answer'] != null) {
          return data['answer'].toString().trim();
        }
      }
    } catch (_) {}

    return _getMissingServerMessage(language);
  }

  String _getMissingServerMessage(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return 'बैकएंड AI सर्वर (node server.js) कनेक्ट नहीं है। कृपया सर्वर चालू होने की जांच करें।';
      case AppLanguage.kannada:
        return 'ಬ್ಯಾಕೆಂಡ್ AI ಸರ್ವರ್ (node server.js) ಸಂಪರ್ಕಗೊಂಡಿಲ್ಲ. ದಯವಿಟ್ಟು ಸರ್ವರ್ ಪರಿಶೀಲಿಸಿ.';
      case AppLanguage.telugu:
        return 'బ్యాకెండ్ AI సర్వర్ (node server.js) కనెక్ట్ చేయబడలేదు. దయచేసి సర్వర్‌ను తనిఖీ చేయండి.';
      case AppLanguage.english:
        return 'Real-Time AI Proxy Server is disconnected. Please ensure "node server.js" is running on port 5000.';
    }
  }
}
