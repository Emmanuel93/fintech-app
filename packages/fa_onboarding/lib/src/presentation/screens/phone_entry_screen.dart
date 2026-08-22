import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../alta_step.dart';
import '../providers/kyc_provider.dart';

/// Paso 3 del alta — "¿A qué celular te mandamos el código?"
/// (Journey L161–L199, datos en L1158–L1169).
///
/// Captura celular **y correo** en una sola tarjeta blanca y manda el código al
/// continuar: la verificación va pegada a la captura, sin pantallas de por
/// medio que enfríen la espera del SMS. La autorización ya se firmó en el
/// paso 1, y este código es el que deja constancia de ella.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _hydrated = false;

  /// Journey L1165–L1168.
  static const _notes = [
    'Nunca compartimos tu número ni te llamamos para venderte nada.',
    'Si cambias de número después, lo actualizas desde tu perfil.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    // Volver atrás desde el código no debe borrar lo ya escrito.
    final st = context.read<KycProvider>().state;
    if (st.phone.isNotEmpty) _phoneCtrl.text = st.phone;
    if (st.email.isNotEmpty) _emailCtrl.text = st.email;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<KycProvider>();
    provider.setContacto(
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );
    final ok = await provider.sendOtp();
    if (ok && mounted) context.go('/onboarding/otp');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<KycProvider>();

    return DsLoaderOverlay(
      isLoading: provider.isLoading,
      message: 'Enviando código...',
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DsOnboardingTopBar(
                            step: AltaStep.celular.number,
                            total: AltaStep.total,
                            onBack: () => context.go('/onboarding/purpose'),
                          ),
                          SizedBox(height: ds.h(24)),
                          Text('¿A qué celular te mandamos el código?',
                              style: AppTextStyles.screenTitle(
                                  fontSize: ds.sp(27))),
                          SizedBox(height: ds.h(6)),
                          Text(
                            'Con este número firmas tu contrato y recibes los avisos '
                            'de tu crédito. Debe estar a tu nombre.',
                            style: AppTextStyles.body(fontSize: ds.sp(14)),
                          ),
                          SizedBox(height: ds.h(22)),

                          // Tarjeta con los dos campos — Journey L172–L187.
                          Container(
                            padding: EdgeInsets.all(ds.w(16)),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                  ds.r(AppRadii.cardSmall)),
                              border:
                                  Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('NÚMERO CELULAR',
                                    style: AppTextStyles.captionLabel(
                                        fontSize: ds.sp(10))),
                                SizedBox(height: ds.h(8)),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _CountryPrefix(),
                                    SizedBox(width: ds.w(9)),
                                    Expanded(
                                      child: DsFormField(
                                        label: 'Número celular',
                                        showLabel: false,
                                        hint: '55 1234 5678',
                                        controller: _phoneCtrl,
                                        height: 52,
                                        fillColor: AppColors.fieldFillOnCard,
                                        keyboardType: TextInputType.phone,
                                        maxLength: 10,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        validator: (v) =>
                                            (v == null || v.trim().length != 10)
                                                ? 'Número de 10 dígitos'
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ds.h(14)),
                                Text('CORREO ELECTRÓNICO',
                                    style: AppTextStyles.captionLabel(
                                        fontSize: ds.sp(10))),
                                SizedBox(height: ds.h(8)),
                                DsFormField(
                                  label: 'Correo electrónico',
                                  showLabel: false,
                                  hint: 'tunombre@correo.com',
                                  controller: _emailCtrl,
                                  height: 52,
                                  fillColor: AppColors.fieldFillOnCard,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) return 'Requerido';
                                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                        .hasMatch(value)) {
                                      return 'Correo inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: ds.h(14)),
                          for (final note in _notes) ...[
                            _Note(text: note),
                            SizedBox(height: ds.h(9)),
                          ],
                          if (provider.error != null) ...[
                            SizedBox(height: ds.h(4)),
                            Text(provider.error!,
                                style: AppTextStyles.body(
                                    fontSize: ds.sp(12.5),
                                    color: AppColors.error)),
                          ],
                          SizedBox(height: ds.h(12)),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      ds.gutter, 0, ds.gutter, ds.bottomGap(28)),
                  child: DsButton(
                    label: 'Continuar',
                    isLoading: provider.isLoading,
                    onPressed: _continue,
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

/// Prefijo de país con chevron — Journey L176–L179. El selector no navega:
/// hoy el BFF sólo da de alta números mexicanos de 10 dígitos.
class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Container(
      width: ds.w(76),
      height: ds.h(52),
      decoration: BoxDecoration(
        color: AppColors.fieldFillOnCard,
        borderRadius: BorderRadius.circular(ds.r(12)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('+52',
              style: AppTextStyles.inputText(fontSize: ds.sp(15))
                  .copyWith(fontWeight: FontWeight.w600)),
          SizedBox(width: ds.w(7)),
          Icon(Icons.expand_more_rounded,
              size: ds.sp(14), color: AppColors.disabled),
        ],
      ),
    );
  }
}

/// Nota con palomita teal — Journey L191–L194.
class _Note extends StatelessWidget {
  const _Note({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: ds.w(18),
          height: ds.w(18),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded,
              size: ds.sp(11), color: AppColors.secondary),
        ),
        SizedBox(width: ds.w(11)),
        Expanded(
          child: Text(text,
              style: AppTextStyles.body(fontSize: ds.sp(12.5))
                  .copyWith(height: 1.45)),
        ),
      ],
    );
  }
}
