import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/image_preprocessor.dart';
import '../models/hazard_info.dart';
import 'gemini_service.dart';

class HazardService extends ChangeNotifier {
  final GeminiService geminiService;
  bool _isProcessing = false;

  HazardService({required this.geminiService});

  bool get isProcessing => _isProcessing;

  Future<HazardAssessment> detectHazards({
    required XFile imageFile,
    required AppLanguage language,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      if (!geminiService.hasApiKey) {
        _isProcessing = false;
        notifyListeners();
        return HazardAssessment(
          hasHazards: false,
          spokenPriorityAlert: _getNoApiKeyAlert(language),
          highestUrgency: HazardUrgency.advisory,
        );
      }

      final Uint8List optimized = await ImagePreprocessor.prepareForGemini(imageFile);
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: geminiService.activeApiKey,
        generationConfig: GenerationConfig(temperature: 0.1),
      );

      final prompt = '''
You are the Obstacle and Hazard Detection system of SightAssist for a visually impaired user walking forward.
Analyze this camera viewpoint for IMMEDIATE hazards (within 1 to 5 steps):
- Descending or ascending stairs / steps
- Curbs, open trenches, potholes, or uneven pavements
- Low-hanging obstacles (tree branches, awnings, beams) at head level
- Moving vehicles, bicycles, or approaching motorcycles
- Obstacles directly on the walking path (poles, chairs, closed doors, wet floors, wires)

INSTRUCTIONS:
1. Prioritize IMMEDIATE, HIGH-RISK collision hazards first. Do NOT overwhelm the user with background items.
2. Provide directional alerts: specify if the obstacle is "ahead", "on your left", "on your right", or "at ground level".
3. State your response as a single, urgent, direct audio guidance in ${language.displayName}.
Example format:
- "Caution: Stairs descending approximately three steps ahead."
- "Obstacle ahead. Chair directly in your walking path."
- "Vehicle approaching on your right."
- "Path is clear ahead."
''';

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', optimized),
        ])
      ]);

      final alert = response.text?.trim() ?? '';
      _isProcessing = false;
      notifyListeners();

      if (alert.isEmpty) {
        return HazardAssessment.clearPath();
      }

      final lower = alert.toLowerCase();
      HazardUrgency urgency = HazardUrgency.advisory;
      if (lower.contains('stop') || lower.contains('immediate') || lower.contains('danger') || lower.contains('stair') || lower.contains('vehicle')) {
        urgency = HazardUrgency.critical;
      } else if (lower.contains('caution') || lower.contains('obstacle') || lower.contains('ahead') || lower.contains('left') || lower.contains('right')) {
        urgency = HazardUrgency.warning;
      }

      final isClear = lower.contains('clear') || lower.contains('safe') || lower.contains('no obstacle');

      return HazardAssessment(
        hasHazards: !isClear,
        highestUrgency: isClear ? HazardUrgency.advisory : urgency,
        spokenPriorityAlert: alert,
        isPathClear: isClear,
      );
    } catch (e) {
      print("Hazard detection error: $e");
      _isProcessing = false;
      notifyListeners();
      return HazardAssessment.clearPath();
    }
  }

  String _getNoApiKeyAlert(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return 'खतरे की पहचान के लिए जेमिनी एपीआई कुंजी आवश्यक है।';
      case AppLanguage.kannada:
        return 'ಅಡೆತಡೆ ಪತ್ತೆಗೆ ಜೆಮಿನಿ ಎಪಿಐ ಕೀ ಅಗತ್ಯವಿದೆ.';
      case AppLanguage.telugu:
        return 'అడ్డంకుల గుర్తింపు కోసం జెమిని ఏపీఐ కీ అవసరం.';
      case AppLanguage.english:
        return 'Gemini API key is required for advanced obstacle detection.';
    }
  }
}
