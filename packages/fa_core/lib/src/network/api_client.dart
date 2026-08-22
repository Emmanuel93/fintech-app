abstract interface class ApiClient {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  });

  /// Para endpoints que devuelven un arreglo JSON en la raíz
  /// (p.ej. `/credit/account` retorna la lista de cuentas activas del cliente).
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  });

  /// `queryParams` porque hay endpoints del BFF que reciben datos por query
  /// aun siendo POST (`@RequestParam`), como los de soporte de pruebas.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  });

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  });

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  });

  void setBearerToken(String? token);
}
