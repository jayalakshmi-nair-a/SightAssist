import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/image_preprocessor.dart';
import '../models/medicine_info.dart';
import 'gemini_service.dart';

class MedicineService extends ChangeNotifier {
  final GeminiService geminiService;
  TextRecognizer? _textRecognizer;
  bool _isProcessing = false;

  MedicineService({required this.geminiService});

  bool get isProcessing => _isProcessing;

  TextRecognizer _getTextRecognizer() {
    return _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<MedicineInfo> analyzeMedicine({
    required XFile imageFile,
    required AppLanguage language,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      String ocrText = '';
      String? extractedExpiry;
      String? extractedDosage;

      // 1. Run local OCR on mobile native platforms
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          final preprocessedFile = await ImagePreprocessor.prepareForOcr(imageFile);
          final inputImage = InputImage.fromFilePath(preprocessedFile.path);
          final RecognizedText recognized = await _getTextRecognizer().processImage(inputImage);
          ocrText = recognized.text;
          extractedExpiry = _extractExpiryDate(ocrText);
          extractedDosage = _extractDosage(ocrText);
        } catch (_) {}
      }

      // 2. Multimodal AI Analysis with Gemini Vision for packaging context & active salt
      if (geminiService.hasApiKey) {
        final Uint8List optimized = await ImagePreprocessor.prepareForGemini(imageFile);
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: geminiService.activeApiKey,
          generationConfig: GenerationConfig(temperature: 0.1),
        );

        final prompt = '''
You are an accessibility visual assistant for a blind person inspecting a medicine strip, bottle, or prescription.
Extract the following information accurately:
1. Medicine Brand Name & Active Salt
2. Expiry Date (Look for EXP, Expiry, Best Before)
3. Dosage or Strength (e.g., 500mg, 1 tablet twice daily)
4. Critical safety warning (e.g. "Keep out of reach of children", "Schedule H prescription drug")

CRITICAL SAFETY DIRECTIVE:
- NEVER invent or guess medicine names or expiry dates.
- If the packaging is foil-reflective, torn, or blurry, explicitly say that expiry date is unreadable.
- Formulate a 2 to 3 sentence natural spoken summary in ${language.displayName}.
''';

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', optimized),
          ])
        ]);

        final responseText = response.text?.trim() ?? '';
        if (responseText.isNotEmpty) {
          _isProcessing = false;
          notifyListeners();

          return MedicineInfo(
            medicineName: _extractLineOrDefault(responseText, 'Medicine'),
            expiryDate: extractedExpiry,
            dosageInstructions: extractedDosage,
            isExpiryFound: extractedExpiry != null || responseText.toLowerCase().contains('expir'),
            isDosageFound: extractedDosage != null,
            spokenSummary: responseText,
          );
        }
      }

      // Fallback to pure on-device OCR if Gemini is unavailable
      _isProcessing = false;
      notifyListeners();

      if (ocrText.trim().isEmpty) {
        return MedicineInfo.unreadable();
      }

      final spoken = _formatOcrMedicineSpeech(ocrText, extractedExpiry, extractedDosage, language);
      return MedicineInfo(
        medicineName: 'Packaging Text Detected',
        expiryDate: extractedExpiry,
        dosageInstructions: extractedDosage,
        isExpiryFound: extractedExpiry != null,
        isDosageFound: extractedDosage != null,
        spokenSummary: spoken,
      );
    } catch (e) {
      print("Medicine analysis error: $e");
      _isProcessing = false;
      notifyListeners();
      return MedicineInfo.unreadable();
    }
  }

  String? _extractExpiryDate(String text) {
    // Regex for EXP: 12/26, 05/2027, EXPIRY: JUN 25, etc.
    final expRegex = RegExp(
      r'(?:EXP(?:IRY)?|USE BEFORE|VALID TILL)[:\.\s]*([0-9]{1,2}[\/\-\.][0-9]{2,4}|[A-Za-z]{3}[\s\/\-][0-9]{2,4})',
      caseSensitive: false,
    );
    final match = expRegex.firstMatch(text);
    return match?.group(1);
  }

  String? _extractDosage(String text) {
    // Regex for 500mg, 10ml, 250 mcg, 100 IU
    final doseRegex = RegExp(r'\b\d+\s*(?:mg|ml|mcg|iu|gm|g)\b', caseSensitive: false);
    final match = doseRegex.firstMatch(text);
    return match?.group(0);
  }

  String _formatOcrMedicineSpeech(String rawText, String? expiry, String? dosage, AppLanguage language) {
    String expiryPart = expiry != null ? 'Expiry date found: $expiry.' : 'Expiry date not found on visible surface.';
    String dosagePart = dosage != null ? 'Strength: $dosage.' : '';

    switch (language) {
      case AppLanguage.hindi:
        return 'दवा का पाठ पढ़ा गया। $expiryPart $dosagePart कृपया पुष्टि किए बिना दवा न लें।';
      case AppLanguage.kannada:
        return 'ಔಷಧಿಯ ಪಠ್ಯ ಗುರುತಿಸಲಾಗಿದೆ. $expiryPart $dosagePart ಖಚಿತಪಡಿಸಿಕೊಳ್ಳದೆ ಸೇವಿಸಬೇಡಿ.';
      case AppLanguage.telugu:
        return 'మందుల వివరాలు గుర్తించబడ్డాయి. $expiryPart $dosagePart ధృవీకరించుకోకుండా మందులు వాడవద్దు.';
      case AppLanguage.english:
        return 'Medicine packaging text analyzed. $expiryPart $dosagePart Always verify before consuming.';
    }
  }

  String _extractLineOrDefault(String full, String fallback) {
    final firstLine = full.split('\n').first;
    return firstLine.length > 50 ? fallback : firstLine;
  }

  @override
  void dispose() {
    try {
      _textRecognizer?.close();
    } catch (_) {}
    super.dispose();
  }
}
