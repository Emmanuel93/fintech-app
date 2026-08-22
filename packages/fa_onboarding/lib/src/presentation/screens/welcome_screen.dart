import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_design_system/fa_design_system.dart';

/// Bienvenida — pantalla 0 del prototipo "Kredius Journey" (L129–L159).
///
/// Héroe azul a sangre con los dos blobs radiales, lockup **invertido** arriba
/// (tile blanco + K azul, que es el tratamiento oficial sobre el azul de marca),
/// titular + subtítulo abajo, tres stat cards y el CTA blanco.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Los tres datos del prototipo (Journey L1059 — `heroStats`).
  static const _stats = <(String, String)>[
    ('3 min', 'SOLICITUD'),
    ('15 min', 'DEPÓSITO'),
    ('\$0', 'APERTURA'),
  ];

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;

    return DsHeroScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Journey L134–L141 — isotipo 46 + "Kredius" 22.
          const Align(
            alignment: Alignment.centerLeft,
            child: KrediusBrand.inverted(markSize: 46),
          ),

          // `margin-top:auto` del prototipo: empuja el bloque de copy abajo.
          // En pantallas cortas el Spacer se colapsa y el scroll del
          // DsHeroScaffold toma el relevo, en vez de desbordar.
          SizedBox(height: ds.h(24)),
          const Spacer(),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ds.w(330)),
            child: Text(
              'El dinero que necesitas, hoy.',
              style: AppTextStyles.heroTitle(
                ds.sp(42),
                color: AppColors.onPrimary,
              ),
            ),
          ),
          SizedBox(height: ds.h(16)),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ds.w(305)),
            child: Text(
              'Revisamos tu historial en buró y círculo de crédito y en minutos '
              'te decimos cuánto tienes autorizado. Sin filas y sin papeles.',
              style: AppTextStyles.body(
                fontSize: ds.sp(15.5),
                color: AppColors.onPrimary.withValues(alpha: 0.72),
              ).copyWith(height: 1.55),
            ),
          ),

          SizedBox(height: ds.h(30)),
          // IntrinsicHeight iguala el alto de las tres tarjetas (una etiqueta
          // que envuelve no debe dejar las otras dos más cortas). Es
          // imprescindible aquí además porque el héroe ya vive dentro de un
          // IntrinsicHeight —el que hace funcionar al Spacer dentro del
          // scroll—, y un Row con `stretch` sin acotar recibiría altura
          // infinita durante el cálculo intrínseco.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _stats.length; i++) ...[
                  if (i > 0) SizedBox(width: ds.w(10)),
                  Expanded(
                    child: _StatCard(
                        value: _stats[i].$1, label: _stats[i].$2),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: ds.h(26)),
          DsWhiteCta(
            label: 'Empezar solicitud',
            onTap: () => context.go('/onboarding/privacy'),
          ),
          SizedBox(height: ds.h(14)),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Área táctil cómoda sin alterar el espaciado visual.
                padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                child: Text.rich(
                  TextSpan(
                    text: 'Ya tengo cuenta · ',
                    style: AppTextStyles.body(
                      fontSize: ds.sp(13),
                      weight: FontWeight.w500,
                      color: AppColors.onPrimary.withValues(alpha: 0.62),
                    ).copyWith(height: 1.0),
                    children: [
                      TextSpan(
                        text: 'Entrar',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(13),
                          weight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ).copyWith(height: 1.0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de dato del héroe — Journey L147–L152.
class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: EdgeInsets.fromLTRB(ds.w(14), ds.h(14), ds.w(14), ds.h(16)),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(ds.r(16)),
        border:
            Border.all(color: AppColors.onPrimary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // En pantallas angostas tres columnas dejan ~95px por tarjeta:
          // el valor se reduce antes que truncarse.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.heroNumber(ds.sp(20),
                  color: AppColors.onPrimary, weight: FontWeight.w700),
            ),
          ),
          SizedBox(height: ds.h(8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.captionLabel(
                fontSize: ds.sp(9.5),
                color: AppColors.onPrimary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
