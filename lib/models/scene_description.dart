class DetectedEntity {
  final String label;
  final String relativePosition; // e.g., 'directly in front', 'to your left', 'to your right', 'approaching'
  final String estimatedDistance; // e.g., 'about 2 steps ahead', 'arm length away'

  DetectedEntity({
    required this.label,
    required this.relativePosition,
    required this.estimatedDistance,
  });

  factory DetectedEntity.fromJson(Map<String, dynamic> json) {
    return DetectedEntity(
      label: json['label'] ?? '',
      relativePosition: json['position'] ?? 'ahead',
      estimatedDistance: json['distance'] ?? 'nearby',
    );
  }
}

class SceneDescription {
  final String spokenSummary;
  final List<DetectedEntity> entities;
  final String lightingCondition;
  final bool containsPeople;
  final String safetyAssessment;
  final DateTime timestamp;

  SceneDescription({
    required this.spokenSummary,
    this.entities = const [],
    this.lightingCondition = 'Normal',
    this.containsPeople = false,
    this.safetyAssessment = 'Safe to proceed with caution',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SceneDescription.empty() {
    return SceneDescription(
      spokenSummary: 'No scene analysis available.',
      safetyAssessment: 'Unknown',
    );
  }
}
