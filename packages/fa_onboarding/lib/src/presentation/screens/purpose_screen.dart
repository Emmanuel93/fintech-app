import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../alta_step.dart';

/// Paso 1 del alta — para qué quiere el crédito.
///
/// Es la primera pregunta porque gobierna todo lo que sigue: qué productos se
/// evalúan en el análisis, a qué pantalla se llega después, qué clausulado
/// lleva el contrato y en qué se enfoca el home. Preguntarlo al final obligaría
/// a rehacer la evaluación.
///
/// Dos caminos, no más: quien pide para sí y quien coloca con terceros. Todo lo
/// demás (tipo de producto, monto, plazo) se resuelve después con el catálogo,
/// que es donde debe vivir la variedad.
class PurposeScreen extends StatefulWidget {
  const PurposeScreen({super.key});

  @override
  State<PurposeScreen> createState() => _PurposeScreenState();
}

class _PurposeScreenState extends State<PurposeScreen> {
  CreditPurpose? _selected;

  void _continue() {
    final purpose = _selected;
    if (purpose == null) return;
    AppSession.instance.purpose = purpose;
    context.go('/onboarding/phone');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(ds.gutter, ds.topGap, ds.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsOnboardingTopBar(
                        step: AltaStep.proposito.number,
                        total: AltaStep.total,
                        onBack: () => context.go('/onboarding/privacy'),
                      ),
                      SizedBox(height: ds.h(24)),
                      Text('¿Cómo vas a usar tu crédito?',
                          style:
                              AppTextStyles.screenTitle(fontSize: ds.sp(27))),
                      SizedBox(height: ds.h(11)),
                      Text(
                        'Esto define qué productos te mostramos y qué papeles '
                        'vas a firmar. Puedes cambiarlo después.',
                        style: AppTextStyles.body(fontSize: ds.sp(14))
                            .copyWith(height: 1.55),
                      ),
                      SizedBox(height: ds.h(22)),
                      for (final purpose in CreditPurpose.values) ...[
                        _PurposeCard(
                          purpose: purpose,
                          selected: _selected == purpose,
                          onTap: () => setState(() => _selected = purpose),
                        ),
                        SizedBox(height: ds.h(12)),
                      ],
                      SizedBox(height: ds.h(4)),
                      // La regla que hay que entender antes de elegir: colocar
                      // no es firmar por otro. Es el contrato de todo el flujo
                      // de colocación que viene después.
                      const DsNoticeBanner(
                        text: 'Si eliges distribuidora, cada persona a la que le '
                            'coloques tiene que hacer su propio KYC y autorizar '
                            'su consulta de buró. Tú no puedes firmar por ella.',
                      ),
                      // El comité sólo aplica a la línea de distribuidor, así
                      // que sólo se dice cuando esa es la opción elegida.
                      if (_selected?.isDistribuidor ?? false) ...[
                        SizedBox(height: ds.h(10)),
                        const DsInfoBanner(
                          icon: Icons.info_outline_rounded,
                          text: 'Tu solicitud pasa por un comité: te avisamos en '
                              'cuanto haya respuesta.',
                        ),
                      ],
                      SizedBox(height: ds.h(20)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    ds.gutter, 0, ds.gutter, ds.bottomGap(28)),
                child: DsButton(
                  label: 'Continuar',
                  onPressed: _selected == null ? null : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de opción — icono en tile, título, descripción, radio y, **sólo al
/// elegirla**, las tres viñetas de lo que incluye (Journey App L995–L1016).
class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.purpose,
    required this.selected,
    required this.onTap,
  });

  final CreditPurpose purpose;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final icon = purpose.isDistribuidor
        ? Icons.storefront_outlined
        : Icons.person_outline_rounded;

    return Semantics(
      button: true,
      selected: selected,
      label: '${purpose.title}. ${purpose.subtitle}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
          child: AnimatedContainer(
            duration: KrediusMotion.tab,
            padding: EdgeInsets.all(ds.w(18)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
              border: Border.all(
                color:
                    selected ? AppColors.primary : AppColors.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ds.w(42),
                      height: ds.w(42),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(ds.r(13)),
                      ),
                      child: Icon(icon,
                          size: ds.sp(22),
                          color: selected
                              ? AppColors.onPrimary
                              : AppColors.primary),
                    ),
                    SizedBox(width: ds.w(14)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(purpose.title,
                                    style: AppTextStyles.cardTitle(
                                        fontSize: ds.sp(16))
                                      .copyWith(height: 1.25)),
                              ),
                              SizedBox(width: ds.w(9)),
                              _Radio(selected: selected),
                            ],
                          ),
                          SizedBox(height: ds.h(7)),
                          Text(purpose.subtitle,
                              style: AppTextStyles.body(fontSize: ds.sp(12.5))
                                  .copyWith(height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selected) ...[
                  SizedBox(height: ds.h(14)),
                  Divider(
                      height: 1, thickness: 1, color: AppColors.divider),
                  SizedBox(height: ds.h(14)),
                  for (final (i, text) in purpose.highlights.indexed) ...[
                    if (i > 0) SizedBox(height: ds.h(9)),
                    DsCheckBullet(text: text),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Radio de 20 px — el diseño lo llena con un borde de 6 px en vez de un punto
/// interior (Journey App L1916), que a este tamaño se ve más sólido.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return AnimatedContainer(
      duration: KrediusMotion.tab,
      width: ds.w(20),
      height: ds.w(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.filledBorder,
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}
