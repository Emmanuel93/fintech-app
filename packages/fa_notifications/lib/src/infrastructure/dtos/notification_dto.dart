import '../../domain/entities/notification_item.dart';

class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.isRead = false,
    this.actionRoute,
  });

  final String id, type, title, body, date;
  final bool isRead;
  final String? actionRoute;

  factory NotificationDto.fromJson(Map<String, dynamic> j) => NotificationDto(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        date: j['date'] as String,
        isRead: j['isRead'] as bool? ?? false,
        actionRoute: j['actionRoute'] as String?,
      );

  NotificationItem toDomain() => NotificationItem(
        id: id,
        type: _parseType(type),
        title: title,
        body: body,
        date: DateTime.parse(date).toLocal(),
        isRead: isRead,
        actionRoute: actionRoute,
      );

  static NotificationType _parseType(String s) =>
      NotificationType.values.firstWhere((e) => e.name == s,
          orElse: () => NotificationType.marketing);
}
