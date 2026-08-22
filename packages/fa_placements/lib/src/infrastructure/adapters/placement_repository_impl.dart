import 'package:fa_core/fa_core.dart';

import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/bureau_report.dart';
import '../../domain/entities/distributor_line.dart';
import '../../domain/entities/placement.dart';
import '../../domain/ports/i_placement_repository.dart';
import '../dtos/beneficiary_dto.dart';
import '../dtos/bureau_report_dto.dart';
import '../dtos/distributor_line_dto.dart';
import '../dtos/placement_dto.dart';

class PlacementRepositoryImpl implements IPlacementRepository {
  PlacementRepositoryImpl({required ApiClient apiClient}) : _client = apiClient;

  final ApiClient _client;

  @override
  Future<DistributorLine?> getLine() async {
    final json = await _client.get('/distributor/line-summary');
    // Sin línea autorizada no hay tarjeta que pintar. El BFF responde 200 con
    // `authorized: 0` en vez de 404 porque no tener línea no es un error.
    final dto = DistributorLineDto.fromJson(json);
    if (dto.authorized <= 0) return null;
    return dto.toDomain();
  }

  @override
  Future<List<Placement>> listPlacements() async {
    final json = await _client.get('/placements');
    final list = json['placements'] as List<dynamic>? ?? const [];
    return list
        .map((e) => PlacementDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
  }

  @override
  Future<Placement> getPlacement(String id) async {
    final json = await _client.get('/placements/$id');
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<Placement> createPlacement({
    required String fullName,
    required String phone,
    required String relationship,
    required double amount,
    required int termFortnights,
  }) async {
    final json = await _client.post('/placements', body: {
      'beneficiary': {
        'fullName': fullName,
        'phone': phone,
        'relationship': relationship,
      },
      'amount': amount,
      'termFortnights': termFortnights,
      // Único modo hoy: el beneficiario se verifica solo, desde su celular
      // (Journey App L1940–L1942).
      'verificationMode': 'SELF_SERVICE_LINK',
    });
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<Placement> resendInvite(String id) async {
    final json = await _client.post('/placements/$id/resend');
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<Placement> cancelPlacement(String id) async {
    final json = await _client.post('/placements/$id/cancel');
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<BureauReport> getBureauReport(String id) async {
    final json = await _client.get('/placements/$id/bureau');
    return BureauReportDto.fromJson(json).toDomain();
  }

  @override
  Future<Placement> approvePlacement(String id) async {
    final json = await _client.post('/placements/$id/approve',
        body: {'riskAcknowledged': true});
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<Placement> rejectPlacement(String id) async {
    final json = await _client.post('/placements/$id/reject');
    return PlacementDto.fromJson(json).toDomain();
  }

  @override
  Future<List<Beneficiary>> listBeneficiaries() async {
    final json = await _client.get('/beneficiaries');
    final list = json['beneficiaries'] as List<dynamic>? ?? const [];
    return list
        .map((e) =>
            BeneficiaryDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
  }
}
