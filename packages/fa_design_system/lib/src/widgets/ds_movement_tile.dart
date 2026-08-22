import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../theme/app_colors.dart';

/// Fila de un movimiento de wallet. Deliberadamente solo recibe primitivos
/// (íconos, colores, texto ya formateado) — el mapeo de categoría/estado del
/// dominio vive en el módulo que sí conoce esos tipos (`fa_wallet`), no aquí.
class DsMovementTile extends StatelessWidget {
  const DsMovementTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.description,
    required this.timeLabel,
    this.reference,
    required this.amountLabel,
    required this.isIncome,
    required this.statusLabel,
    required this.statusColor,
  });

  final IconData icon;
  final Color iconColor;
  final String description;
  final String timeLabel;
  final String? reference;

  /// Ya formateado con signo, ej. "+ \$1,500.00".
  final String amountLabel;
  final bool isIncome;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.014),
      child: Row(
        children: [
          Container(
            width: h * 0.052,
            height: h * 0.052,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: h * 0.026),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Gap(h * 0.002),
                Row(
                  children: [
                    Text(timeLabel,
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
                    if (reference != null) ...[
                      const Gap(6),
                      Flexible(
                        child: Text('· $reference',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.disabled, fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isIncome ? AppColors.success : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Gap(h * 0.002),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
