enum CurrencyType { banknote, coin, unknown }

class CurrencyInfo {
  final int denomination; // 10, 20, 50, 100, 200, 500, 2000, etc.
  final CurrencyType type;
  final double confidence; // 0.0 - 1.0
  final bool isAuthenticFeaturesDetected;
  final String conditionNote; // e.g. "Folded", "Creased", "Well lit"
  final String spokenSummary;
  final bool requiresReposition;
  final DateTime timestamp;

  CurrencyInfo({
    required this.denomination,
    required this.type,
    required this.confidence,
    this.isAuthenticFeaturesDetected = true,
    this.conditionNote = '',
    required this.spokenSummary,
    this.requiresReposition = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CurrencyInfo.lowConfidence([String reason = 'Image is blurry or folded']) {
    return CurrencyInfo(
      denomination: 0,
      type: CurrencyType.unknown,
      confidence: 0.2,
      spokenSummary: 'Could not clearly recognize the currency note. Please flatten the note and hold steady under good lighting.',
      requiresReposition: true,
    );
  }
}
