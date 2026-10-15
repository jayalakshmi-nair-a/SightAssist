import 'package:flutter_test/flutter_test.dart';
import 'package:sightassist/models/medicine_info.dart';

void main() {
  group('MedicineInfo Safety & Verification Tests', () {
    test('Unreadable medicine outputs safety warning without hallucinating info', () {
      final unreadable = MedicineInfo.unreadable();
      expect(unreadable.confidence, equals(0.0));
      expect(unreadable.isExpiryFound, isFalse);
      expect(unreadable.isDosageFound, isFalse);
      expect(unreadable.spokenSummary, contains('do not consume without human verification'));
    });

    test('Identified medicine preserves expiry date and dosage', () {
      final med = MedicineInfo(
        medicineName: 'Paracetamol 500mg',
        expiryDate: '12/2026',
        dosageInstructions: '500mg',
        isExpiryFound: true,
        isDosageFound: true,
        confidence: 0.9,
        spokenSummary: 'Paracetamol 500mg. Expiry date found: 12/2026.',
      );

      expect(med.medicineName, equals('Paracetamol 500mg'));
      expect(med.expiryDate, equals('12/2026'));
      expect(med.isExpiryFound, isTrue);
    });
  });
}
