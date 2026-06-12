import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  static const String _speedEnabledKey = 'speed_notifications_enabled';
  static const String _snoozeUntilKey = 'snooze_until';

  static Future<bool> areSpeedNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_speedEnabledKey) ?? true;
  }

  static Future<void> setSpeedNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_speedEnabledKey, enabled);
    if (enabled) {
      await clearSnooze();
    }
  }

  static Future<DateTime?> getSnoozeUntil() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_snoozeUntilKey);
    if (millis == null) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    if (date.isBefore(DateTime.now())) {
      await clearSnooze();
      return null;
    }
    return date;
  }

  static Future<void> setSnoozeUntil(DateTime? snoozeUntil) async {
    final prefs = await SharedPreferences.getInstance();
    if (snoozeUntil == null) {
      await prefs.remove(_snoozeUntilKey);
    } else {
      await prefs.setInt(_snoozeUntilKey, snoozeUntil.millisecondsSinceEpoch);
    }
  }

  static Future<void> clearSnooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snoozeUntilKey);
  }

  static Future<bool> shouldShowNotification({
    required bool isSpeedRelated,
  }) async {
    final snoozeUntil = await getSnoozeUntil();
    if (snoozeUntil != null) {
      return false;
    }

    if (isSpeedRelated) {
      return await areSpeedNotificationsEnabled();
    }

    return true;
  }
}
