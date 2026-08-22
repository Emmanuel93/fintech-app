import 'package:fa_core/fa_core.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/ports/i_notification_repository.dart';
import '../dtos/notification_dto.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  NotificationRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<List<NotificationItem>> getNotifications() async {
    final json = await _client.get('/notifications');
    final list = json['notifications'] as List<dynamic>;
    return list
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
  }

  @override
  Future<bool> markAsRead({required String id}) async {
    final json = await _client.put('/notifications/$id/read');
    return json['success'] as bool? ?? false;
  }

  @override
  Future<bool> markAllRead() async {
    final json = await _client.put('/notifications/read-all');
    return json['success'] as bool? ?? false;
  }
}
