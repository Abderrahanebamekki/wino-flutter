class VitalsLog {
  final int id;
  final String childId;
  final int heartbeats;
  final int oxygenLevel;
  final DateTime timestamp;

  VitalsLog({
    required this.id,
    required this.childId,
    required this.heartbeats,
    required this.oxygenLevel,
    required this.timestamp,
  });
}
