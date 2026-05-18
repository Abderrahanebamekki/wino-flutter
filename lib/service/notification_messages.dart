class NotificationMessages {
  NotificationMessages._();

  static String safezoneEnter(String childName, String safezoneName) {
    return '$childName ENTER the $safezoneName zone';
  }

  static String safezoneExit(String childName, String safezoneName) {
    return '$childName EXIT the $safezoneName zone';
  }

  static String abnormalSpeed(String childName, double speed) {
    final displaySpeed = speed.toStringAsFixed(speed == speed.roundToDouble() ? 0 : 1);
    return '$childName has abnormal speed $displaySpeed km';
  }
}
