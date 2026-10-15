class MedicineInfo {
  final String medicineName;
  final String? activeIngredients;
  final String? expiryDate;
  final String? manufacturingDate;
  final String? dosageInstructions;
  final String? precautions;
  final bool isExpiryFound;
  final bool isDosageFound;
  final double confidence;
  final String spokenSummary;
  final DateTime timestamp;

  MedicineInfo({
    required this.medicineName,
    this.activeIngredients,
    this.expiryDate,
    this.manufacturingDate,
    this.dosageInstructions,
    this.precautions,
    required this.isExpiryFound,
    required this.isDosageFound,
    this.confidence = 1.0,
    required this.spokenSummary,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MedicineInfo.unreadable() {
    return MedicineInfo(
      medicineName: 'Unrecognized Medication',
      isExpiryFound: false,
      isDosageFound: false,
      confidence: 0.0,
      spokenSummary: 'Could not clearly identify the medicine name or expiry date. Please do not consume without human verification.',
    );
  }
}
