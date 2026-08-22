import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/credit_application_provider.dart';

/// Continuación del análisis del alta — precalifica y decide a dónde llevar.
///
/// El alta crea la cuenta (`fa_onboarding`) y esta pantalla hace lo que sigue:
/// pedir la precalificación y rutear. Son dos pantallas porque son dos módulos
/// —el alta no conoce el catálogo de crédito—, pero para el usuario es **un
/// solo análisis**: mismos pasos, mismo contador. El alta deja cerrado el
/// primero y aquí se retoma en el segundo, nunca desde cero.
///
/// El destino depende de lo que el scoring haya abierto:
///
/// - Hay algo **aprobado** → oportunidades: existe una oferta real que tomar.
/// - No hay nada aprobado pero sí productos que pasan a comité —el caso típico
///   del distribuidor— → home, que lo muestra "en revisión". Llevarlo a un
///   catálogo que no puede contratar sería enseñarle una puerta cerrada.
class PostAnalysisScreen extends StatefulWidget {
  const PostAnalysisScreen({super.key});

  @override
  State<PostAnalysisScreen> createState() => _PostAnalysisScreenState();
}

class _PostAnalysisScreenState extends State<PostAnalysisScreen> {
  /// Los mismos pasos del alta: el primero ya viene hecho de allá.
  static const _steps = [
    'Creando tu cuenta',
    'Consultando buró de crédito',
    'Consultando círculo de crédito',
    'Verificando tu capacidad de pago',
  ];

  static const _tick = Duration(milliseconds: 850);

  int _step = 1;
  bool _done = false;
  Timer? _choreography;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    _choreography = Timer.periodic(_tick, (t) {
      if (!mounted) return t.cancel();
      if (_step >= _steps.length - 1) {
        t.cancel();
        return;
      }
      setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _choreography?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    final provider = context.read<CreditApplicationProvider>();
    // La precalificación es la consulta real: hasta que responde, el último
    // paso sigue abierto.
    await provider.loadProducts();
    await provider.loadPrequalifiedProducts();
    if (!mounted) return;

    setState(() => _done = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(provider.postAnalysisRoute);
  }

  @override
  Widget build(BuildContext context) {
    final esDistribuidor = AppSession.instance.purpose.isDistribuidor;

    return DsAnalysisView(
      title: 'Analizando tu perfil',
      subtitle: esDistribuidor
          ? 'Revisamos tu historial y las líneas de colocación disponibles.\n'
              'Toma unos segundos, no cierres la app.'
          : 'Estamos creando tu cuenta y revisando tu historial.\n'
              'Toma unos segundos, no cierres la app.',
      steps: _steps,
      currentStep: _done ? _steps.length : _step,
    );
  }
}
