import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fa_core/fa_core.dart';
import 'package:fa_design_system/fa_design_system.dart';

import '../../domain/entities/credit_product.dart';
import '../../domain/entities/prequalified_product.dart';
import '../../domain/services/amortization_calculator.dart';
import '../providers/credit_application_provider.dart';

/// Oportunidades — lo que salió del análisis (Journey L427–L480).
///
/// Las ofertas se agrupan por lo que el scoring decidió sobre cada producto:
///
/// - **Aprobadas para ti** — `AUTO_APPROVED`. Se pueden tomar hoy.
/// - **Puedes solicitarlas** — el resto: pasan a comité o necesitan más
///   información. Se muestran igual, pero sin prometer un sí.
///
/// La distinción importa: mezclarlas haría que el usuario descubriera hasta el
/// final que "su" crédito en realidad estaba sujeto a revisión.
class ProductSelectionScreen extends StatefulWidget {
  const ProductSelectionScreen({super.key});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  /// Ancho de la tarjeta en el diseño (Journey L1186).
  static const double _cardWidth = 262;
  static const double _cardGap = 12;

  CreditProduct? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<CreditApplicationProvider>();
      p.reset();
      p.loadProducts();
      // El catálogo precalificado trae la decisión de scoring por producto —
      // es lo que permite separar "aprobadas" de "sujetas a revisión".
      p.loadPrequalifiedProducts();
    });
  }

  void _continue(CreditProduct product) {
    context.read<CreditApplicationProvider>().selectProduct(product);
    // Los revolventes no piden monto: se salta el configurador (regla del
    // handoff, IMPLEMENTACION_UI.md §4).
    context.go(product.requiresAmount
        ? '/credit/apply/details'
        : '/credit/apply/consent');
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditApplicationProvider>();

    // Con precalificación se agrupa por decisión; sin ella (un BFF que aún no
    // la expone) se muestra el catálogo plano, sin prometer aprobación.
    final approved = provider.approvedProducts;
    final onReview = provider.onReviewProducts;
    // Sin precalificación (un BFF que aún no la expone) se muestra el catálogo
    // del propósito, sin prometer aprobación.
    final purpose = AppSession.instance.purpose;
    final plain = provider.prequalifiedProducts.isEmpty
        ? provider.products
            .where((p) => purpose.matches(p.targetAudience))
            .toList()
        : const <CreditProduct>[];

    final hasAny =
        approved.isNotEmpty || onReview.isNotEmpty || plain.isNotEmpty;
    _selected ??= approved.isNotEmpty
        ? approved.first.product
        : (onReview.isNotEmpty
            ? onReview.first.product
            : (plain.isNotEmpty ? plain.first : null));

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.error != null
                  ? _ErrorState(
                      message: provider.error!,
                      onRetry: provider.loadProducts,
                    )
                  : !hasAny
                      ? _EmptyState(onBack: () => context.go('/home'))
                      : _buildContent(ds, approved, onReview, plain),
        ),
      ),
    );
  }

  Widget _buildContent(
    DsScale ds,
    List<PrequalifiedProduct> approved,
    List<PrequalifiedProduct> onReview,
    List<CreditProduct> plain,
  ) {
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding:
              EdgeInsets.fromLTRB(ds.gutterWide, ds.topGap, ds.gutterWide, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _BackButton(onTap: () => context.go('/home')),
                  SizedBox(width: ds.w(14)),
                  Expanded(
                    child: Text('Tus oportunidades',
                        style: AppTextStyles.cardTitle(fontSize: ds.sp(15))
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: ds.h(16)),
              Text(
                approved.isNotEmpty
                    ? 'Esto es lo que abrió tu análisis. Toma la que te cuadre — '
                        'defines monto y plazo en el siguiente paso.'
                    : 'Estas líneas puedes solicitarlas. La decisión final la da '
                        'el comité después de revisarlas.',
                style: AppTextStyles.body(fontSize: ds.sp(13.5)),
              ),
            ],
          ),
        ),
        SizedBox(height: ds.h(18)),

        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: ds.h(16)),
            children: [
              if (approved.isNotEmpty)
                _Section(
                  title: 'APROBADAS PARA TI',
                  note: 'Ya pasaron la revisión. Las puedes tomar hoy.',
                  children: [
                    for (final p in approved)
                      _card(p.product,
                          approved: true, selected: p.product == selected),
                  ],
                ),
              if (onReview.isNotEmpty)
                _Section(
                  title: 'PUEDES SOLICITARLAS',
                  note:
                      'Pasan a comité o necesitan más información antes de una '
                      'respuesta.',
                  children: [
                    for (final p in onReview)
                      _card(p.product,
                          approved: false,
                          selected: p.product == selected,
                          needsInfo: p.skippedReason != null),
                  ],
                ),
              if (plain.isNotEmpty)
                _Section(
                  title: 'CATÁLOGO',
                  note: 'Tu evaluación define el monto final de cada una.',
                  children: [
                    for (final p in plain)
                      _card(p, approved: false, selected: p == selected),
                  ],
                ),
              if (selected != null) ...[
                SizedBox(height: ds.h(4)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: ds.gutterWide),
                  child: _HowItWorksCard(product: selected),
                ),
              ],
            ],
          ),
        ),

        if (selected != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
                ds.gutterWide, ds.h(12), ds.gutterWide, ds.bottomGap(24)),
            child: DsButton(
              label: 'Continuar con ${selected.name.toLowerCase()}',
              onPressed: () => _continue(selected),
            ),
          ),
      ],
    );
  }

  /// Tarjeta del carrusel. La que está sujeta a revisión lleva el badge ámbar
  /// del prototipo (Journey L1189) para que no se confunda con una aprobada.
  Widget _card(
    CreditProduct product, {
    required bool approved,
    required bool selected,
    bool needsInfo = false,
  }) {
    final ds = context.ds;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final estimate = (product.maxAmount != null &&
            product.maxTerm != null &&
            product.nominalRate != null)
        ? AmortizationCalculator.estimate(
            amount: product.maxAmount!,
            termInMonths: product.maxTerm!,
            nominalRateAnnual: product.nominalRate!,
            paymentFrequency: product.defaultPaymentFrequency ?? 'MONTHLY',
          )
        : null;

    return Container(
      width: ds.w(_cardWidth),
      margin: EdgeInsets.only(right: ds.w(_cardGap)),
      decoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(ds.r(AppRadii.cardLarge)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : null,
      child: DsProductCarouselCard(
        icon: product.isRevolving
            ? Icons.credit_card_rounded
            : Icons.payments_rounded,
        segmentLabel: product.targetAudience ?? 'B2C',
        name: product.name,
        description: product.description ??
            (product.isRevolving
                ? 'Línea revolvente disponible'
                : 'Préstamo a plazo fijo'),
        amountCaption: approved ? 'LÍNEA AUTORIZADA' : 'HASTA',
        amountValue:
            product.maxAmount != null ? fmt.format(product.maxAmount) : '—',
        footnote: product.isRevolving
            ? 'Solo pagas lo que dispones'
            : estimate != null
                ? 'Desde ${fmt.format(estimate.periodicPayment)} al ${estimate.periodLabel}'
                : 'Sujeto a tu evaluación final',
        statusLabel: approved
            ? 'APROBADA'
            : (needsInfo ? 'MÁS INFORMACIÓN' : 'PASA A COMITÉ'),
        statusColor:
            approved ? AppColors.secondary : AppColors.onTertiaryContainer,
        onTap: () => setState(() => _selected = product),
      ),
    );
  }
}

/// Sección con encabezado y carrusel horizontal.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.note,
    required this.children,
  });

  final String title, note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: ds.gutterWide),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
              SizedBox(height: ds.h(6)),
              Text(note,
                  style: AppTextStyles.body(
                    fontSize: ds.sp(12),
                    color: AppColors.disabled,
                  ).copyWith(height: 1.4)),
            ],
          ),
        ),
        SizedBox(height: ds.h(12)),
        SizedBox(
          height: ds.h(300),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: ds.gutterWide),
            children: children,
          ),
        ),
        SizedBox(height: ds.h(20)),
      ],
    );
  }
}

/// Ficha "CÓMO FUNCIONA {producto}" — Journey L355–L366, specs en L1193–L1197.
class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.product});
  final CreditProduct product;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final specs = <(String, String)>[
      ('Tipo', product.isRevolving ? 'Revolvente' : 'A plazo'),
      (
        'Plazos',
        product.minTerm != null && product.maxTerm != null
            ? '${product.minTerm}–${product.maxTerm}'
            : '—'
      ),
      ('Pago', _frequencyLabel(product.defaultPaymentFrequency)),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(18), vertical: ds.h(16)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(18)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('CÓMO FUNCIONA ${product.name.toUpperCase()}',
              style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
          SizedBox(height: ds.h(12)),
          Text(
            product.description ??
                (product.isRevolving
                    ? 'Una línea siempre lista: solo pagas por lo que dispones y '
                        'el monto se libera conforme abonas.'
                    : 'Recibes el monto completo en tu cuenta y lo pagas en '
                        'mensualidades fijas.'),
            style: AppTextStyles.body(fontSize: ds.sp(13)),
          ),
          SizedBox(height: ds.h(12)),
          // Grilla de 3 con separadores de 1px — Journey L358–L365.
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(ds.r(12)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < specs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 1),
                    Expanded(
                      child: Container(
                        color: AppColors.surface,
                        padding: EdgeInsets.symmetric(
                            horizontal: ds.w(13), vertical: ds.h(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(specs[i].$1,
                                style: AppTextStyles.body(
                                  fontSize: ds.sp(10.5),
                                  color: AppColors.disabled,
                                ).copyWith(height: 1.0)),
                            SizedBox(height: ds.h(8)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(specs[i].$2,
                                  maxLines: 1,
                                  style: AppTextStyles.cardTitle(
                                          fontSize: ds.sp(13.5))
                                      .copyWith(height: 1.0)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _frequencyLabel(String? freq) => switch (freq?.toUpperCase()) {
        'WEEKLY' => 'Semanal',
        'BIWEEKLY' => 'Quincenal',
        'MONTHLY' => 'Mensual',
        _ => 'Mensual',
      };
}

/// Botón de retroceso del prototipo — 38×38, blanco, radio 12 (Journey L926).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Semantics(
      button: true,
      label: 'Volver',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: ds.w(38),
          height: ds.w(38),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(ds.r(12)),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Icon(Icons.arrow_back_rounded,
              size: ds.sp(18), color: AppColors.onSurface),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ds.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: ds.sp(48), color: AppColors.error),
            SizedBox(height: ds.h(12)),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(fontSize: ds.sp(14))),
            SizedBox(height: ds.h(20)),
            DsButton(label: 'Reintentar', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(ds.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DsEmptyStateCard(
              icon: Icons.inbox_outlined,
              title: 'Todavía no hay ofertas para ti',
              message:
                  'Tu análisis no abrió líneas por ahora. Tu historial cambia mes '
                  'con mes: en cuanto se mueva, volvemos a revisarlo.',
            ),
            SizedBox(height: ds.h(20)),
            DsButton(
                label: 'Volver al inicio',
                variant: DsButtonVariant.outlined,
                onPressed: onBack),
          ],
        ),
      ),
    );
  }
}
