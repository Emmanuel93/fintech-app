import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../providers/auth_provider.dart';

/// Login — pantalla 0b del prototipo (Journey L63–L127, estilos L1033–L1046).
///
/// Mismo héroe azul que la bienvenida: lockup invertido + botón de cierre,
/// titular "Qué gusto verte otra vez.", campos translúcidos, CTA blanco con
/// botón de biometría al lado, separador y proveedores sociales.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onLoginSuccess});
  final void Function(String userId)? onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Credenciales de conveniencia sólo fuera de producción.
    if (AppConfig.current.flavor != AppFlavor.prod) {
      _phoneCtrl.text = '5510026001';
      _passwordCtrl.text = 'Test1234!';
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().login(
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (ok) {
      final userId = context.read<AuthProvider>().currentUser?.userId ?? '';
      widget.onLoginSuccess?.call(userId);
      if (widget.onLoginSuccess == null) context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<AuthProvider>().error ?? 'Error al ingresar'),
        ),
      );
    }
  }

  void _notAvailable(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what estará disponible muy pronto.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return DsLoaderOverlay(
      isLoading: isLoading,
      message: 'Iniciando sesión...',
      child: DsHeroScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Journey L69–L81 — marca + botón de cierre.
              Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: KrediusBrand.inverted(markSize: 46),
                    ),
                  ),
                  SizedBox(width: ds.w(12)),
                  DsGlassButton(
                    width: ds.w(38),
                    height: ds.w(38),
                    radius: 11,
                    semanticLabel: 'Cerrar',
                    onTap: () => context.go('/onboarding/welcome'),
                    child: Icon(Icons.close_rounded,
                        size: ds.sp(16), color: AppColors.onPrimary),
                  ),
                ],
              ),

              SizedBox(height: ds.h(24)),
              const Spacer(),

              // Journey L83–L86.
              Text(
                'Qué gusto verte otra vez.',
                style: AppTextStyles.heroTitle(ds.sp(42),
                    color: AppColors.onPrimary),
              ),
              SizedBox(height: ds.h(14)),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ds.w(305)),
                child: Text(
                  'Entra con el celular que registraste y sigue justo donde te quedaste.',
                  style: AppTextStyles.body(
                    fontSize: ds.sp(15.5),
                    color: AppColors.onPrimary.withValues(alpha: 0.72),
                  ).copyWith(height: 1.55),
                ),
              ),

              SizedBox(height: ds.h(28)),
              DsTranslucentField(
                label: 'CELULAR',
                hint: '55 1234 5678',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumberLocal],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) => (v == null || v.length < 10)
                    ? 'Ingresa un número de 10 dígitos'
                    : null,
              ),
              SizedBox(height: ds.h(12)),
              DsTranslucentField(
                label: 'CONTRASEÑA',
                hint: '••••••••',
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(horizontal: ds.w(14)),
                    child: Text(
                      _obscurePassword ? 'Ver' : 'Ocultar',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(11.5),
                        weight: FontWeight.w600,
                        color: AppColors.onPrimary.withValues(alpha: 0.7),
                      ).copyWith(height: 1.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ds.h(10)),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _notAvailable('La recuperación de contraseña'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                    child: Text(
                      'Olvidé mi contraseña',
                      style: AppTextStyles.body(
                        fontSize: ds.sp(12.5),
                        weight: FontWeight.w500,
                        color: AppColors.onPrimary.withValues(alpha: 0.72),
                      ).copyWith(height: 1.0),
                    ),
                  ),
                ),
              ),

              // Journey L103–L108 — CTA + biometría.
              SizedBox(height: ds.h(16)),
              Row(
                children: [
                  Expanded(
                    child: DsWhiteCta(
                        label: 'Entrar', onTap: isLoading ? null : _login),
                  ),
                  SizedBox(width: ds.w(10)),
                  DsGlassButton(
                    width: ds.h(52),
                    height: ds.h(52),
                    semanticLabel: 'Entrar con Face ID',
                    onTap: () => _notAvailable('El acceso con biometría'),
                    child: Icon(Icons.face_retouching_natural_outlined,
                        size: ds.sp(22), color: AppColors.onPrimary),
                  ),
                ],
              ),

              // Journey L110–L123 — separador + proveedores.
              SizedBox(height: ds.h(20)),
              Row(
                children: [
                  Expanded(child: _rule()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ds.w(12)),
                    child: Text(
                      'O ENTRA CON',
                      style: AppTextStyles.captionLabel(
                        fontSize: ds.sp(9.5),
                        color: AppColors.onPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(child: _rule()),
                ],
              ),
              SizedBox(height: ds.h(16)),
              Row(
                children: [
                  Expanded(
                    child: _ProviderButton(
                      label: 'Google',
                      onTap: () => _notAvailable('El acceso con Google'),
                    ),
                  ),
                  SizedBox(width: ds.w(10)),
                  Expanded(
                    child: _ProviderButton(
                      label: 'Apple',
                      onTap: () => _notAvailable('El acceso con Apple'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: ds.h(22)),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/onboarding'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: ds.h(6)),
                    child: Text.rich(
                      TextSpan(
                        text: '¿Aún no tienes cuenta? ',
                        style: AppTextStyles.body(
                          fontSize: ds.sp(13),
                          weight: FontWeight.w500,
                          color: AppColors.onPrimary.withValues(alpha: 0.62),
                        ).copyWith(height: 1.0),
                        children: [
                          TextSpan(
                            text: 'Créala en 3 minutos',
                            style: AppTextStyles.body(
                              fontSize: ds.sp(13),
                              weight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ).copyWith(height: 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: ds.h(8)),
              Center(
                child: Text(
                  AppConfig.current.flavor == AppFlavor.prod
                      ? 'Versión 1.0.0'
                      : 'Versión 1.0.0  ·  ${AppConfig.current.label}',
                  style: AppTextStyles.captionLabel(
                    fontSize: ds.sp(9.5),
                    color: AppColors.onPrimary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule() => Container(
        height: 1,
        color: AppColors.onPrimary.withValues(alpha: 0.18),
      );
}

/// Botón de proveedor social — Journey L117–L122.
class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsGlassButton(
      height: ds.h(48),
      onTap: onTap,
      semanticLabel: 'Entrar con $label',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ds.w(18),
            height: ds.w(18),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(ds.r(5)),
            ),
          ),
          SizedBox(width: ds.w(9)),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(
                fontSize: ds.sp(13),
                weight: FontWeight.w600,
                color: AppColors.onPrimary,
              ).copyWith(height: 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
