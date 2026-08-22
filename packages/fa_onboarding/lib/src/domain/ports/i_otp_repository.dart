abstract interface class IOtpRepository {
  Future<bool> send(String phone);

  /// Verifica el OTP. Retorna el `preAuthToken` (JWT de corta vida) que debe
  /// viajar como `Bearer` en `/ocr/extract`, `/kyc/submit` y `/auth/register`.
  /// Retorna `null` si el código es inválido o expiró.
  Future<String?> verify(String phone, String code);

  Future<bool> resend(String phone);
}
