import 'package:fa_design_system/fa_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/placement_provider.dart';
import '../widgets/placement_top_bar.dart';

/// Paso 1 de la colocación — "¿A quién le vas a prestar?"
/// (Journey App L1029–L1078).
///
/// Sólo tres datos, y ninguno es del expediente: el expediente lo llena el
/// beneficiario en su propio teléfono. Aquí sólo se dice a quién, a qué número
/// mandarle la liga y de qué se conocen.
class BeneficiaryEntryScreen extends StatefulWidget {
  const BeneficiaryEntryScreen({super.key});

  @override
  State<BeneficiaryEntryScreen> createState() => _BeneficiaryEntryScreenState();
}

class _BeneficiaryEntryScreenState extends State<BeneficiaryEntryScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relationship = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlacementProvider>().startNew();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  /// El celular tiene que ser suyo y de 10 dígitos: ahí le llega el código con
  /// el que autoriza. Sin eso, no hay a quién mandarle nada.
  bool get _isReady =>
      _name.text.trim().split(RegExp(r'\s+')).length >= 2 &&
      _phone.text.replaceAll(RegExp(r'\D'), '').length == 10;

  void _continue() {
    if (!_isReady) return;
    context.go('/placements/new/amount', extra: {
      'fullName': _name.text.trim(),
      'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
      'relationship': _relationship.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<PlacementProvider>();
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);

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
                      PlacementTopBar(
                        title: 'Enviar préstamo',
                        trailing: 'Línea ${fmt.format(provider.available)}',
                        onBack: () => context.go('/home'),
                      ),
                      SizedBox(height: ds.h(20)),
                      const DsSegmentBar(total: 3, current: 0),
                      SizedBox(height: ds.h(20)),
                      Text('¿A quién le vas a prestar?',
                          style: AppTextStyles.heroTitle(ds.sp(24))
                              .copyWith(height: 1.2)),
                      SizedBox(height: ds.h(10)),
                      Text(
                        'El crédito y el contrato quedan a nombre de esta '
                        'persona. La deuda de tu línea sigue siendo tuya.',
                        style: AppTextStyles.body(fontSize: ds.sp(13.5))
                            .copyWith(height: 1.55),
                      ),
                      SizedBox(height: ds.h(20)),
                      _Card(
                        title: 'DATOS PARA EMPEZAR',
                        children: [
                          DsFormField(
                            label: 'Nombre completo, como en su INE',
                            controller: _name,
                            hint: 'María Luisa Cortés Hernández',
                            textCapitalization: TextCapitalization.words,
                            fillColor: AppColors.fieldFillOnCard,
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: ds.h(14)),
                          DsFormField(
                            label: 'Su celular a 10 dígitos',
                            controller: _phone,
                            hint: '55 4182 9037',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            fillColor: AppColors.fieldFillOnCard,
                            onChanged: (_) => setState(() {}),
                          ),
                          SizedBox(height: ds.h(7)),
                          _Hint(
                            text: 'Ahí le llega su código para autorizar. Tiene '
                                'que ser suyo, no el tuyo.',
                          ),
                          SizedBox(height: ds.h(14)),
                          DsFormField(
                            label: 'Cómo la conoces',
                            controller: _relationship,
                            hint: 'Clienta de mi tienda desde 2023',
                            textCapitalization: TextCapitalization.sentences,
                            fillColor: AppColors.fieldFillOnCard,
                          ),
                          SizedBox(height: ds.h(7)),
                          _Hint(
                              text: 'Nos ayuda a validar la relación comercial.'),
                        ],
                      ),
                      SizedBox(height: ds.h(16)),
                      Text('CÓMO SE VERIFICA',
                          style: AppTextStyles.captionLabel(
                              fontSize: ds.sp(10))),
                      SizedBox(height: ds.h(10)),
                      const _SelfServiceMode(),
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
                  onPressed: _isReady ? _continue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Único modo de verificación disponible — Journey App L1940–L1942.
///
/// Se dibuja como opción seleccionada, y no como un párrafo, porque el diseño
/// contempla que más adelante haya un segundo modo (asistido). Hoy hay uno solo
/// y por eso no se puede deseleccionar.
class _SelfServiceMode extends StatelessWidget {
  const _SelfServiceMode();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: EdgeInsets.all(ds.w(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ds.w(38),
            height: ds.w(38),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(ds.r(11)),
            ),
            child: Icon(Icons.link_rounded,
                size: ds.sp(19), color: AppColors.onPrimary),
          ),
          SizedBox(width: ds.w(13)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ella se verifica sola',
                    style: AppTextStyles.body(
                      fontSize: ds.sp(14),
                      weight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ).copyWith(height: 1.25)),
                SizedBox(height: ds.h(5)),
                Text(
                  'Le llega una liga por WhatsApp: pone su código, fotografía '
                  'su INE y se toma su video. Desde su propio celular, sin ti.',
                  style: AppTextStyles.body(fontSize: ds.sp(11.5))
                      .copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          SizedBox(width: ds.w(10)),
          Container(
            width: ds.w(20),
            height: ds.w(20),
            margin: EdgeInsets.only(top: ds.h(2)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      padding: EdgeInsets.all(ds.w(18)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall + 2)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
          SizedBox(height: ds.h(14)),
          ...children,
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Text(text,
        style: AppTextStyles.body(
          fontSize: ds.sp(11),
          color: AppColors.disabled,
        ).copyWith(height: 1.4));
  }
}
