import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';

/// Fila expandible del historial de créditos. Los detalles (beneficiario +
/// SPEI + comisión para `DISTRIBUTOR_LINE`, tabla por disposición para
/// revolventes, etc.) son responsabilidad del caller — este widget solo
/// renderiza pares (label, value) genéricos, sin conocer el dominio de
/// crédito.
class DsCreditListTile extends StatelessWidget {
  const DsCreditListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    required this.amountLabel,
    required this.amountSubLabel,
    this.detailRows = const [],
    this.beneficiary,
    this.tableLabel,
    this.onViewContract,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String statusLabel;
  final Color statusColor;
  final String amountLabel;
  final String amountSubLabel;
  final List<(String, String)> detailRows;

  /// Bloque de "disposición a tercero" (solo `DISTRIBUTOR_LINE`) — null si no aplica.
  final DsBeneficiaryInfo? beneficiary;

  /// Etiqueta del segundo botón de acción, ej. "Tabla fija" / "Tabla por
  /// disposición" / "Tabla por colocación" — null oculta ambos botones.
  final String? tableLabel;
  final VoidCallback? onViewContract;

  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amountLabel,
                  style: theme.textTheme.titleSmall?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800)),
              Text(amountSubLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: AppColors.outlineVariant, height: 1),
                  const SizedBox(height: 12),
                  if (beneficiary != null) ...[
                    _BeneficiaryBlock(info: beneficiary!),
                    const SizedBox(height: 12),
                  ],
                  if (detailRows.isNotEmpty)
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.6,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                      children: [
                        for (final row in detailRows)
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(row.$1,
                                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 4),
                                Text(row.$2, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ],
                    )
                  else
                    Text('Sin detalle adicional.',
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  if (tableLabel != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.description_outlined,
                            label: 'Contrato',
                            onTap: onViewContract,
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: _ActionChip(
                            icon: Icons.table_rows_outlined,
                            label: tableLabel!,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos del beneficiario de una disposición a tercero (`DISTRIBUTOR_LINE`).
class DsBeneficiaryInfo {
  const DsBeneficiaryInfo({
    required this.initials,
    required this.name,
    required this.meta,
    required this.commissionLabel,
  });

  final String initials;
  final String name;
  final String meta;
  final String commissionLabel;
}

class _BeneficiaryBlock extends StatelessWidget {
  const _BeneficiaryBlock({required this.info});
  final DsBeneficiaryInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DISPOSICIÓN A TERCERO',
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, letterSpacing: 0.6)),
          const Gap(10),
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary,
                child: Text(info.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
              const Gap(11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(info.meta,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(info.commissionLabel,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                  Text('tu comisión',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const Gap(7),
              Flexible(
                child: Text(label,
                    style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
