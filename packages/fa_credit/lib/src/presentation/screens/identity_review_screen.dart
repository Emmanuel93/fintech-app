import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../providers/credit_application_provider.dart';

/// La solicitud no se recibió porque la identidad sigue en verificación.
///
/// Antes esto era un snackbar de «no pudimos enviar tu solicitud, intenta de
/// nuevo»: invitaba a reintentar algo que no depende de la persona. Lo que
/// pasa es que un analista está revisando sus documentos, y eso se dice.
class IdentityReviewScreen extends StatelessWidget {
  const IdentityReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final hold = context.watch<CreditApplicationProvider>().identityHold;
    final finalNo = hold?.isFinal ?? false;

    final title = finalNo
        ? 'No pudimos verificar tu identidad'
        : 'Estamos verificando tu identidad';
    final message = finalNo
        ? 'Por ahora no podemos recibir tu solicitud. Si crees que es un error, '
            'escríbenos desde Ayuda.'
        : 'Un analista está revisando tus documentos. Cuando termine te '
            'avisamos y podrás enviar tu solicitud.';

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: DsResponsiveBody(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ds.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ds.h(48)),
                Container(
                  width: ds.w(52),
                  height: ds.w(52),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(ds.r(15)),
                  ),
                  child: Icon(
                    finalNo ? Icons.info_outline_rounded : Icons.hourglass_top_rounded,
                    size: ds.sp(26),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: ds.h(18)),
                Text(title, style: AppTextStyles.heroTitle(ds.sp(26))),
                SizedBox(height: ds.h(12)),
                Text(message, style: AppTextStyles.body(fontSize: ds.sp(14))),
                const Spacer(),
                DsButton(
                  label: 'Entendido',
                  onPressed: () => context.go('/home'),
                ),
                SizedBox(height: ds.h(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
