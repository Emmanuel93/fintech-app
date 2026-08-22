import '../../domain/entities/notification_item.dart';
import '../../domain/ports/i_notification_repository.dart';

class GetNotificationsUseCase {
  const GetNotificationsUseCase(this._repo);
  final INotificationRepository _repo;
  Future<List<NotificationItem>> call() => _repo.getNotifications();
}
