class AuthUser {
  const AuthUser({
    required this.phone,
    required this.userId,
    required this.token,
    this.refreshToken,
    this.expiresIn,
  });

  final String phone;
  final String userId;
  final String token;
  final String? refreshToken;
  final int? expiresIn;
}
