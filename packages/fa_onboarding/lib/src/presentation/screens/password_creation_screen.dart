import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../alta_step.dart';
import '../providers/kyc_provider.dart';

class PasswordCreationScreen extends StatefulWidget {
  const PasswordCreationScreen({super.key});

  @override
  State<PasswordCreationScreen> createState() => _PasswordCreationScreenState();
}

class _PasswordCreationScreenState extends State<PasswordCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  double _strength = 0;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _evaluateStrength(String value) {
    double strength = 0;
    if (value.length >= 8) strength += 0.25;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    setState(() => _strength = strength);
  }

  Color get _strengthColor {
    if (_strength <= 0.25) return AppColors.error;
    if (_strength <= 0.5) return AppColors.warning;
    if (_strength <= 0.75) return AppColors.tertiary;
    return AppColors.secondary;
  }

  String get _strengthLabel {
    if (_strength <= 0.25) return 'Débil';
    if (_strength <= 0.5) return 'Regular';
    if (_strength <= 0.75) return 'Buena';
    return 'Excelente';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<KycProvider>();
    // La cuenta se crea en la siguiente pantalla, que es la que muestra el
    // análisis: crear la cuenta y consultar el historial son el mismo momento.
    provider.stagePassword(_passCtrl.text);
    context.go('/onboarding/analysis');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final phone = context.watch<KycProvider>().state.phone;

    return Consumer<KycProvider>(
      builder: (_, provider, __) => DsLoaderOverlay(
        isLoading: provider.isLoading,
        message: 'Creando tu cuenta...',
        child: Scaffold(
          backgroundColor: AppColors.surfaceVariant,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: ds.gutter),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: ds.h(10)),
                          DsOnboardingTopBar(
                            step: AltaStep.contrasena.number,
                            total: AltaStep.total,
                            onBack: () => context.go('/onboarding/identity'),
                          ),
                          SizedBox(height: ds.h(17)),
                          Container(
                            padding: EdgeInsets.all(ds.w(16)),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    color: AppColors.secondary,
                                    size: ds.sp(20)),
                                SizedBox(width: ds.w(10)),
                                Expanded(
                                  child: Text(
                                    'Todos los documentos verificados ✓',
                                    style: AppTextStyles.body(
                                      fontSize: ds.sp(12.5),
                                      weight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ds.h(17)),
                          Icon(
                            Icons.lock_outline_rounded,
                            size: ds.sp(40),
                            color: AppColors.primary,
                          ),
                          SizedBox(height: ds.h(13)),
                          Text('Crea tu contraseña',
                              style: AppTextStyles.screenTitle(
                                  fontSize: ds.sp(27))),
                          SizedBox(height: ds.h(7)),
                          Text(
                            'Esta será tu contraseña para ingresar con tu número celular.',
                            style: AppTextStyles.body(fontSize: ds.sp(14)),
                          ),
                          SizedBox(height: ds.h(13)),
                          DsTextField(
                            label: 'Número celular (usuario)',
                            controller: TextEditingController(text: '+52 $phone'),
                            readOnly: true,
                            enabled: false,
                            prefixIcon: const Icon(Icons.phone_outlined),
                          ),
                          SizedBox(height: ds.h(13)),
                          DsTextField(
                            label: 'Contraseña',
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            onChanged: _evaluateStrength,
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'Mínimo 8 caracteres';
                              }
                              return null;
                            },
                          ),
                          if (_passCtrl.text.isNotEmpty) ...[
                            SizedBox(height: ds.h(9)),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _strength,
                                      backgroundColor: AppColors.outlineVariant,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          _strengthColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                SizedBox(width: ds.w(10)),
                                Text(
                                  _strengthLabel,
                                  style: AppTextStyles.body(fontSize: ds.sp(11)).copyWith(
                                    color: _strengthColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: ds.h(13)),
                          DsTextField(
                            label: 'Confirmar contraseña',
                            controller: _confirmCtrl,
                            obscureText: _obscureConfirm,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (v != _passCtrl.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ds.h(13)),
                          Container(
                            padding: EdgeInsets.all(ds.w(13)),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Requisitos de contraseña',
                                    style: AppTextStyles.body(fontSize: ds.sp(12))),
                                SizedBox(height: ds.h(9)),
                                _Req('Mínimo 8 caracteres',
                                    _passCtrl.text.length >= 8),
                                _Req('Al menos 1 mayúscula',
                                    _passCtrl.text.contains(RegExp(r'[A-Z]'))),
                                _Req('Al menos 1 número',
                                    _passCtrl.text.contains(RegExp(r'[0-9]'))),
                                _Req(
                                    'Al menos 1 símbolo (!@#\$...)',
                                    _passCtrl.text.contains(
                                        RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
                              ],
                            ),
                          ),
                          if (provider.error != null) ...[
                            SizedBox(height: ds.h(13)),
                            Container(
                              padding: EdgeInsets.all(ds.w(14)),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                provider.error!,
                                style: AppTextStyles.body(fontSize: ds.sp(12.5)).copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: ds.h(17)),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(ds.gutter, 0, ds.gutter, ds.bottomGap(26)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DsButton(
                        label: 'Crear cuenta',
                        icon: Icons.check_circle_outlined,
                        onPressed: _submit,
                        isLoading: provider.isLoading,
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

class _Req extends StatelessWidget {
  const _Req(this.label, this.met);
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: EdgeInsets.only(top: ds.h(4)),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: ds.sp(16),
            color: met ? AppColors.secondary : AppColors.disabled,
          ),
          SizedBox(width: ds.w(8)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: met ? AppColors.onSurface : AppColors.disabled,
                ),
          ),
        ],
      ),
    );
  }
}
