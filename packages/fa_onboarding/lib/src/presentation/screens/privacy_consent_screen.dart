import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../alta_step.dart';
import '../providers/kyc_provider.dart';
import 'privacy_notice_screen.dart';

/// Paso 1 del alta — "Tu privacidad y tu autorización"
/// (Journey L313–L366, datos en L1171–L1189).
///
/// Tres piezas, en este orden:
/// 1. Los **documentos legales** como filas tocables con su tiempo de lectura,
///    para que aceptarlos no sea aceptar algo invisible.
/// 2. La tarjeta **SE CONSULTAN** con las dos sociedades de información
///    crediticia — quién va a ver tu historial, con nombre y apellido.
/// 3. Los **tres consentimientos**: dos obligatorios y uno opcional
///    (comunicaciones comerciales), cada uno con su etiqueta.
///
/// Abre el alta porque nada se pide antes de tener permiso para pedirlo: el
/// celular, el correo y los documentos vienen después de esta firma. El código
/// que verifica el número llega en el paso 3 y es el que deja constancia de la
/// autorización que se otorga aquí.
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _privacy = false;
  bool _bureau = false;
  bool _marketing = false;

  /// Journey L1171–L1174.
  static const _legalDocs = <({String name, String meta})>[
    (
      name: 'Aviso de privacidad integral',
      meta: 'Qué datos guardamos, para qué y por cuánto tiempo · 4 min de lectura',
    ),
    (
      name: 'Términos de uso de Kredius',
      meta: 'Reglas de la app y de tu cuenta · 3 min de lectura',
    ),
  ];

  /// Journey L1321–L1322.
  static const _bureaus = <({String code, String name, String desc, bool teal})>[
    (
      code: 'BC',
      name: 'Buró de crédito',
      desc: 'Historial y comportamiento de pago',
      teal: false,
    ),
    (
      code: 'CC',
      name: 'Círculo de crédito',
      desc: 'Deuda vigente y capacidad de pago',
      teal: true,
    ),
  ];

  /// Sólo los dos obligatorios habilitan el CTA (Journey L1189).
  bool get _canContinue => _privacy && _bureau;

  void _openDoc(String name) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacyNoticeScreen()),
    );
  }

  void _authorize() {
    context.read<KycProvider>().setConsents(
          privacidad: _privacy,
          circulo: _bureau,
          marketing: _marketing,
        );
    context.go('/onboarding/purpose');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<KycProvider>();

    return DsLoaderOverlay(
      isLoading: provider.isLoading,
      child: Scaffold(
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
                          step: AltaStep.privacidad.number,
                          total: AltaStep.total,
                          onBack: () => context.go('/onboarding/welcome'),
                        ),
                        SizedBox(height: ds.h(24)),
                        Text('Tu privacidad y tu autorización',
                            style:
                                AppTextStyles.screenTitle(fontSize: ds.sp(27))),
                        SizedBox(height: ds.h(6)),
                        Text(
                          'Necesitamos dos permisos por separado. Puedes leer cada '
                          'documento completo antes de aceptar.',
                          style: AppTextStyles.body(fontSize: ds.sp(14)),
                        ),
                        SizedBox(height: ds.h(18)),

                        // Documentos legales — Journey L324–L337.
                        for (final doc in _legalDocs) ...[
                          _LegalDocRow(
                            name: doc.name,
                            meta: doc.meta,
                            onTap: () => _openDoc(doc.name),
                          ),
                          SizedBox(height: ds.h(10)),
                        ],

                        SizedBox(height: ds.h(6)),
                        // SE CONSULTAN — Journey L339–L352.
                        Container(
                          padding: EdgeInsets.all(ds.w(15)),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(ds.r(AppRadii.cardSmall)),
                            border: Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('SE CONSULTAN',
                                  style: AppTextStyles.captionLabel(
                                      fontSize: ds.sp(10))),
                              SizedBox(height: ds.h(13)),
                              for (var i = 0; i < _bureaus.length; i++) ...[
                                if (i > 0) SizedBox(height: ds.h(11)),
                                _BureauRow(
                                  code: _bureaus[i].code,
                                  name: _bureaus[i].name,
                                  desc: _bureaus[i].desc,
                                  teal: _bureaus[i].teal,
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: ds.h(14)),
                        // Consentimientos — Journey L354–L362.
                        _ConsentRow(
                          value: _privacy,
                          onChanged: (v) => setState(() => _privacy = v),
                          text:
                              'Leí y acepto el aviso de privacidad y los términos de uso.',
                          required: true,
                        ),
                        SizedBox(height: ds.h(9)),
                        _ConsentRow(
                          value: _bureau,
                          onChanged: (v) => setState(() => _bureau = v),
                          text:
                              'Autorizo expresamente a Kredius a consultar mi historial en '
                              'buró y círculo de crédito durante 90 días.',
                          required: true,
                        ),
                        SizedBox(height: ds.h(9)),
                        _ConsentRow(
                          value: _marketing,
                          onChanged: (v) => setState(() => _marketing = v),
                          text:
                              'Quiero recibir ofertas y novedades de Kredius por SMS y correo.',
                          required: false,
                        ),

                        if (provider.error != null) ...[
                          SizedBox(height: ds.h(12)),
                          Text(provider.error!,
                              style: AppTextStyles.body(
                                  fontSize: ds.sp(12.5),
                                  color: AppColors.error)),
                        ],
                        SizedBox(height: ds.h(18)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      ds.gutter, 0, ds.gutter, ds.bottomGap(28)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsButton(
                        label: 'Autorizar y continuar',
                        onPressed: _canContinue ? _authorize : null,
                      ),
                      SizedBox(height: ds.h(12)),
                      Text(
                        'Más adelante te enviamos un código SMS. Tu autorización '
                        'queda firmada con ese código.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de documento legal — Journey L326–L335.
class _LegalDocRow extends StatelessWidget {
  const _LegalDocRow({
    required this.name,
    required this.meta,
    required this.onTap,
  });

  final String name, meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: 'Abrir $name',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
          child: Container(
            padding: EdgeInsets.all(ds.w(15)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: ds.w(38),
                  height: ds.w(38),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(ds.r(11)),
                  ),
                  child: Icon(Icons.description_outlined,
                      size: ds.sp(18), color: AppColors.primary),
                ),
                SizedBox(width: ds.w(13)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppTextStyles.cardTitle(fontSize: ds.sp(14))
                              .copyWith(fontWeight: FontWeight.w600)),
                      SizedBox(height: ds.h(5)),
                      Text(meta,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(11.5),
                            color: AppColors.disabled,
                          ).copyWith(height: 1.35)),
                    ],
                  ),
                ),
                SizedBox(width: ds.w(8)),
                Icon(Icons.chevron_right_rounded,
                    size: ds.sp(18), color: AppColors.disabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de sociedad de información crediticia — Journey L343–L349.
class _BureauRow extends StatelessWidget {
  const _BureauRow({
    required this.code,
    required this.name,
    required this.desc,
    required this.teal,
  });

  final String code, name, desc;
  final bool teal;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      children: [
        Container(
          width: ds.w(44),
          height: ds.w(44),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: teal ? AppColors.secondary : AppColors.primary,
            borderRadius: BorderRadius.circular(ds.r(13)),
          ),
          child: Text(code,
              style: AppTextStyles.cardTitle(
                      fontSize: ds.sp(15), color: AppColors.onPrimary)
                  .copyWith(height: 1.0)),
        ),
        SizedBox(width: ds.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTextStyles.cardTitle(fontSize: ds.sp(13.5))
                      .copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: ds.h(4)),
              Text(desc,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(11.5),
                    color: AppColors.disabled,
                  ).copyWith(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Consentimiento con etiqueta OBLIGATORIO / OPCIONAL — Journey L356–L360,
/// estilos L1184–L1186.
class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.text,
    required this.required,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  // ignore: avoid_positional_boolean_parameters
  final bool required;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      checked: value,
      label: '$text ${required ? 'Obligatorio' : 'Opcional'}',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: KrediusMotion.tab,
          padding: EdgeInsets.all(ds.w(14)),
          decoration: BoxDecoration(
            color: value ? AppColors.primaryContainer : AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(14)),
            border: Border.all(
                color: value ? AppColors.primary : AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: KrediusMotion.tab,
                width: ds.w(20),
                height: ds.w(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(ds.r(6)),
                  border: Border.all(
                      color:
                          value ? AppColors.primary : AppColors.outlineVariant),
                ),
                child: Icon(Icons.check_rounded,
                    size: ds.sp(12),
                    color: value ? AppColors.onPrimary : Colors.transparent),
              ),
              SizedBox(width: ds.w(11)),
              Expanded(
                child: Text(text,
                    style: AppTextStyles.body(
                      fontSize: ds.sp(12),
                      weight: FontWeight.w500,
                      color: value
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurface,
                    ).copyWith(height: 1.5)),
              ),
              SizedBox(width: ds.w(9)),
              Padding(
                padding: EdgeInsets.only(top: ds.h(2)),
                child: DsStatusChip(
                  label: required ? 'OBLIGATORIO' : 'OPCIONAL',
                  tone: required ? DsChipTone.warning : DsChipTone.neutral,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
