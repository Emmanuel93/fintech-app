import 'package:fa_design_system/fa_design_system.dart';
import 'package:fa_wallet/fa_wallet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/credit_account.dart';
import '../providers/credit_provider.dart';

/// El expediente del crédito — saldo, fechas y las acciones que caben sobre él.
///
/// Sigue el lenguaje del `Kredius Journey App.dc.html`: papel gris, barra
/// superior con el botón en tile blanco (L1701–L1702), un bloque azul con el
/// número que importa y tarjetas blancas de radio 20 para el resto.
///
/// Antes era una pantalla **azul completa** con una hoja blanca redondeada
/// encima, medidas proporcionales a la altura (`h * 0.022`) y `theme.textTheme`.
/// Ése era el lenguaje anterior al rediseño: sobrevivía porque el journey
/// llegaba aquí por un CTA y nadie lo volvió a mirar de cerca.
class CreditDetailScreen extends StatefulWidget {
  const CreditDetailScreen({super.key});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CreditProvider>();
      if (p.credit == null && !p.isLoading) p.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final provider = context.watch<CreditProvider>();
    final credit = provider.credit;
    final fmt =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('d MMM yyyy', 'es_MX');

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: DsResponsiveBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(ds.gutter, ds.topGap, ds.gutter, 0),
                child: DsTopBar(
                  title: credit?.displayTitle ?? 'Mi crédito',
                  onBack: () => context.go('/home'),
                ),
              ),
              Expanded(
                child: provider.isLoading && credit == null
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : credit == null
                        ? _EmptyState(onRetry: () => provider.load())
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: provider.load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                  ds.gutter, ds.h(18), ds.gutter, ds.h(32)),
                              children: [
                                _BalanceCard(credit: credit, fmt: fmt),
                                SizedBox(height: ds.h(14)),
                                _StatementCard(credit: credit, fmt: fmt),
                                SizedBox(height: ds.h(14)),
                                _DatesCard(credit: credit, dateFmt: dateFmt),
                                SizedBox(height: ds.h(14)),
                                DsNoticeBanner(
                                  tone: credit.isOverdue
                                      ? DsNoticeTone.amber
                                      : DsNoticeTone.success,
                                  text: credit.isOverdue
                                      ? 'Tu pago venció el '
                                          '${dateFmt.format(credit.paymentDueDate)}. '
                                          'Ponte al corriente para dejar de generar '
                                          'moratorios.'
                                      : 'Paga ${fmt.format(credit.noInterestPayment)} '
                                          'antes del '
                                          '${dateFmt.format(credit.paymentDueDate)} '
                                          'y no generas intereses.',
                                ),
                                SizedBox(height: ds.h(20)),
                                if (credit.isRevolving) ...[
                                  DsButton(
                                    label: 'Disponer al wallet',
                                    icon: Icons.account_balance_wallet_outlined,
                                    onPressed: () => _showDisposeSheet(
                                        context, credit.availableCredit, fmt),
                                  ),
                                  SizedBox(height: ds.h(11)),
                                ],
                                DsButton(
                                  label: 'Realizar pago',
                                  variant: DsButtonVariant.outlined,
                                  icon: Icons.payments_outlined,
                                  onPressed: () => _showPaymentSheet(context,
                                      credit.minimumPayment, credit.noInterestPayment, fmt),
                                ),
                                SizedBox(height: ds.h(11)),
                                DsButton(
                                  label: 'Ver movimientos',
                                  variant: DsButtonVariant.ghost,
                                  icon: Icons.list_alt_rounded,
                                  onPressed: () => context.go('/home/movements'),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hojas ──────────────────────────────────────────────────────────────────

  void _showDisposeSheet(
      BuildContext context, double available, NumberFormat fmt) {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(context.ds.r(24)))),
      builder: (sheetCtx) {
        final ds = sheetCtx.ds;
        return Padding(
          padding: EdgeInsets.fromLTRB(ds.gutter, ds.h(20), ds.gutter,
              MediaQuery.of(sheetCtx).viewInsets.bottom + ds.h(30)),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetGrip(),
                SizedBox(height: ds.h(18)),
                Text('Disponer al wallet',
                    style: AppTextStyles.sectionTitle(fontSize: ds.sp(18))),
                SizedBox(height: ds.h(6)),
                Text('Disponible ${fmt.format(available)}',
                    style: AppTextStyles.body(fontSize: ds.sp(13))),
                SizedBox(height: ds.h(18)),
                DsFormField(
                  label: 'Monto a disponer',
                  controller: ctrl,
                  hint: '\$0',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', ''));
                    if (n == null || n <= 0) return 'Ingresa un monto válido';
                    if (n > available) return 'Excede el crédito disponible';
                    return null;
                  },
                ),
                SizedBox(height: ds.h(18)),
                DsButton(
                  label: 'Confirmar disposición',
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final amount = double.parse(ctrl.text.replaceAll(',', ''));
                    Navigator.pop(sheetCtx);
                    final creditProv = context.read<CreditProvider>();
                    final walletProv = context.read<WalletProvider>();
                    final ok = await creditProv.disposeToWallet(amount: amount);
                    if (ok) walletProv.applyDisposition(amount: amount);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok
                          ? '${fmt.format(amount)} acreditados a tu wallet'
                          : 'No se pudo procesar la disposición'),
                      backgroundColor:
                          ok ? AppColors.secondary : AppColors.error,
                    ));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentSheet(BuildContext context, double minimum, double full,
      NumberFormat fmt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(context.ds.r(24)))),
      builder: (sheetCtx) {
        final ds = sheetCtx.ds;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              ds.gutter, ds.h(20), ds.gutter, ds.bottomGap(30)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetGrip(),
              SizedBox(height: ds.h(18)),
              Text('¿Cuánto deseas pagar?',
                  style: AppTextStyles.sectionTitle(fontSize: ds.sp(18))),
              SizedBox(height: ds.h(16)),
              _PayOption(
                label: 'Pago mínimo',
                sublabel: 'Evita mora y cargos extra',
                amount: fmt.format(minimum),
                tone: AppColors.amberInk,
                onTap: () => Navigator.pop(sheetCtx),
              ),
              SizedBox(height: ds.h(10)),
              _PayOption(
                label: 'Liquidar saldo',
                sublabel: 'Sin mora ni intereses adicionales',
                amount: fmt.format(full),
                tone: AppColors.secondary,
                recommended: true,
                onTap: () => Navigator.pop(sheetCtx),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bloques
// ─────────────────────────────────────────────────────────────────────────────

/// El número que importa, sobre azul — mismo tratamiento que la tarjeta del
/// home (Journey App L753–L774): saldo grande, chip de estado, barra de avance.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.credit, required this.fmt});

  final CreditAccount credit;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final progress = credit.paymentProgress;
    final term = credit.assignedTerm;
    final made = credit.paymentsMade;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: ds.w(-60),
            top: ds.h(-60),
            child: IgnorePointer(
              child: Container(
                width: ds.w(180),
                height: ds.w(180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGreen.withValues(alpha: 0.32),
                      AppColors.accentGreen.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(ds.w(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              credit.isRevolving
                                  ? 'Saldo dispuesto'
                                  : 'Saldo pendiente',
                              style: AppTextStyles.body(
                                fontSize: ds.sp(11.5),
                                weight: FontWeight.w500,
                                color: AppColors.onPrimary
                                    .withValues(alpha: 0.62),
                              ).copyWith(height: 1.0)),
                          SizedBox(height: ds.h(10)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(fmt.format(credit.pendingBalance),
                                maxLines: 1,
                                style: AppTextStyles.heroNumber(ds.sp(32),
                                    color: AppColors.onPrimary)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: ds.w(12)),
                    _HeroChip(credit: credit),
                  ],
                ),
                if (progress != null) ...[
                  SizedBox(height: ds.h(16)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: ds.h(7),
                      backgroundColor:
                          AppColors.onPrimary.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen),
                    ),
                  ),
                  SizedBox(height: ds.h(12)),
                  Text('PAGO ${(made ?? 0) + (credit.isPaidOff ? 0 : 1)} DE $term',
                      style: AppTextStyles.chipLabel(
                        fontSize: ds.sp(9.5),
                        color: AppColors.onPrimary.withValues(alpha: 0.55),
                      )),
                ] else if (credit.isRevolving) ...[
                  SizedBox(height: ds.h(16)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                    child: LinearProgressIndicator(
                      value: credit.usedPercentage,
                      minHeight: ds.h(7),
                      backgroundColor:
                          AppColors.onPrimary.withValues(alpha: 0.18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.accentGreen),
                    ),
                  ),
                  SizedBox(height: ds.h(12)),
                  Text('DISPONIBLE ${fmt.format(credit.availableCredit)}',
                      style: AppTextStyles.chipLabel(
                        fontSize: ds.sp(9.5),
                        color: AppColors.onPrimary.withValues(alpha: 0.55),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip translúcido sobre el azul. La mora no se suaviza: se nombra.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.credit});

  final CreditAccount credit;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final label = credit.isPaidOff
        ? 'LIQUIDADO'
        : credit.isOverdue
            ? 'EN MORA${credit.daysPastDue != null ? ' · ${credit.daysPastDue} D' : ''}'
            : 'AL CORRIENTE';

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: ds.w(9), vertical: ds.h(5)),
      decoration: BoxDecoration(
        color: credit.isOverdue
            ? AppColors.error.withValues(alpha: 0.9)
            : AppColors.onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(label,
          style: AppTextStyles.chipLabel(
                  fontSize: ds.sp(9), color: AppColors.onPrimary)
              .copyWith(height: 1.4)),
    );
  }
}

/// Estado de cuenta — tres renglones sobre blanco.
class _StatementCard extends StatelessWidget {
  const _StatementCard({required this.credit, required this.fmt});

  final CreditAccount credit;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'ESTADO DE CUENTA',
      children: [
        _Row(
          label: 'Saldo pendiente',
          value: fmt.format(credit.pendingBalance),
        ),
        _Row(
          label: 'Pago mínimo',
          value: fmt.format(credit.minimumPayment),
          tone: AppColors.amberInk,
          note: 'Evita mora',
        ),
        _Row(
          label: 'Liquidar saldo',
          value: fmt.format(credit.noInterestPayment),
          tone: AppColors.secondary,
          note: 'Recomendado',
          last: true,
        ),
      ],
    );
  }
}

/// Fechas clave.
class _DatesCard extends StatelessWidget {
  const _DatesCard({required this.credit, required this.dateFmt});

  final CreditAccount credit;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'FECHAS CLAVE',
      children: [
        _Row(
          label: 'Fecha de corte',
          value: dateFmt.format(credit.cutoffDate),
        ),
        _Row(
          label: 'Límite de pago',
          value: dateFmt.format(credit.paymentDueDate),
          tone: credit.isOverdue
              ? AppColors.error
              : credit.isPaymentDueSoon
                  ? AppColors.amberInk
                  : null,
          last: true,
        ),
      ],
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
      padding: EdgeInsets.fromLTRB(ds.w(18), ds.h(16), ds.w(18), ds.h(4)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.card)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTextStyles.captionLabel(fontSize: ds.sp(10))),
          SizedBox(height: ds.h(6)),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.tone,
    this.note,
    this.last = false,
  });

  final String label, value;
  final Color? tone;
  final String? note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: ds.h(13)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.body(fontSize: ds.sp(13.5))
                        .copyWith(height: 1.3)),
              ),
              if (note != null) ...[
                SizedBox(width: ds.w(8)),
                Text(note!,
                    style: AppTextStyles.chipLabel(
                        fontSize: ds.sp(9),
                        color: tone ?? AppColors.disabled)),
                SizedBox(width: ds.w(10)),
              ],
              Text(value,
                  style: AppTextStyles.cardTitle(
                    fontSize: ds.sp(14),
                    color: tone ?? AppColors.onSurface,
                  ).copyWith(height: 1.0)),
            ],
          ),
        ),
        if (!last)
          Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.tone,
    required this.onTap,
    this.recommended = false,
  });

  final String label, sublabel, amount;
  final Color tone;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
        child: Container(
          padding: EdgeInsets.all(ds.w(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall)),
            border: Border.all(
                color: recommended ? AppColors.secondary : AppColors.outlineVariant,
                width: recommended ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label,
                            style: AppTextStyles.cardTitle(fontSize: ds.sp(14.5))),
                        if (recommended) ...[
                          SizedBox(width: ds.w(8)),
                          const DsStatusChip(label: 'RECOMENDADO'),
                        ],
                      ],
                    ),
                    SizedBox(height: ds.h(5)),
                    Text(sublabel,
                        style: AppTextStyles.body(fontSize: ds.sp(11.5))
                            .copyWith(height: 1.35)),
                  ],
                ),
              ),
              SizedBox(width: ds.w(10)),
              Text(amount,
                  style: AppTextStyles.heroNumber(ds.sp(17), color: tone)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetGrip extends StatelessWidget {
  const _SheetGrip();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Container(
        width: ds.w(40),
        height: ds.h(4),
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      padding: EdgeInsets.all(ds.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DsEmptyStateCard(
            icon: Icons.credit_card_off_outlined,
            title: 'No pudimos cargar tu crédito',
            message: 'Revisa tu conexión e inténtalo de nuevo.',
          ),
          SizedBox(height: ds.h(16)),
          DsButton(label: 'Reintentar', onPressed: onRetry),
        ],
      ),
    );
  }
}
