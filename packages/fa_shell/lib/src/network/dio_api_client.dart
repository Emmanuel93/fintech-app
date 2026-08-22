import 'package:dio/dio.dart';
import 'package:fa_core/fa_core.dart';

class DioApiClient implements ApiClient {
  DioApiClient({
    required String baseUrl,
    List<Interceptor> interceptors = const [],
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    _dio.interceptors.addAll(interceptors);
  }

  late final Dio _dio;

  @override
  void setBearerToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  @override
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers),
    );
    return res.data!;
  }

  @override
  Future<List<dynamic>> getList(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers),
    );
    return res.data ?? const [];
  }

  @override
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      url,
      data: body,
      queryParameters: queryParams,
      options: Options(headers: headers),
    );
    return res.data!;
  }

  @override
  Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(headers: headers),
    );
    return res.data!;
  }

  @override
  Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      url,
      options: Options(headers: headers),
    );
    return res.data!;
  }
}
