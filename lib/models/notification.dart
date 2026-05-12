import 'notification_category.dart';


class NotificationM {
final String title;
final String message;
final NotificationCategory category;
final DateTime time;
final bool isRead;

NotificationM({
required this.title,
required this.message,
required this.category,
required this.time,
this.isRead = false,
});
}
