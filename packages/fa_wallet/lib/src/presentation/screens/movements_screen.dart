import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fa_design_system/fa_design_system.dart';
import '../providers/wallet_provider.dart';
import '../../domain/entities/transaction.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key, this.embedded = false});

  /// `true` cuando se usa como cuerpo del tab "Movimientos" del home — omite
  /// su propio Scaffold/AppBar, el home ya pone los suyos. `false` (default)
  /// preserva el comportamiento existente al navegar a `/wallet/movements`
  /// como pantalla completa.
  final bool embedded;

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  int _selectedFilter = 0;
  static const _filters = ['Todos', 'Disposiciones', 'Pagos', 'Transferencias'];

  bool _matchesFilter(Transaction tx) => switch (_selectedFilter) {
        1 => tx.category == TransactionCategory.disposicion,
        2 => tx.category == TransactionCategory.payment,
        3 => tx.category == TransactionCategory.transferIn ||
            tx.category == TransactionCategory.transferOut ||
            tx.category == TransactionCategory.deposit ||
            tx.category == TransactionCategory.withdrawal,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
            final ds = context.ds;
    final provider = context.watch<WalletProvider>();

    final filtered = provider.transactions.where(_matchesFilter).toList();

    final Map<String, List<Transaction>> grouped = {};
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', 'es_MX');
    for (final tx in filtered) {
      grouped.putIfAbsent(dateFmt.format(tx.date), () => []).add(tx);
    }

    final body = Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: EdgeInsets.symmetric(vertical: ds.h(10)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: ds.gutterWide),
            child: Row(
              children: _filters.asMap().entries.map((e) {
                final selected = _selectedFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedFilter = e.key),
                    selectedColor: AppColors.primaryContainer,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.body(fontSize: ds.sp(12)).copyWith(
                      color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant),
                    backgroundColor: AppColors.surface,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const Divider(height: 1),
        Container(
          color: AppColors.surface,
          padding: EdgeInsets.symmetric(horizontal: ds.gutterWide, vertical: ds.h(10)),
          child: Row(
            children: [
              _SummaryBadge(
                label: 'Entradas',
                amount: filtered.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
                color: AppColors.secondary,
              ),
              SizedBox(width: ds.w(16)),
              _SummaryBadge(
                label: 'Salidas',
                amount: filtered.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.refresh,
                  child: ListView.builder(
                    padding: EdgeInsets.only(bottom: ds.h(34), top: ds.h(9)),
                    itemCount: grouped.length,
                    itemBuilder: (_, i) {
                      final date = grouped.keys.elementAt(i);
                      final txs = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(ds.gutterWide, ds.h(16), ds.gutterWide, ds.h(7)),
                            child: Text(
                              date[0].toUpperCase() + date.substring(1),
                              style: AppTextStyles.captionLabel(fontSize: ds.sp(10)),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: ds.gutterWide),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.outlineVariant),
                            ),
                            child: Column(
                              children: txs.asMap().entries.map((e) => Column(
                                children: [
                                  _movementTileFor(e.value),
                                  if (e.key < txs.length - 1)
                                    const Divider(height: 1, indent: 64, endIndent: 16),
                                ],
                              )).toList(),
                            ),
                          ),
                          SizedBox(height: ds.h(9)),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  ds.gutterWide, ds.topGap, ds.gutterWide, ds.h(10)),
              child: DsTopBar(
                title: 'Movimientos',
                onBack: () => context.go('/home'),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

const _categoryVisual = {
  TransactionCategory.disposicion: (Icons.credit_card_rounded, AppColors.primary),
  TransactionCategory.transferOut: (Icons.arrow_upward_rounded, AppColors.error),
  TransactionCategory.transferIn: (Icons.arrow_downward_rounded, AppColors.success),
  TransactionCategory.payment: (Icons.receipt_long_outlined, AppColors.warning),
  TransactionCategory.deposit: (Icons.account_balance_wallet_outlined, AppColors.success),
  TransactionCategory.withdrawal: (Icons.atm_rounded, AppColors.error),
  TransactionCategory.interest: (Icons.percent_rounded, AppColors.error),
  TransactionCategory.other: (Icons.swap_horiz_rounded, AppColors.onSurfaceVariant),
};

const _statusVisual = {
  TransactionStatus.completed: ('Completado', AppColors.success),
  TransactionStatus.pending: ('Pendiente', AppColors.tertiary),
  TransactionStatus.failed: ('Fallido', AppColors.error),
};

/// Resuelve el mapeo específico de dominio (categoría/estado de `Transaction`)
/// a los primitivos que `DsMovementTile` (fa_design_system) sabe renderizar —
/// el widget compartido no conoce estos enums, solo íconos/colores/texto.
Widget _movementTileFor(Transaction tx) {
  final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
  final timeFmt = DateFormat('HH:mm', 'es_MX');
  final (icon, iconColor) =
      _categoryVisual[tx.category] ?? (Icons.swap_horiz_rounded, AppColors.onSurfaceVariant);
  final (statusLabel, statusColor) = _statusVisual[tx.status]!;

  return DsMovementTile(
    icon: icon,
    iconColor: iconColor,
    description: tx.description,
    timeLabel: timeFmt.format(tx.date),
    reference: tx.reference,
    amountLabel: '${tx.isIncome ? '+' : '-'}${fmt.format(tx.amount)}',
    isIncome: tx.isIncome,
    statusLabel: statusLabel,
    statusColor: statusColor,
  );
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
        Text(fmt.format(amount),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
