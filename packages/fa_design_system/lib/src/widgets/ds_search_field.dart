import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/ds_scale.dart';

/// Buscador de una lista — Journey App L884–L890.
///
/// Lupa, campo sin borde propio y un "Limpiar" que sólo existe cuando hay algo
/// que limpiar. La `x` permanente de los buscadores de Material aquí sobra: la
/// lista es corta y el gesto de borrar es raro.
class DsSearchField extends StatelessWidget {
  const DsSearchField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.controller,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final ds = DsScale.of(context);
    final hasQuery = value.isNotEmpty;

    return Container(
      height: ds.h(46),
      padding: EdgeInsets.symmetric(horizontal: ds.w(14)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(ds.r(13)),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: ds.sp(16), color: AppColors.disabled),
          SizedBox(width: ds.w(9)),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyles.inputText(fontSize: ds.sp(13.5)),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: AppTextStyles.inputText(
                    fontSize: ds.sp(13.5), color: AppColors.disabled),
              ),
            ),
          ),
          if (hasQuery)
            GestureDetector(
              onTap: () {
                controller?.clear();
                onChanged('');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(left: ds.w(8)),
                child: Text('Limpiar',
                    style: AppTextStyles.body(
                      fontSize: ds.sp(12),
                      weight: FontWeight.w600,
                      color: AppColors.primary,
                    ).copyWith(height: 1.0)),
              ),
            ),
        ],
      ),
    );
  }
}
