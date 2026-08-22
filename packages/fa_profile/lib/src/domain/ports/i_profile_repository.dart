import '../entities/user_profile.dart';

abstract interface class IProfileRepository {
  Future<UserProfile> getProfile();
}
