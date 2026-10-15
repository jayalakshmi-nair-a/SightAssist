import 'package:flutter_test/flutter_test.dart';
import 'package:sightassist/models/currency_info.dart';

void main() {
  group('CurrencyInfo Model Tests', () {
    test('Standard banknote initialization', () {
      final info = CurrencyInfo(
        denomination: 500,
        type: CurrencyType.banknote,
        confidence: 0.95,
        spokenSummary: '500 Rupee note detected.',
        requiresReposition: false,
      );

      expect(info.denomination, equals(500));
      expect(info.type, equals(CurrencyType.banknote));
      expect(info.confidence, equals(0.95));
      expect(info.requiresReposition, isFalse);
    });

    test('Low confidence triggers reposition advice', () {
      final lowConf = CurrencyInfo.lowConfidence('Folded or dark');
      expect(lowConf.denomination, equals(0));
      expect(lowConf.confidence, lessThan(0.5));
      expect(lowConf.requiresReposition, isTrue);
      expect(lowConf.spokenSummary, contains('flatten the note'));
    });
  });
}
