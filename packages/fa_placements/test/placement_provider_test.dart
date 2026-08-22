/// Cableado completo del módulo: provider → casos de uso → repositorio → DTOs
/// → mock. Si el contrato del mock y el de los DTOs se separan, esto falla
/// aquí y no en pantalla.
library;

import 'package:dio/dio.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_placements/fa_placements.dart';
import 'package:flutter_test/flutter_test.dart';

/// `ApiClient` mínimo sobre un Dio con el interceptor del mock. No se usa
/// `DioApiClient` del shell porque este paquete no depende de él.
class _TestApiClient implements ApiClient {
  _TestApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, String>? headers, Map<String, dynamic>? queryParams}) async {
    final r = await _dio.get(path, queryParameters: queryParams);
    return (r.data as Map).cast<String, dynamic>();
  }

  @override
  Future<List<dynamic>> getList(String path,
      {Map<String, String>? headers, Map<String, dynamic>? queryParams}) async {
    final r = await _dio.get(path, queryParameters: queryParams);
    return r.data as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body,
      Map<String, String>? headers,
      Map<String, dynamic>? queryParams}) async {
    final r = await _dio.post(path, data: body, queryParameters: queryParams);
    return (r.data as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> put(String path,
      {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    final r = await _dio.put(path, data: body);
    return (r.data as Map).cast<String, dynamic>();
  }

  @override
  Future<Map<String, dynamic>> delete(String path,
      {Map<String, String>? headers}) async {
    final r = await _dio.delete(path);
    return (r.data as Map).cast<String, dynamic>();
  }

  @override
  void setBearerToken(String? token) {}
}

PlacementProvider _buildProvider() {
  PlacementsMockInterceptor.reset();
  final dio = Dio(BaseOptions(baseUrl: 'http://mock'))
    ..interceptors.add(PlacementsMockInterceptor());
  final repo = PlacementRepositoryImpl(apiClient: _TestApiClient(dio));
  return PlacementProvider(
    getLine: GetDistributorLineUseCase(repo),
    listPlacements: ListPlacementsUseCase(repo),
    getPlacement: GetPlacementUseCase(repo),
    createPlacement: CreatePlacementUseCase(repo),
    getBureauReport: GetBureauReportUseCase(repo),
    decidePlacement: DecidePlacementUseCase(repo),
    resendInvite: ResendInviteUseCase(repo),
    listBeneficiaries: ListBeneficiariesUseCase(repo),
  );
}

void main() {
  test('load trae línea, colocaciones y beneficiarios', () async {
    final p = _buildProvider();
    await p.load();

    expect(p.hasLine, isTrue);
    expect(p.line!.authorized, 250000);
    expect(p.line!.available, lessThan(p.line!.authorized));
    expect(p.placements, isNotEmpty);
    expect(p.beneficiaries, isNotEmpty);
    expect(p.error, isNull);
  });

  test('el filtro separa las que van al corriente de las atrasadas', () async {
    final p = _buildProvider();
    await p.load();

    p.setFilter(PlacementFilter.conAtraso);
    expect(p.visiblePlacements, isNotEmpty);
    expect(p.visiblePlacements.every((x) => x.isOverdue), isTrue);

    p.setFilter(PlacementFilter.alCorriente);
    expect(p.visiblePlacements.every((x) => !x.isOverdue), isTrue);
  });

  test('el buscador de beneficiarios encuentra por nombre y por celular',
      () async {
    final p = _buildProvider();
    await p.load();

    p.setBeneficiaryQuery('ramiro');
    expect(p.visibleBeneficiaries.single.name, contains('Ramiro'));

    // Los últimos dígitos del celular, como los recordaría el distribuidor.
    p.setBeneficiaryQuery('4488');
    expect(p.visibleBeneficiaries, hasLength(1));

    p.setBeneficiaryQuery('');
    expect(p.visibleBeneficiaries.length, p.beneficiaries.length);
  });

  test('crear una colocación la deja como la actual, invitada', () async {
    final p = _buildProvider();
    await p.load();

    final ok = await p.submit(
      fullName: 'Rosa Elena Díaz',
      phone: '5549029037',
      relationship: 'Clienta de mi tienda',
      amount: 18000,
      termFortnights: 24,
    );

    expect(ok, isTrue);
    expect(p.current, isNotNull);
    expect(p.current!.status, PlacementStatus.invited);
    expect(p.current!.beneficiaryName, 'Rosa Elena Díaz');
  });

  test('un monto sobre la línea no crea nada y deja mensaje', () async {
    final p = _buildProvider();
    await p.load();

    final ok = await p.submit(
      fullName: 'Rosa Elena Díaz',
      phone: '5549029037',
      relationship: '',
      amount: 999999,
      termFortnights: 24,
    );

    expect(ok, isFalse);
    expect(p.error, isNotNull);
  });

  test('abrir una colocación sin buró no inventa un reporte', () async {
    final p = _buildProvider();
    await p.load();
    await p.submit(
      fullName: 'Rosa Elena Díaz',
      phone: '5549029037',
      relationship: '',
      amount: 18000,
      termFortnights: 24,
    );

    await p.open(p.current!.id);

    expect(p.current!.status.isPending, isTrue);
    expect(p.report, isNull);
  });
}
