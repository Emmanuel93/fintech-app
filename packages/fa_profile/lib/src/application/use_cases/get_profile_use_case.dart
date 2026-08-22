import '../../domain/entities/user_profile.dart';
import '../../domain/ports/i_profile_repository.dart';

class GetProfileUseCase {
  const GetProfileUseCase(this._repo);
  final IProfileRepository _repo;
  Future<UserProfile> call() => _repo.getProfile();
}
