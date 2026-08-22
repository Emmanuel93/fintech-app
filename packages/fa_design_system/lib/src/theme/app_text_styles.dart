import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografía del journey Kredius.
///
/// Dos reglas que vienen del prototipo y que conviene no perder de vista:
///
/// 1. **Inter va embebida**, no descargada. Los TTF viven en
///    `assets/fonts/` de este paquete y se declaran en su `pubspec.yaml`.
///    Como el paquete no es la app, la familia se resuelve con el prefijo
///    `packages/fa_design_system/` — usa siempre [fontFamily] para referirla.
/// 2. **El tracking es 0 en cuerpo y etiquetas.** El prototipo escribe Inter sin
///    `letter-spacing` salvo en dos casos deliberados: los titulares/números
///    grandes (tracking negativo) y las etiquetas en mayúsculas (positivo).
///    Los defaults de Material (`bodyMedium 0.25`, `bodyLarge 0.5`, …) ensanchan
///    el texto y son la razón de que la app se viera "parecida pero no igual".
abstract final class AppTextStyles {
  /// Familia resuelta con el prefijo de paquete. Úsala en `ThemeData.fontFamily`
  /// y en cualquier `TextStyle` fuera de esta clase.
  static const String fontFamily = 'packages/fa_design_system/Inter';

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = 0,
    double height = 1.0,
    Color color = AppColors.onSurface,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  // ── Titulares y números ────────────────────────────────────────────────────

  /// Números "hero" — 800 con tracking negativo proporcional al tamaño.
  /// Prototipo: `font:800 46px/1; letter-spacing:-2.4px` ≈ -0.052·tamaño
  /// (Journey L292, L414, L596).
  static TextStyle heroNumber(
    double fontSize, {
    Color color = AppColors.onSurface,
    FontWeight weight = FontWeight.w800,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: fontSize * -0.052,
        color: color,
      );

  /// Titular de marketing (welcome, login).
  /// Prototipo: `font:800 42px/1.05; letter-spacing:-2px` ≈ -0.048·tamaño
  /// (Journey L143, L84).
  static TextStyle heroTitle(double fontSize, {Color color = AppColors.onSurface}) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * -0.048,
        height: 1.05,
        color: color,
      );

  /// Título de pantalla — `font:700 27px/1.15; letter-spacing:-1.1px`
  /// (Journey L169, L239, L529). El tamaño es escalable para que responda a
  /// `DsScale.sp`.
  static TextStyle screenTitle({
    double fontSize = 27,
    Color color = AppColors.onSurface,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize * -0.041,
        height: 1.15,
        color: color,
      );

  /// Subtítulo de sección dentro de una pantalla — `font:700 19px/1.2`
  /// (Journey L301, L384).
  static TextStyle sectionTitle({
    double fontSize = 19,
    Color color = AppColors.onSurface,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: fontSize * -0.032,
        height: 1.2,
        color: color,
      );

  /// Título de tarjeta — `font:700 15px/1.2` (Journey L492, L615).
  static TextStyle cardTitle({
    double fontSize = 15,
    Color color = AppColors.onSurface,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color,
      );

  // ── Etiquetas ──────────────────────────────────────────────────────────────

  /// Etiqueta pequeña en mayúsculas ("CUÁNTO NECESITAS", "LÍNEA AUTORIZADA").
  /// Prototipo: `font:600 10px/1; letter-spacing:.12em` (Journey L183, L340).
  static TextStyle captionLabel({
    double fontSize = 10,
    Color color = AppColors.disabled,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: fontSize * 0.12,
        color: color,
      );

  /// Texto de chip de estado ("LISTO", "VERIFICADA", "RECOMENDADO").
  /// Prototipo: `font:600 9px/1; letter-spacing:.08em` (Journey L214, L493).
  static TextStyle chipLabel({
    double fontSize = 9,
    Color color = AppColors.secondary,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: fontSize * 0.08,
        color: color,
      );

  /// Etiqueta de campo de formulario — `font:500 11.5px/1` (Journey L188).
  static TextStyle fieldLabel({
    double fontSize = 11.5,
    Color color = AppColors.onSurfaceVariant,
  }) =>
      _inter(fontSize: fontSize, fontWeight: FontWeight.w500, color: color);

  /// Texto dentro de un input — `font:500 14.5px/1` (Journey L1103).
  static TextStyle inputText({
    double fontSize = 14.5,
    Color color = AppColors.onSurface,
  }) =>
      _inter(fontSize: fontSize, fontWeight: FontWeight.w500, color: color);

  /// Etiqueta del bottom nav — `font:600 10.5px/1` (Journey L794).
  static TextStyle navLabel({
    double fontSize = 10.5,
    Color color = AppColors.disabled,
  }) =>
      _inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);

  /// Texto del CTA principal — `font:600 16px/1` (Journey L919).
  static TextStyle button({
    double fontSize = 16,
    Color color = AppColors.onPrimary,
  }) =>
      _inter(fontSize: fontSize, fontWeight: FontWeight.w600, color: color);

  /// Cuerpo de texto del diseño — `font:400 14px/1.5`, tracking 0
  /// (Journey L170, L302, L385).
  static TextStyle body({
    double fontSize = 14,
    Color color = AppColors.onSurfaceVariant,
    FontWeight weight = FontWeight.w400,
  }) =>
      _inter(
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.5,
        color: color,
      );

  // ── TextTheme de Material ──────────────────────────────────────────────────

  /// Escala Material alineada al prototipo: Inter local y **tracking 0** en
  /// cuerpo/etiquetas (Material trae 0.25–0.5 y ensancha el texto), con las
  /// alturas de línea que usa el diseño.
  static TextTheme get textTheme => TextTheme(
        // Display
        displayLarge: _inter(
            fontSize: 57, fontWeight: FontWeight.w800, letterSpacing: -2.4, height: 1.05),
        displayMedium: _inter(
            fontSize: 45, fontWeight: FontWeight.w800, letterSpacing: -2.0, height: 1.05),
        displaySmall: _inter(
            fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.6, height: 1.1),
        // Headline
        headlineLarge: _inter(
            fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1.4, height: 1.15),
        headlineMedium: _inter(
            fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1.2, height: 1.15),
        // 27/1.15/-1.1 — el H2 exacto del prototipo, para que
        // `theme.textTheme.headlineSmall` ya no se desvíe del diseño.
        headlineSmall: _inter(
            fontSize: 27, fontWeight: FontWeight.w700, letterSpacing: -1.1, height: 1.15),
        // Title
        titleLarge: _inter(
            fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.7, height: 1.2),
        titleMedium: _inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.25),
        titleSmall: _inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.25),
        // Body
        bodyLarge: _inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: _inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: _inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            height: 1.45,
            color: AppColors.onSurfaceVariant),
        // Label
        labelLarge: _inter(fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: _inter(fontSize: 12.5, fontWeight: FontWeight.w500),
        labelSmall: _inter(
            fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
      );
}
