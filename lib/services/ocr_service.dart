import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/env_config.dart';
import '../core/localization/app_localizations.dart';
import '../core/utils/image_preprocessor.dart';
import '../models/ocr_result.dart';

class OcrService extends ChangeNotifier {
  TextRecognizer? _textRecognizer;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  TextRecognizer _getTextRecognizer() {
    return _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  }

  Future<OcrResult> extractText({
    required XFile imageFile,
    required AppLanguage language,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      String rawText = '';

      // 1. On mobile platforms (Android/iOS), run ML Kit Text Recognition
      if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          final XFile processedImage = await ImagePreprocessor.prepareForOcr(imageFile);
          final InputImage inputImage = InputImage.fromFile(File(processedImage.path));
          final RecognizedText recognized = await _getTextRecognizer().processImage(inputImage);
          rawText = recognized.text.trim();
        } catch (mlError) {
          print("ML Kit text recognition bypassed: $mlError");
        }
      }

      // 2. On web, desktop, or if local OCR returned empty and Gemini key is available, use Gemini OCR
      if (rawText.isEmpty && EnvConfig.geminiApiKey.isNotEmpty) {
        final Uint8List bytes = await ImagePreprocessor.prepareForGemini(imageFile);
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: EnvConfig.geminiApiKey,
        );
        const prompt = 'Read all printed or handwritten text visible in this image accurately. Return ONLY the extracted text. If no text exists, return NONE.';
        final response = await model.generateContent([
          Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)])
        ]);
        final extracted = response.text?.trim() ?? '';
        if (extracted != 'NONE' && extracted.isNotEmpty) {
          rawText = extracted;
        }
      }

      if (rawText.isEmpty) {
        _isProcessing = false;
        notifyListeners();
        return OcrResult(
          fullText: '',
          spokenText: _getNoTextMessage(language),
          detectedType: TextDocumentType.generalText,
          hasReadableContent: false,
        );
      }

      final docType = _classifyDocumentType(rawText);
      final spoken = _formatSpokenOcr(rawText, docType, language);

      _isProcessing = false;
      notifyListeners();

      return OcrResult(
        fullText: rawText,
        spokenText: spoken,
        detectedType: docType,
        blocks: [OcrBlock(text: rawText)],
        hasReadableContent: true,
      );
    } catch (e) {
      print("OCR Service processing error: $e");
      _isProcessing = false;
      notifyListeners();

      return OcrResult(
        fullText: '',
        spokenText: _getErrorMessage(language),
        detectedType: TextDocumentType.generalText,
        hasReadableContent: false,
      );
    }
  }

  TextDocumentType _classifyDocumentType(String text) {
    final lower = text.toLowerCase();
    // Bus number pattern (e.g., "335-E", "Route 500D", "201R", "BUS 45")
    final busRegex = RegExp(r'\b(bus|route|no\.?)\s*[0-9]+[a-z]?\b', caseSensitive: false);
    if (busRegex.hasMatch(text) || (text.length < 15 && RegExp(r'^[0-9]+[A-Z]?$').hasMatch(text.trim()))) {
      return TextDocumentType.busNumber;
    }

    if (lower.contains('stop') || lower.contains('caution') || lower.contains('way out') ||
        lower.contains('exit') || lower.contains('entry') || lower.contains('hospital') ||
        lower.contains('street') || lower.contains('road') || lower.contains('avenue')) {
      return TextDocumentType.signboard;
    }

    if (lower.contains('notice') || lower.contains('announcement') || lower.contains('attention') || lower.contains('circular')) {
      return TextDocumentType.notice;
    }

    if (lower.contains('mfg') || lower.contains('exp') || lower.contains('mrp') || lower.contains('net wt') || lower.contains('ingredients')) {
      return TextDocumentType.productLabel;
    }

    return TextDocumentType.document;
  }

  String _formatSpokenOcr(String rawText, TextDocumentType type, AppLanguage language) {
    final cleanText = rawText.replaceAll('\n\n', '. ').replaceAll('\n', ' ');

    switch (type) {
      case TextDocumentType.busNumber:
        switch (language) {
          case AppLanguage.hindi:
            return 'बस या रूट नंबर पहचाना गया: $cleanText';
          case AppLanguage.kannada:
            return 'ಬಸ್ ಅಥವಾ ಮಾರ್ಗ ಸಂಖ್ಯೆ ಗುರುತಿಸಲಾಗಿದೆ: $cleanText';
          case AppLanguage.telugu:
            return 'బస్సు లేదా రూట్ నంబర్ గుర్తించబడింది: $cleanText';
          case AppLanguage.english:
            return 'Bus route identified: $cleanText';
        }
      case TextDocumentType.signboard:
        switch (language) {
          case AppLanguage.hindi:
            return 'साइनबोर्ड पर लिखा है: $cleanText';
          case AppLanguage.kannada:
            return 'ಸೈನ್‌ಬೋರ್ಡ್‌ನಲ್ಲಿ ಹೀಗಿದೆ: $cleanText';
          case AppLanguage.telugu:
            return 'సైన్‌బోర్డుపై ఇలా ఉంది: $cleanText';
          case AppLanguage.english:
            return 'Signboard reads: $cleanText';
        }
      default:
        return cleanText;
    }
  }

  String _getNoTextMessage(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return 'कोई पठनीय टेक्स्ट नहीं मिला। कृपया कैमरे को थोड़ा पास लाएं और रोशनी की जांच करें।';
      case AppLanguage.kannada:
        return 'ಯಾವುದೇ ಸ್ಪಷ್ಟ ಪಠ್ಯ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಕ್ಯಾಮೆರಾವನ್ನು ಹತ್ತಿರ ಹಿಡಿದು ಪುನಃ ಪ್ರಯತ್ನಿಸಿ.';
      case AppLanguage.telugu:
        return 'ఎటువంటి స్పష్టమైన టెక్స్ట్ కనిపించలేదు. దయచేసి కెమెరాను దగ్గరగా ఉంచి మళ్ళీ ప్రయత్నించండి.';
      case AppLanguage.english:
        return 'No readable text was detected. Try holding the camera closer under good lighting.';
    }
  }

  String _getErrorMessage(AppLanguage language) {
    switch (language) {
      case AppLanguage.hindi:
        return 'टेक्स्ट पढ़ने में त्रुटि हुई। कृपया दोबारा प्रयास करें।';
      case AppLanguage.kannada:
        return 'ಪಠ್ಯ ಓದುವಲ್ಲಿ ದೋಷ ಸಂಭವಿಸಿದೆ. ದಯವಿಟ್ಟು ಪುನಃ ಪ್ರಯತ್ನಿಸಿ.';
      case AppLanguage.telugu:
        return 'టెక్స్ట్ చదవడంలో లోపం జరిగింది. దయచేసి మళ్ళీ ప్రయత్నించండి.';
      case AppLanguage.english:
        return 'Error reading text from the image. Please try again.';
    }
  }

  @override
  void dispose() {
    try {
      _textRecognizer?.close();
    } catch (_) {}
    super.dispose();
  }
}
