import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Avatar de iniciales — círculo `primaryContainer` con las iniciales en azul
/// (Journey App L820, L896).
///
/// Las iniciales se derivan del nombre aquí y no en cada pantalla: dos listas
/// que calculan iniciales distinto para la misma persona es un defecto que sólo
/// se ve cuando ya está en producción.
class DsAvatar extends StatelessWidget {
  const DsAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  /// "María Luisa Cortés" → "MC"; "María" → "MA"; vacío → "—".
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      width: ds.w(size),
      height: ds.w(size),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Text(
        initialsOf(name),
        style: AppTextStyles.cardTitle(
          fontSize: ds.sp(size * 0.32),
          color: AppColors.primary,
        ).copyWith(height: 1.0),
      ),
    );
  }
}

/// Fila de persona dentro de una tarjeta-lista — Journey App L819–L832.
///
/// Avatar, nombre con chip de estado al lado, una línea de metadatos y, a la
/// derecha, el monto con su pie. El separador va **entre** filas, nunca después
/// de la última: una tarjeta que termina en línea se ve rota.
class DsPersonRow extends StatelessWidget {
  const DsPersonRow({
    super.key,
    required this.name,
    required this.meta,
    this.chip,
    this.trailingValue,
    this.trailingNote,
    this.trailingNoteGood = false,
    this.onTap,
    this.expanded,
    this.showDivider = true,
  });

  final String name, meta;

  /// Chip de estado a la derecha del nombre.
  final Widget? chip;

  /// Monto a la derecha y su pie (la comisión, en verde si [trailingNoteGood]).
  final String? trailingValue, trailingNote;
  final bool trailingNoteGood;

  final VoidCallback? onTap;

  /// Contenido que se despliega debajo al abrir la fila (ficha del
  /// beneficiario, L903–L925).
  final Widget? expanded;

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);

    final row = Padding(
      padding: EdgeInsets.symmetric(vertical: ds.h(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsAvatar(name: name),
              SizedBox(width: ds.w(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body(
                                fontSize: ds.sp(13.5),
                                weight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ).copyWith(height: 1.2)),
                        ),
                        if (chip != null) ...[
                          SizedBox(width: ds.w(8)),
                          chip!,
                        ],
                      ],
                    ),
                    SizedBox(height: ds.h(5)),
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body(
                          fontSize: ds.sp(11),
                          color: AppColors.disabled,
                        ).copyWith(height: 1.35)),
                  ],
                ),
              ),
              if (trailingValue != null) ...[
                SizedBox(width: ds.w(10)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trailingValue!,
                        style: AppTextStyles.cardTitle(fontSize: ds.sp(13.5))
                            .copyWith(height: 1.0)),
                    if (trailingNote != null) ...[
                      SizedBox(height: ds.h(6)),
                      Text(trailingNote!,
                          style: AppTextStyles.body(
                            fontSize: ds.sp(10.5),
                            weight: FontWeight.w600,
                            color: trailingNoteGood
                                ? AppColors.secondary
                                : AppColors.disabled,
                          ).copyWith(height: 1.0)),
                    ],
                  ],
                ),
              ],
            ],
          ),
          if (expanded != null) expanded!,
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onTap == null)
          row
        else
          InkWell(onTap: onTap, child: row),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: AppColors.divider),
      ],
    );
  }
}

/// Contenedor blanco de una lista de filas — el `padding:2px 16px` del diseño
/// (L817, L892). Existe para que ninguna pantalla vuelva a escribirlo.
class DsListCard extends StatelessWidget {
  const DsListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: ds.w(16), vertical: ds.h(2)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(AppRadii.cardSmall + 2)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}
