import '../../domain/ports/i_credit_repository.dart';

/// Dispara los endpoints de soporte del BFF (`/internal/test-support/*`).
///
/// Sólo lo usan las pruebas E2E, para no esperar en tiempo real a que un
/// crédito devengue, venza o caiga en mora. El BFF los tiene apagados por
/// configuración fuera de local, así que en la app instalada no hacen nada.
class RunTestSupportUseCase {
  const RunTestSupportUseCase(this._repository);
  final ICreditRepository _repository;

  Future<bool> call(String path, {Map<String, dynamic>? query}) =>
      _repository.runTestSupport(path, query: query);
}
