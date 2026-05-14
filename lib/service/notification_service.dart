import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notification.dart';
import '../models/notification_category.dart';
import '../screens/local_notification_service.dart';
import 'auth_token_service.dart';

class AlertNotificationService {
  static const String baseUrl = 'http://10.0.2.2:8081';
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

        final messageText = json['message'] as String? ?? '';
        final dateTimeStr = json['dateTime'] as String? ?? '';
        final typeStr = json['type'] as String? ?? 'UPDATE';

        final dateTime = DateTime.tryParse(dateTimeStr) ?? DateTime.now();

        NotificationCategory category;
        String title;

        switch (typeStr.toUpperCase()) {
          case 'ALERT':
            category = NotificationCategory.alert;
            title = 'Alert';
            break;
          case 'INVITATION':
            category = NotificationCategory.invitation;
            title = 'Invitation';
            break;
          default:
            category = NotificationCategory.update;
            title = 'Update';
        }

        final notification = NotificationM(
          title: title,
          message: messageText,
          category: category,
          time: dateTime,
        );

        _notificationId++;
        await LocalNotificationService.showNotification(
          id: _notificationId,
          title: title,
          body: messageText,
        );

        yield notification;
      }
    } finally {
      client.close();
    }
  }
}
