import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification.dart';
import '../models/notification_category.dart';
import '../screens/local_notification_service.dart';
import 'auth_token_service.dart';
import 'notification_messages.dart';
import 'notification_preferences_service.dart';

class AlertNotificationService {
  static const String baseUrl = 'http://zephyr.proxy.rlwy.net:28363';
  static int _notificationId = 0;

  static Stream<NotificationM> listenForAlerts() async* {
    final token = await AuthTokenService.getToken();

    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/notifications/subscribe'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'text/event-stream',
    });

    final client = http.Client();

    try {
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        throw Exception(
          'Notification stream failed: ${streamedResponse.statusCode}',
        );
      }

      await for (final chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final line = chunk.trim();

        if (line.isEmpty) continue;
        if (!line.startsWith('data:')) continue;

        final body = line.substring(5).trim();
        final json = jsonDecode(body);

        final dateTimeStr = json['dateTime'] as String? ?? '';
        final typeStr = json['type'] as String? ?? 'UPDATE';
        final dateTime = DateTime.tryParse(dateTimeStr) ?? DateTime.now();

        final childName = json['childName'] as String? ?? 'Unknown';
        final safezoneName = json['safezoneName'] as String?;
        final speed = (json['speed'] as num?)?.toDouble();

        String message;
        String title;
        NotificationCategory category;

        switch (typeStr.toUpperCase()) {
          case 'SAFEZONE_ENTER':
            title = 'Location Update';
            category = NotificationCategory.update;
            message = NotificationMessages.safezoneEnter(
              childName,
              safezoneName ?? 'Unknown',
            );
            break;
          case 'SAFEZONE_EXIT':
            title = 'Location Update';
            category = NotificationCategory.update;
            message = NotificationMessages.safezoneExit(
              childName,
              safezoneName ?? 'Unknown',
            );
            break;
          case 'ABNORMAL_SPEED':
            title = 'Speed Alert';
            category = NotificationCategory.alert;
            message = NotificationMessages.abnormalSpeed(
              childName,
              speed ?? 0,
            );
            break;
          case 'ALERT':
            category = NotificationCategory.alert;
            title = 'Alert';
            message = json['message'] as String? ?? '';
            break;
          case 'INVITATION':
            category = NotificationCategory.invitation;
            title = 'Invitation';
            message = json['message'] as String? ?? '';
            break;
          default:
            category = NotificationCategory.update;
            title = 'Update';
            message = json['message'] as String? ?? '';
        }

        final isSpeedRelated = typeStr.toUpperCase() == 'ABNORMAL_SPEED' ||
            (json['message'] as String? ?? '').toLowerCase().contains('speed') ||
            message.toLowerCase().contains('speed');

        final shouldShow = await NotificationPreferencesService.shouldShowNotification(
          isSpeedRelated: isSpeedRelated,
        );

        if (!shouldShow) continue;

        final notification = NotificationM(
          title: title,
          message: message,
          category: category,
          time: dateTime,
        );

        _notificationId++;
        await LocalNotificationService.showNotification(
          id: _notificationId,
          title: title,
          body: message,
        );

        yield notification;
      }
    } finally {
      client.close();
    }
  }
}
