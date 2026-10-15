enum HazardUrgency {
  critical, // Immediate stop / drop / collision risk
  warning,  // Caution needed within 2-3 steps
  advisory  // Info / safe path ahead
}

enum HazardDirection {
  ahead,
  left,
  right,
  ground,
  overhead
}

class DetectedHazard {
  final String title;
  final HazardUrgency urgency;
  final HazardDirection direction;
  final String estimatedDistance;
  final String spokenAlert;

  DetectedHazard({
    required this.title,
    required this.urgency,
    required this.direction,
    required this.estimatedDistance,
    required this.spokenAlert,
  });
}

class HazardAssessment {
  final bool hasHazards;
  final HazardUrgency highestUrgency;
  final List<DetectedHazard> hazards;
  final String spokenPriorityAlert;
  final bool isPathClear;
  final DateTime timestamp;

  HazardAssessment({
    required this.hasHazards,
    this.highestUrgency = HazardUrgency.advisory,
    this.hazards = const [],
    required this.spokenPriorityAlert,
    this.isPathClear = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory HazardAssessment.clearPath() {
    return HazardAssessment(
      hasHazards: false,
      isPathClear: true,
      highestUrgency: HazardUrgency.advisory,
      spokenPriorityAlert: 'Path ahead is clear. Proceed with usual awareness.',
    );
  }
}
