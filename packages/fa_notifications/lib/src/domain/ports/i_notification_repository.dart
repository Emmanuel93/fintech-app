import '../entities/notification_item.dart';

abstract interface class INotificationRepository {
  Future<List<NotificationItem>> getNotifications();
  Future<bool> markAsRead({required String id});
  Future<bool> markAllRead();
}
