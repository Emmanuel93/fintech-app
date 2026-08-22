import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fa_core/fa_core.dart';
import 'src/application/use_cases/get_profile_use_case.dart';
import 'src/infrastructure/adapters/profile_repository_impl.dart';
import 'src/presentation/providers/profile_provider.dart';
import 'src/presentation/screens/profile_screen.dart';

class ProfileModule extends IModule {
  late ApiClient _apiClient;
  // ignore: unused_field
  late NavigationCallbacks _navigation;

  @override
  String get moduleId => 'fa_profile';

  @override
  String get version => '1.0.0';

  @override
  void configure({required ApiClient apiClient, required NavigationCallbacks navigation}) {
    _apiClient = apiClient;
    _navigation = navigation;
  }

  @override
  List<Widget> get providers => [
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(
            getProfile: GetProfileUseCase(ProfileRepositoryImpl(apiClient: _apiClient)),
          ),
        ),
      ];

  @override
  List<RouteBase> get routes => [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ];

  @override
  void initHome(BuildContext context) {
    final profile = context.read<ProfileProvider>();
    if (profile.profile == null) profile.load();
  }

  @override
  String? getHeaderDisplayName(BuildContext context) =>
      context.watch<ProfileProvider>().profile?.firstName;

  @override
  Widget? buildHomeCard(BuildContext context) => null;
}
