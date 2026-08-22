import 'package:fa_core/fa_core.dart';
import 'package:flutter/foundation.dart';

import '../../application/use_cases/placement_use_cases.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/bureau_report.dart';
import '../../domain/entities/distributor_line.dart';
import '../../domain/entities/placement.dart';

/// Filtros de la pestaña Colocaciones — Journey App L2136.
enum PlacementFilter {
  todas('Todas'),
  alCorriente('Al corriente'),
  conAtraso('Con atraso'),
  enAlta('En alta');

  const PlacementFilter(this.label);
  final String label;

  bool matches(Placement p) => switch (this) {
        PlacementFilter.todas => true,
        PlacementFilter.alCorriente =>
          p.status == PlacementStatus.active && !p.isOverdue,
        PlacementFilter.conAtraso => p.isOverdue,
        PlacementFilter.enAlta => p.status.isPending,
      };
}

/// Estado del dominio de colocación.
class PlacementProvider extends ChangeNotifier with SafeNotifier {
  PlacementProvider({
    required GetDistributorLineUseCase getLine,
    required ListPlacementsUseCase listPlacements,
    required GetPlacementUseCase getPlacement,
    required CreatePlacementUseCase createPlacement,
    required GetBureauReportUseCase getBureauReport,
    required DecidePlacementUseCase decidePlacement,
    required ResendInviteUseCase resendInvite,
    required ListBeneficiariesUseCase listBeneficiaries,
  })  : _getLine = getLine,
        _listPlacements = listPlacements,
        _getPlacement = getPlacement,
        _createPlacement = createPlacement,
        _getBureauReport = getBureauReport,
        _decidePlacement = decidePlacement,
        _resendInvite = resendInvite,
        _listBeneficiaries = listBeneficiaries;

  final GetDistributorLineUseCase _getLine;
  final ListPlacementsUseCase _listPlacements;
  final GetPlacementUseCase _getPlacement;
  final CreatePlacementUseCase _createPlacement;
  final GetBureauReportUseCase _getBureauReport;
  final DecidePlacementUseCase _decidePlacement;
  final ResendInviteUseCase _resendInvite;
  final ListBeneficiariesUseCase _listBeneficiaries;

  DistributorLine? _line;
  List<Placement> _placements = const [];
  List<Beneficiary> _beneficiaries = const [];
  PlacementFilter _filter = PlacementFilter.todas;
  String _beneficiaryQuery = '';

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// La colocación que se está armando o revisando.
  Placement? _current;
  BureauReport? _report;

  DistributorLine? get line => _line;
  bool get hasLine => _line != null;
  List<Placement> get placements => _placements;
  List<Beneficiary> get beneficiaries => _beneficiaries;
  PlacementFilter get filter => _filter;
  String get beneficiaryQuery => _beneficiaryQuery;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  Placement? get current => _current;
  BureauReport? get report => _report;

  /// Las colocaciones vivas del filtro activo, más recientes primero.
  List<Placement> get visiblePlacements =>
      _placements.where(_filter.matches).toList();

  List<Beneficiary> get visibleBeneficiaries =>
      _beneficiaries.where((b) => b.matches(_beneficiaryQuery)).toList();

  /// Las que esperan decisión del distribuidor: son las que hay que empujar
  /// arriba, porque son las únicas donde él es el cuello de botella.
  List<Placement> get awaitingDecision => _placements
      .where((p) => p.status == PlacementStatus.bureauReady)
      .toList();

  double get available => _line?.available ?? 0;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notificar();
    try {
      _line = await _getLine();
      // Se publica para que el módulo de crédito no pinte esta misma línea con
      // su propio vocabulario. Ver `AppSession.hasDistributorLine`.
      AppSession.instance.hasDistributorLine = _line != null;
      // Sin línea no hay nada que listar y pedirlo sería ruido de red en cada
      // refresco del home de quien nunca va a colocar.
      if (_line != null) {
        _placements = await _listPlacements();
        _beneficiaries = await _listBeneficiaries();
      } else {
        _placements = const [];
        _beneficiaries = const [];
      }
    } catch (e) {
      _error = 'No pudimos cargar tus colocaciones';
      debugPrint('PlacementProvider.load: $e');
    } finally {
      _isLoading = false;
      notificar();
    }
  }

  void setFilter(PlacementFilter f) {
    if (_filter == f) return;
    _filter = f;
    notificar();
  }

  void setBeneficiaryQuery(String q) {
    if (_beneficiaryQuery == q) return;
    _beneficiaryQuery = q;
    notificar();
  }

  /// Arranca una colocación nueva. Limpia lo anterior para que el flujo no
  /// herede al beneficiario de la vez pasada.
  void startNew() {
    _current = null;
    _report = null;
    _error = null;
    notificar();
  }

  /// Crea la colocación y manda la liga. Devuelve `true` si salió.
  Future<bool> submit({
    required String fullName,
    required String phone,
    required String relationship,
    required double amount,
    required int termFortnights,
  }) async {
    _isSubmitting = true;
    _error = null;
    notificar();
    try {
      _current = await _createPlacement(
        fullName: fullName,
        phone: phone,
        relationship: relationship,
        amount: amount,
        termFortnights: termFortnights,
      );
      await load();
      return true;
    } catch (e) {
      _error = 'No pudimos enviar la liga. Revisa el celular e inténtalo otra vez.';
      debugPrint('PlacementProvider.submit: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notificar();
    }
  }

  /// Abre una colocación concreta y, si ya hay buró, lo trae.
  Future<void> open(String id) async {
    _isLoading = true;
    _error = null;
    _report = null;
    notificar();
    try {
      _current = await _getPlacement(id);
      if (_current!.status == PlacementStatus.bureauReady) {
        _report = await _getBureauReport(id);
      }
    } catch (e) {
      _error = 'No pudimos abrir esta colocación';
      debugPrint('PlacementProvider.open: $e');
    } finally {
      _isLoading = false;
      notificar();
    }
  }

  Future<bool> decide({required bool approve}) async {
    final id = _current?.id;
    if (id == null) return false;
    _isSubmitting = true;
    notificar();
    try {
      _current = await _decidePlacement(id, approve: approve);
      await load();
      return true;
    } catch (e) {
      _error = 'No pudimos registrar tu decisión';
      debugPrint('PlacementProvider.decide: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notificar();
    }
  }

  Future<void> resend(String id) async {
    try {
      _current = await _resendInvite(id);
      await load();
    } catch (e) {
      debugPrint('PlacementProvider.resend: $e');
    }
  }
}
