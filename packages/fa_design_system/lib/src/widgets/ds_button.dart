import 'package:flutter/material.dart';

enum DsButtonVariant { primary, secondary, outlined, ghost }

class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = DsButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  /// Alto del botón. El tema fija 52 (el CTA principal del prototipo); las
  /// acciones dentro de una tarjeta usan 44 (Journey L738).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: variant == DsButtonVariant.outlined || variant == DsButtonVariant.ghost
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onPrimary,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label);

    Widget button;
    switch (variant) {
      case DsButtonVariant.primary:
        button = ElevatedButton(onPressed: isLoading ? null : onPressed, child: child);
      case DsButtonVariant.secondary:
        button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
      case DsButtonVariant.outlined:
        button = OutlinedButton(onPressed: isLoading ? null : onPressed, child: child);
      case DsButtonVariant.ghost:
        button = TextButton(onPressed: isLoading ? null : onPressed, child: child);
    }

    // `minimumSize` del tema fija 52 de alto; para bajarlo hay que soltar
    // también ese mínimo, si no el SizedBox pelea contra el estilo.
    if (height != null) {
      button = Theme(
        data: theme.copyWith(
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: theme.elevatedButtonTheme.style
                ?.copyWith(minimumSize: WidgetStatePropertyAll(Size(0, height!))),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: theme.outlinedButtonTheme.style
                ?.copyWith(minimumSize: WidgetStatePropertyAll(Size(0, height!))),
          ),
        ),
        child: SizedBox(height: height, child: button),
      );
    }
    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
