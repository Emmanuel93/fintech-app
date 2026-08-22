import 'package:flutter/material.dart';
import '../../application/use_cases/get_notifications_use_case.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/ports/i_notification_repository.dart';
import 'package:fa_core/fa_core.dart';

class NotificationProvider extends ChangeNotifier with SafeNotifier {
  NotificationProvider({
    required GetNotificationsUseCase getNotifications,
    required INotificationRepository repository,
  })  : _getNotifications = getNotifications,
        _repo = repository;

  final GetNotificationsUseCase _getNotifications;
  final INotificationRepository _repo;

  List<NotificationItem> items = [];
  bool isLoading = false;

  int get unreadCount => items.where((n) => !n.isRead).length;

  Future<void> load() async {
    isLoading = true;
    notificar();
    try {
      items = await _getNotifications();
    } catch (_) {
      // p.ej. 404 si notifications-service aún no está implementado.
      items = [];
    } finally {
      isLoading = false;
      notificar();
    }
  }

  Future<void> markRead(String id) async {
    await _repo.markAsRead(id: id);
    items = List.from(items.map((n) => n.id == id
        ? NotificationItem(
            id: n.id, type: n.type, title: n.title, body: n.body,
            date: n.date, isRead: true, actionRoute: n.actionRoute)
        : n));
    notificar();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    items = items.map((n) => NotificationItem(
        id: n.id, type: n.type, title: n.title, body: n.body,
        date: n.date, isRead: true, actionRoute: n.actionRoute)).toList();
    notificar();
  }
}
