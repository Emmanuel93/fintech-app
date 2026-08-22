/// Guard test — protege la "adecuación al design system" del journey Kredius.
///
/// Las pantallas de abajo fueron migradas de colores hex hardcodeados a los
/// tokens de `fa_design_system` (AppColors / AppTheme). Este test falla si
/// alguien reintroduce un literal de color fuera de la paleta en ellas, para
/// que el drift no regrese silenciosamente.
///
/// Regla: en estos archivos NO se permite `Color(0x…)` ni `Colors.<hue>`
/// (red/blue/green/amber/orange/teal/grey/purple/indigo/pink/cyan/lime).
/// Sí se permiten los neutros semánticos `Colors.white/black/transparent`
/// (equivalen a onPrimary/onSurface/transparent y no son "de paleta").
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Rutas relativas al cwd de `flutter test` (= packages/fa_shell).
  const files = <String>[
    '../fa_credit/lib/credit_module.dart',
    '../fa_credit/lib/src/presentation/screens/credit_detail_screen.dart',
    '../fa_credit/lib/src/presentation/screens/product_selection_screen.dart',
    '../fa_notifications/lib/src/presentation/screens/notifications_screen.dart',
    '../fa_wallet/lib/src/presentation/screens/movements_screen.dart',
    '../fa_wallet/lib/src/presentation/screens/send_money_screen.dart',
    '../fa_profile/lib/src/presentation/screens/profile_screen.dart',
    // Perfil reescrito al tab del diseño (expediente claro con sellos).
    '../fa_shell/lib/src/home/home_screen.dart',
    '../fa_auth/lib/src/presentation/screens/splash_screen.dart',
    '../fa_auth/lib/src/presentation/screens/login_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/privacy_notice_screen.dart',
    // Rediseño Kredius — logo + welcome + alta 100% con tokens.
    '../fa_onboarding/lib/src/presentation/screens/welcome_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/privacy_consent_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/phone_entry_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/otp_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/password_creation_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/kyc_success_screen.dart',
    '../fa_design_system/lib/src/brand/kredius_mark.dart',
    '../fa_design_system/lib/src/brand/kredius_wordmark.dart',
    '../fa_design_system/lib/src/brand/kredius_brand.dart',
    // Integración E2E del diseño Kredius — pantallas nuevas o reescritas.
    '../fa_credit/lib/src/presentation/screens/application_status_screen.dart',
    '../fa_credit/lib/src/presentation/screens/offer_screen.dart',
    '../fa_credit/lib/src/presentation/screens/application_amount_screen.dart',
    '../fa_credit/lib/src/presentation/screens/contract_sign_screen.dart',
    '../fa_credit/lib/src/presentation/screens/contract_otp_screen.dart',
    '../fa_credit/lib/src/presentation/screens/disbursement_success_screen.dart',
    '../fa_design_system/lib/src/motion/kredius_motion.dart',
    '../fa_design_system/lib/src/theme/ds_scale.dart',
    '../fa_design_system/lib/src/widgets/ds_hero_scaffold.dart',
    '../fa_design_system/lib/src/widgets/ds_document_tile.dart',
    '../fa_design_system/lib/src/widgets/ds_field_group.dart',
    '../fa_design_system/lib/src/widgets/ds_consent_check.dart',
    '../fa_design_system/lib/src/widgets/ds_segmented_tabs.dart',
    '../fa_design_system/lib/src/widgets/ds_status_chip.dart',
    '../fa_design_system/lib/src/widgets/ds_translucent_field.dart',
    '../fa_design_system/lib/src/widgets/ds_term_stepper.dart',
    '../fa_design_system/lib/src/widgets/ds_product_carousel_card.dart',
    '../fa_credit/lib/src/presentation/screens/counter_offer_screen.dart',
    '../fa_onboarding/lib/src/presentation/screens/identity_screen.dart',
    // Migración del home, notificaciones y rechazo al design system.
    '../fa_credit/lib/src/presentation/screens/rejected_screen.dart',
    '../fa_notifications/lib/src/presentation/screens/notifications_screen.dart',
    '../fa_design_system/lib/src/widgets/ds_home_cards.dart',
    '../fa_design_system/lib/src/widgets/ds_notification_tile.dart',
    '../fa_design_system/lib/src/widgets/ds_filter_chips.dart',
    '../fa_design_system/lib/src/widgets/ds_pin_pad.dart',
    // El análisis pasa a ser parte del alta.
    '../fa_onboarding/lib/src/presentation/screens/account_analysis_screen.dart',
    '../fa_design_system/lib/src/widgets/ds_analysis_view.dart',
    // Segmentación del alta, contrato en PDF y firma autógrafa.
    '../fa_onboarding/lib/src/presentation/screens/purpose_screen.dart',
    '../fa_credit/lib/src/presentation/screens/post_analysis_screen.dart',
    '../fa_credit/lib/src/presentation/screens/amortization_table_screen.dart',
    '../fa_credit/lib/src/presentation/screens/contract_review_screen.dart',
    '../fa_design_system/lib/src/widgets/ds_document_link.dart',
    '../fa_design_system/lib/src/widgets/ds_picker_field.dart',
    '../fa_design_system/lib/src/widgets/ds_signature_pad.dart',
    // Alineación al Journey App: la barra del diseño y las pantallas que
    // seguían en el lenguaje anterior (azul a pantalla completa, AppBar de
    // Material, medidas proporcionales).
    '../fa_design_system/lib/src/widgets/ds_top_bar.dart',
    // Barra de marca global del rediseño (logo en todas las pantallas).
    '../fa_design_system/lib/src/widgets/ds_brand_bar.dart',
    '../fa_shell/lib/src/brand/brand_bar_host.dart',
    '../fa_credit/lib/src/presentation/screens/credits_list_screen.dart',
    // Colocación B2B2C — pantallas y widgets de la 7ª pasada.
    '../fa_design_system/lib/src/widgets/ds_notice_banner.dart',
    '../fa_design_system/lib/src/widgets/ds_line_summary_card.dart',
    '../fa_design_system/lib/src/widgets/ds_person_row.dart',
    '../fa_design_system/lib/src/widgets/ds_timeline.dart',
    '../fa_design_system/lib/src/widgets/ds_score_card.dart',
    '../fa_design_system/lib/src/widgets/ds_search_field.dart',
    '../fa_placements/lib/placements_module.dart',
    '../fa_placements/lib/src/presentation/widgets/placement_top_bar.dart',
    '../fa_placements/lib/src/presentation/screens/beneficiary_entry_screen.dart',
    '../fa_placements/lib/src/presentation/screens/placement_amount_screen.dart',
    '../fa_placements/lib/src/presentation/screens/placement_sent_screen.dart',
    '../fa_placements/lib/src/presentation/screens/placement_bureau_screen.dart',
    '../fa_placements/lib/src/presentation/screens/placements_tab_screen.dart',
    '../fa_placements/lib/src/presentation/screens/beneficiaries_tab_screen.dart',
  ];

  final hexLiteral = RegExp(r'Color\(0x');
  final paletteHue = RegExp(
    r'Colors\.(red|blue|green|amber|orange|teal|grey|gray|purple|deepPurple|'
    r'indigo|pink|cyan|lime|brown|lightBlue|lightGreen|deepOrange|yellow)\b',
  );

  for (final rel in files) {
    test('$rel usa tokens del design system (sin colores hardcodeados)', () {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: 'No existe el archivo: $rel');
      final offenders = <String>[];
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (hexLiteral.hasMatch(line) || paletteHue.hasMatch(line)) {
          offenders.add('  L${i + 1}: ${line.trim()}');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Color fuera de la paleta en $rel — usa AppColors.*:\n'
            '${offenders.join('\n')}',
      );
    });
  }
}
