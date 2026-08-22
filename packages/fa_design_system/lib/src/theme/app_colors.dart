import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand seed
  static const Color brandSeed = Color(0xFF0D47A1);

  // Primary — Deep Blue financiero
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryContainer = Color(0xFFD6E4FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF001A42);

  // Secondary — Teal de confirmación
  static const Color secondary = Color(0xFF00695C);
  static const Color secondaryContainer = Color(0xFFB2DFDB);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Tertiary — Amber de alerta/acento
  static const Color tertiary = Color(0xFFFF8F00);
  static const Color tertiaryContainer = Color(0xFFFFECB3);

  // Error
  static const Color error = Color(0xFFB00020);
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Neutrals
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEBF0F7);
  static const Color outline = Color(0xFFBDBDBD);
  static const Color outlineVariant = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEDEFF3);

  // Acento del logo / progreso (Kredius)
  static const Color accentGreen = Color(0xFF00B894);

  // ── Grises y acentos intermedios del prototipo ────────────────────────────
  // Valores literales de `Kredius Journey.dc.html` que no tenían token. Están
  // aquí para que ninguna pantalla necesite volver a escribir un hex.

  /// Carril del segmented control del alta — L172.
  static const Color trackSurface = Color(0xFFE3E9F2);

  /// Texto secundario dentro de tarjetas (más claro que `onSurfaceVariant`)
  /// — L337, L676, L1063.
  static const Color mutedText = Color(0xFF7A8296);

  /// Borde de un input **con valor** — L1103. Es la señal de "esto ya se llenó".
  static const Color filledBorder = Color(0xFFC9D4E5);

  /// Fondo del tick sin marcar — L1157.
  static const Color tickEmpty = Color(0xFFF0F1F4);

  /// Relleno de un input que va **dentro de una tarjeta blanca** — L1163.
  /// Sobre papel gris los campos van blancos; sobre blanco necesitan este gris
  /// frío para no desaparecer.
  static const Color fieldFillOnCard = Color(0xFFF6F8FC);

  /// Texto del chip ámbar "PASA A COMITÉ" — L1189.
  static const Color onTertiaryContainer = Color(0xFF8A5300);

  /// Punto e icono de los avisos ámbar del journey de colocación
  /// (`Kredius Journey App.dc.html` L1021, L1334; `--amber` del KYC web).
  static const Color amberInk = Color(0xFFB26A00);

  /// Texto sobre `tertiaryContainer` en esos mismos avisos — L1022, L1335.
  /// Es más oscuro que [onTertiaryContainer], que es de chip y no de párrafo.
  static const Color onAmberContainer = Color(0xFF7A4E00);

  /// Texto sobre `secondaryContainer` en el aviso de OCR del beneficiario
  /// — L1114.
  static const Color onSecondaryContainer = Color(0xFF004D40);

  /// Icono/etiqueta de tab inactivo en el bottom nav — L920.
  static const Color navInactive = Color(0xFF9AA2B1);

  /// Separador superior del bottom nav — L791.
  static const Color navBorder = Color(0xFFDDE3EC);

  /// Dot inactivo del carrusel — L1192.
  static const Color dotInactive = Color(0xFFC9D0DC);

  /// Verde claro sobre el héroe azul (chips "SÍ CUMPLES", "AUTORIZADO") — L288.
  static const Color onPrimaryAccent = Color(0xFF7FE8CE);

  /// Ámbar claro sobre el héroe azul (badge de contraoferta) — L811.
  static const Color onPrimaryWarning = Color(0xFFFFD08A);

  // Text
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color disabled = Color(0xFF9E9E9E);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFE65100);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color info = Color(0xFF01579B);
  static const Color infoContainer = Color(0xFFE1F5FE);

  // KYC Steps
  static const Color stepActive = primary;
  static const Color stepCompleted = secondary;
  static const Color stepPending = outlineVariant;
}
