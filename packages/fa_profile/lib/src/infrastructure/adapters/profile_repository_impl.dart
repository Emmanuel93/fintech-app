import 'package:fa_core/fa_core.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/ports/i_profile_repository.dart';
import '../dtos/profile_dto.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  ProfileRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<UserProfile> getProfile() async {
    final json = await _client.get('/users/me');
    return ProfileDto.fromJson(json).toDomain();
  }
}
