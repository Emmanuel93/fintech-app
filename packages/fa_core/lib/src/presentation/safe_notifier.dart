import 'package:flutter/foundation.dart';

/// Un [ChangeNotifier] que deja de avisar en cuanto lo destruyen.
///
/// Todos los providers de la app hacen lo mismo: disparan una petición y avisan
/// **cuando la respuesta llega**. Si para entonces la pantalla ya no existe
/// —el usuario se salió, la sesión se reinició, el test desmontó el árbol—,
/// `notifyListeners` sobre un notifier destruido lanza una aserción.
///
/// Lo caro no es el error, es dónde aparece: la excepción se dispara *después*
/// de que el trabajo terminó, así que se le atribuye a lo siguiente que esté
/// corriendo. En la suite de regresión se veía como si fallara el test de
/// login, cuando lo que estaba en vuelo era la carga del home anterior.
///
/// Envolverlo aquí y no repetir la bandera en cada provider evita justo lo que
/// pasó al descubrirlo: arreglarlo en uno y que el siguiente saliera igual.
///
/// ```dart
/// class MiProvider extends ChangeNotifier with SafeNotifier {
///   Future<void> load() async {
///     items = await _repo.fetch();
///     notificar();          // en vez de notifyListeners()
///   }
/// }
/// ```
mixin SafeNotifier on ChangeNotifier {
  bool _destruido = false;

  /// Ya no hay a quién avisar. Útil para cortar trabajo en vuelo, no sólo la
  /// notificación final.
  bool get destruido => _destruido;

  @override
  void dispose() {
    _destruido = true;
    super.dispose();
  }

  /// Como `notifyListeners`, pero calla si el provider ya se destruyó.
  void notificar() {
    if (_destruido) return;
    notifyListeners();
  }
}
