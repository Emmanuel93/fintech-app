import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/kyc_provider.dart';

/// Análisis del alta — corre justo después de "Crear cuenta".
///
/// Es el momento en que la solicitud deja de ser papeleo y se convierte en una
/// decisión: se crea la cuenta y, con ella, se consulta el historial y se
/// calcula la capacidad de pago. De aquí salen las ofertas que el usuario verá.
///
/// **Esta pantalla sólo cierra su propio paso.** Crear la cuenta es una llamada
/// real (`/kyc/submit` + `/auth/register`) y no se marca como hecha hasta que
/// responde; los otros tres los cierra `/credit/after-analysis`, que es quien
/// consulta de verdad. Por eso aquí no hay coreografía: si esta pantalla
/// adelantara pasos, el usuario vería el análisis completarse y volver a
/// empezar al cambiar de módulo — un solo análisis, un solo contador.
class AccountAnalysisScreen extends StatefulWidget {
  const AccountAnalysisScreen({super.key});

  @override
  State<AccountAnalysisScreen> createState() => _AccountAnalysisScreenState();
}

class _AccountAnalysisScreenState extends State<AccountAnalysisScreen> {
  /// Los cuatro pasos que el usuario ve.
  static const _steps = [
    'Creando tu cuenta',
    'Consultando buró de crédito',
    'Consultando círculo de crédito',
    'Verificando tu capacidad de pago',
  ];

  bool _accountReady = false;
  bool _navigated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final provider = context.read<KycProvider>();
    final password = provider.stagedPassword;
    if (password.isEmpty) {
      // Entrada inválida (recarga directa a esta ruta): de vuelta al paso.
      if (mounted) context.go('/onboarding/password');
      return;
    }

    final ok = await provider.submitAndCreateAccount(password);
    if (!mounted) return;

    if (!ok) {
      setState(() => _error = provider.error ?? 'No pudimos crear tu cuenta.');
      return;
    }

    setState(() => _accountReady = true);
    // Lo justo para que se vea palomear el primer paso. Más pausa aquí se
    // percibe como un corte entre las dos mitades del mismo análisis.
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || _navigated) return;
    _navigated = true;
    // El análisis continúa en el módulo de crédito, que es quien conoce el
    // catálogo: precalifica y decide si hay ofertas que mostrar o si la
    // solicitud queda en revisión. Para el usuario es el mismo análisis.
    context.go('/credit/after-analysis');
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return _AnalysisError(message: _error!);

    return DsAnalysisView(
      title: 'Analizando tu perfil',
      subtitle: 'Estamos creando tu cuenta y revisando tu historial.\n'
          'Toma unos segundos, no cierres la app.',
      steps: _steps,
      currentStep: _accountReady ? 1 : 0,
    );
  }
}

/// El alta falló a medio análisis. Se ofrece reintentar sin perder nada de lo
/// capturado — el estado del KYC sigue en memoria.
class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsHeroScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          KrRise(
            child: Column(
              children: [
                Container(
                  width: ds.w(94),
                  height: ds.w(94),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off_rounded,
                      size: ds.sp(40), color: AppColors.onPrimary),
                ),
                SizedBox(height: ds.h(22)),
                Text('No pudimos terminar',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heroTitle(ds.sp(29),
                        color: AppColors.onPrimary)),
                SizedBox(height: ds.h(10)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ds.w(300)),
                  child: Text(
                    '$message Tus datos siguen guardados: puedes intentarlo otra vez.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      fontSize: ds.sp(14.5),
                      color: AppColors.onPrimary.withValues(alpha: 0.65),
                    ).copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          DsWhiteCta(
            label: 'Intentar de nuevo',
            onTap: () => context.go('/onboarding/password'),
          ),
        ],
      ),
    );
  }
}
