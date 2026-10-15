enum TextDocumentType {
  signboard,
  busNumber,
  document,
  productLabel,
  notice,
  generalText
}

class OcrBlock {
  final String text;
  final double confidence;

  OcrBlock({required this.text, this.confidence = 1.0});
}

class OcrResult {
  final String fullText;
  final String spokenText;
  final TextDocumentType detectedType;
  final List<OcrBlock> blocks;
  final bool hasReadableContent;
  final DateTime timestamp;

  OcrResult({
    required this.fullText,
    required this.spokenText,
    required this.detectedType,
    this.blocks = const [],
    required this.hasReadableContent,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory OcrResult.empty() {
    return OcrResult(
      fullText: '',
      spokenText: 'No readable text was detected.',
      detectedType: TextDocumentType.generalText,
      hasReadableContent: false,
    );
  }
}
