import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/get_notifications_use_case.dart';
import 'src/infrastructure/adapters/notification_repository_impl.dart';
import 'src/presentation/providers/notification_provider.dart';
import 'src/presentation/screens/notifications_screen.dart';

class NotificationsModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_notifications';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) {
            final repo = NotificationRepositoryImpl(apiClient: _apiClient);
            return NotificationProvider(
              getNotifications: GetNotificationsUseCase(repo),
              repository: repo,
            );
          },
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
      ];

  @override
  void initHome(BuildContext context) {
    final notif = context.read<NotificationProvider>();
    if (notif.items.isEmpty) notif.load();
  }

  @override
  int getHeaderBadgeCount(BuildContext context) =>
      context.watch<NotificationProvider>().unreadCount;

  @override
  Widget? buildHomeCard(BuildContext context) => null;
}
