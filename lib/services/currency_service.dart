import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/image_preprocessor.dart';
import '../models/currency_info.dart';
import 'gemini_service.dart';

class CurrencyService extends ChangeNotifier {
  final GeminiService geminiService;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;

  CurrencyService({required this.geminiService});

  bool get isProcessing => _isProcessing;

  Future<CurrencyInfo> recognizeCurrency({
    required XFile imageFile,
    required AppLanguage language,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      int detectedDenomination = 0;
      bool hasRbiWatermark = false;

      // 1. Fast local on-device OCR pass to detect currency keywords & numerals (on native platforms)
      if (!kIsWeb) {
        try {
          final inputImage = InputImage.fromFilePath(imageFile.path);
          final RecognizedText recognized = await _textRecognizer.processImage(inputImage);
          final rawText = recognized.text.toUpperCase();
          hasRbiWatermark = rawText.contains('RESERVE BANK') || rawText.contains('BHARATIYA') || rawText.contains('INDIA') || rawText.contains('PROMISE');

          final validDenominations = [2000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
          for (final denom in validDenominations) {
            final pattern = RegExp('\\b(₹|RS\\.?|RUPEES)?\\s*$denom\\b');
            if (pattern.hasMatch(rawText)) {
              detectedDenomination = denom;
              break;
            }
          }
        } catch (_) {}
      }

      // If clear RBI watermark and denomination matched with high confidence locally
      if (detectedDenomination > 0 && hasRbiWatermark) {
        _isProcessing = false;
        notifyListeners();
        return CurrencyInfo(
          denomination: detectedDenomination,
          type: detectedDenomination > 20 ? CurrencyType.banknote : CurrencyType.banknote,
          confidence: 0.95,
          spokenSummary: _formatCurrencySpeech(detectedDenomination, language, CurrencyType.banknote),
          requiresReposition: false,
        );
      }

      // 2. If local OCR is ambiguous or key is available, query Gemini Vision for multimodal verification
      if (geminiService.hasApiKey) {
        final Uint8List optimized = await ImagePreprocessor.prepareForCurrency(imageFile);
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: geminiService.activeApiKey,
          generationConfig: GenerationConfig(temperature: 0.1),
        );

        const prompt = '''
Examine this image for Indian currency (banknotes or coins).
Return EXACTLY a JSON format:
{
  "recognized": true | false,
  "denomination": 10 | 20 | 50 | 100 | 200 | 500 | 2000 | 1 | 2 | 5,
  "type": "banknote" | "coin",
  "confidence": 0.0 to 1.0,
  "reason": "Clear note" | "Folded" | "Low light" | "Partially cut off" | "Not currency"
}
CRITICAL SAFETY RULE: If the note is folded, blurry, cut off, or you are less than 75% certain, set "recognized": false and "confidence": 0.3. NEVER guess currency.
''';

        final response = await model.generateContent([
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', optimized),
          ])
        ]);

        final responseText = response.text ?? '';
        final parsed = _parseGeminiCurrencyJson(responseText);

        _isProcessing = false;
        notifyListeners();

        if (parsed != null && parsed['recognized'] == true && (parsed['confidence'] as num) >= 0.75) {
          final denom = (parsed['denomination'] as num).toInt();
          final type = parsed['type'] == 'coin' ? CurrencyType.coin : CurrencyType.banknote;
          return CurrencyInfo(
            denomination: denom,
            type: type,
            confidence: (parsed['confidence'] as num).toDouble(),
            spokenSummary: _formatCurrencySpeech(denom, language, type),
            requiresReposition: false,
          );
        }
      }

      // If either method could not reliably verify
      _isProcessing = false;
      notifyListeners();
      return CurrencyInfo.lowConfidence();
    } catch (e) {
      print("Currency recognition error: $e");
      _isProcessing = false;
      notifyListeners();
      return CurrencyInfo.lowConfidence();
    }
  }

  Map<String, dynamic>? _parseGeminiCurrencyJson(String text) {
    try {
      final startIndex = text.indexOf('{');
      final endIndex = text.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        final jsonStr = text.substring(startIndex, endIndex + 1);
        // Basic parser for JSON keys
        final isRecognized = jsonStr.contains('"recognized": true');
        final denomMatch = RegExp(r'"denomination":\s*(\d+)').firstMatch(jsonStr);
        final confMatch = RegExp(r'"confidence":\s*([\d\.]+)').firstMatch(jsonStr);
        final isCoin = jsonStr.contains('"type": "coin"');

        if (denomMatch != null) {
          return {
            'recognized': isRecognized,
            'denomination': int.parse(denomMatch.group(1)!),
            'confidence': confMatch != null ? double.parse(confMatch.group(1)!) : 0.8,
            'type': isCoin ? 'coin' : 'banknote',
          };
        }
      }
    } catch (e) {
      print("Error parsing currency JSON: $e");
    }
    return null;
  }

  String _formatCurrencySpeech(int denomination, AppLanguage language, CurrencyType type) {
    final isCoin = type == CurrencyType.coin;
    switch (language) {
      case AppLanguage.hindi:
        return isCoin
            ? '$denomination रुपये का सिक्का पहचाना गया।'
            : '$denomination रुपये का नोट पहचाना गया।';
      case AppLanguage.kannada:
        return isCoin
            ? '$denomination ರೂಪಾಯಿ ನಾಣ್ಯ ಗುರುತಿಸಲಾಗಿದೆ.'
            : '$denomination ರೂಪಾಯಿ ನೋಟು ಗುರುತಿಸಲಾಗಿದೆ.';
      case AppLanguage.telugu:
        return isCoin
            ? '$denomination రూపాయల నాణెం గుర్తించబడింది.'
            : '$denomination రూపాయల నోటు గుర్తించబడింది.';
      case AppLanguage.english:
        return isCoin
            ? '$denomination Rupee coin detected.'
            : '$denomination Rupee note detected.';
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
