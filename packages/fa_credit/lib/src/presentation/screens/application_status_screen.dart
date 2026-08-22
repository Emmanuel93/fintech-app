import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/credit_application_provider.dart';

/// Resolución de la solicitud — el cierre, no una segunda evaluación.
///
/// **Aquí no se vuelve a consultar buró ni círculo.** Eso ya pasó en el
/// análisis del alta y su autorización dura 90 días: repetirlo dejaría una
/// segunda huella de consulta en el historial del cliente por un crédito que
/// su score ya tenía preaprobado. Lo que ocurre en esta pantalla es lo que
/// falta después de configurar el monto: confirmar las condiciones contra la
/// preoferta y preparar el contrato. Por eso el copy dice que la solicitud está
/// casi lista — porque lo está.
///
/// **Cómo avanzan los pasos.** Los primeros avanzan con una coreografía
/// temporizada (el usuario necesita ver progreso), pero **el último se queda
/// activo hasta que llega la decisión real** del polling. Nunca se marca un
/// paso como terminado después de que el backend respondió algo distinto.
class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  /// Lo que de verdad falta: confirmar y formalizar. Nada de SIC.
  static const _steps = [
    'Confirmando el monto y el plazo',
    'Aplicando las condiciones de tu preoferta',
    'Preparando tu contrato',
  ];

  /// Cadencia de la coreografía. El prototipo usa 850ms.
  static const _tick = Duration(milliseconds: 850);

  int _step = 0;
  Timer? _choreography;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CreditApplicationProvider>().startPolling();
    });
    _choreography = Timer.periodic(_tick, (t) {
      // Se detiene en el último paso: ese lo cierra la respuesta real.
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditApplicationProvider>();
    final app = provider.application;

    if (app == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/credit/apply');
      });
      return const SizedBox.shrink();
    }

    // Transiciones que llevan a otra pantalla del flujo. Una oferta por debajo
    // de lo solicitado no va a "Aprobado": va a la ruta alterna de contraoferta.
    final String? redirect = app.isOfferPresented
        ? (provider.isCounterOffer
            ? '/credit/apply/counter-offer'
            : '/credit/apply/offer')
        : (app.isOfferAccepted || app.isPendingSignature)
            ? '/credit/apply/contract'
            : null;
    if (redirect != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(redirect);
      });
    }

    // El rechazo tiene pantalla propia desde que el diseño la incorporó
    // (Journey L960): explica el porqué y qué hacer, en vez de un mensaje seco.
    if (app.isRejected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/credit/apply/rejected');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (app.isManualReview) return const _ManualReviewState();

    return DsAnalysisView(
      title: 'Tu solicitud está casi lista',
      subtitle: 'Revisamos los últimos detalles con las condiciones que ya\n'
          'tenías aprobadas. No cierres la app.',
      steps: _steps,
      // Con la oferta ya lista, todos los pasos quedan cerrados.
      currentStep:
          app.isApproved || app.isOfferPresented ? _steps.length : _step,
    );
  }
}

// ─── Estados terminales ───────────────────────────────────────────────────────

class _ManualReviewState extends StatelessWidget {
  const _ManualReviewState();

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
                  decoration: const BoxDecoration(
                    color: AppColors.tertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: ds.sp(40), color: AppColors.onPrimary),
                ),
                SizedBox(height: ds.h(22)),
                Text(
                  'Tu solicitud pasa a comité',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroTitle(ds.sp(29),
                      color: AppColors.onPrimary),
                ),
                SizedBox(height: ds.h(10)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ds.w(300)),
                  child: Text(
                    'Un analista la va a revisar. Te avisamos por notificación en '
                    'cuanto tengamos una respuesta.',
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
          DsWhiteCta(label: 'Entendido', onTap: () => context.go('/home')),
        ],
      ),
    );
  }
}
