class GpsLog {
  final int id;
  final String childId;
  final double longitude;
  final double latitude;
  final double speed;
  final DateTime timestamp;

  GpsLog({
    required this.id,
    required this.childId,
    required this.longitude,
    required this.latitude,
    required this.speed,
    required this.timestamp,
  });
}
