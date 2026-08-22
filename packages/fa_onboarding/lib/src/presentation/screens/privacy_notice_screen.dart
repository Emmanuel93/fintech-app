import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:fa_design_system/fa_design_system.dart';

class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Aviso de Privacidad'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: w * 0.064, vertical: h * 0.015),
            color: AppColors.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.primary, size: h * 0.025),
                const Gap(8),
                Expanded(
                  child: Text(
                    'AVISO_PRIVACIDAD_KREDIUS.pdf',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: w * 0.064, vertical: h * 0.025),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'AVISO DE PRIVACIDAD INTEGRAL',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(h * 0.005),
                  Center(
                    child: Text(
                      'Kredius, S.A. de C.V., SOFOM, E.N.R.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Gap(h * 0.025),
                  _Section(
                    title: '1. IDENTIDAD Y DOMICILIO DEL RESPONSABLE',
                    body:
                        'Kredius, S.A. de C.V., Sociedad Financiera de Objeto Múltiple, Entidad No Regulada (SOFOM, E.N.R.), con domicilio en Av. Insurgentes Sur 1602, Piso 9, Col. Crédito Constructor, Alcaldía Benito Juárez, C.P. 03940, Ciudad de México, es responsable del tratamiento de sus datos personales.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '2. DATOS PERSONALES QUE SE RECABAN',
                    body:
                        'Para llevar a cabo las finalidades descritas en el presente aviso de privacidad, utilizaremos los siguientes datos personales:\n\n'
                        '• Datos de identificación: nombre completo, CURP, RFC, fecha de nacimiento, género, estado de nacimiento.\n'
                        '• Datos de contacto: número de teléfono celular, correo electrónico.\n'
                        '• Datos financieros y patrimoniales: comprobantes de ingresos, estados de cuenta, historial crediticio.\n'
                        '• Datos biométricos: fotografía del documento de identidad oficial (INE/IFE).\n'
                        '• Datos de domicilio: comprobante de domicilio, dirección completa.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '3. FINALIDADES DEL TRATAMIENTO',
                    body:
                        'Sus datos personales serán utilizados para las siguientes finalidades primarias:\n\n'
                        '• Evaluación, análisis y otorgamiento de crédito.\n'
                        '• Verificación de identidad mediante procesos KYC (Know Your Customer).\n'
                        '• Consulta de historial crediticio ante Sociedades de Información Crediticia (Buró de Crédito, Círculo de Crédito).\n'
                        '• Cumplimiento de obligaciones legales en materia de prevención de lavado de dinero (PLD).\n'
                        '• Administración y seguimiento del contrato de crédito.\n\n'
                        'Finalidades secundarias:\n\n'
                        '• Envío de comunicaciones comerciales y promocionales.\n'
                        '• Encuestas de satisfacción y mejora del servicio.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '4. CONSULTA EN SOCIEDADES DE INFORMACIÓN CREDITICIA',
                    body:
                        'De manera expresa y por escrito, usted autoriza a Kredius, S.A. de C.V., SOFOM, E.N.R., a llevar a cabo investigaciones sobre su comportamiento crediticio en las Sociedades de Información Crediticia que estime conveniente. Esta autorización tiene una vigencia de tres años contados a partir de la fecha de su firma, y en su caso por todo el tiempo que se mantenga la relación jurídica.\n\n'
                        'Conforme a lo establecido en los artículos 13 y 28 de la Ley para Regular las Sociedades de Información Crediticia.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '5. TRANSFERENCIA DE DATOS PERSONALES',
                    body:
                        'Sus datos personales podrán ser transferidos y tratados por terceros dentro y fuera del país, en los siguientes casos:\n\n'
                        '• Autoridades competentes que lo requieran conforme a la Ley.\n'
                        '• Sociedades de Información Crediticia para consulta y reporte de historial.\n'
                        '• Socios comerciales y proveedores de servicios necesarios para el otorgamiento del crédito.\n\n'
                        'En estos supuestos no se requerirá su consentimiento, conforme al artículo 37 de la LFPDPPP.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '6. DERECHOS ARCO',
                    body:
                        'Usted tiene derecho a Acceder, Rectificar, Cancelar u Oponerse (derechos ARCO) al tratamiento de sus datos personales. Para ejercer estos derechos puede enviar una solicitud a:\n\n'
                        'Correo electrónico: privacidad@kredius.com.mx\n'
                        'Teléfono: 800 CREDIT (273348)\n\n'
                        'Su solicitud deberá contener nombre completo, descripción clara del derecho que desea ejercer, y copia de identificación oficial.',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '7. MODIFICACIONES AL AVISO DE PRIVACIDAD',
                    body:
                        'Nos reservamos el derecho de efectuar en cualquier momento modificaciones o actualizaciones al presente aviso de privacidad, las cuales serán publicadas en nuestra página de internet: www.kredius.com.mx',
                  ),
                  Gap(h * 0.018),
                  _Section(
                    title: '8. AUTORIDAD COMPETENTE',
                    body:
                        'Si usted considera que su derecho a la protección de datos personales ha sido lesionado, puede acudir ante el Instituto Nacional de Transparencia, Acceso a la Información y Protección de Datos Personales (INAI): www.inai.org.mx.',
                  ),
                  Gap(h * 0.025),
                  Container(
                    padding: EdgeInsets.all(h * 0.018),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      'Última actualización: enero 2025\n'
                      'Este aviso de privacidad fue elaborado en cumplimiento de la Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP) y su Reglamento.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Gap(h * 0.04),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.064, 0, w * 0.064, h * 0.03),
            child: DsButton(
              label: 'Entendido',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const Gap(6),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.6,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
