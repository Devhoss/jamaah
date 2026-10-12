import 'package:flutter/material.dart';

/// Design tokens ported from docs/prayer-prototype.html (CSS custom properties).
///
/// Light first, dark secondary. Colours are deliberately few: a warm off-white,
/// a deep forest green and a restrained sage.
abstract final class AppColors {
  // Light
  static const lightBg = Color(0xFFFAF7F0);
  static const lightSurface = Color(0xFFFFFDF8);
  static const lightInk = Color(0xFF1B2A22);
  static const lightMuted = Color(0xFF6B7A70);
  static const lightPrimary = Color(0xFF1F4D3A);
  static const lightSage = Color(0xFFDCE6DA);
  static const lightLine = Color(0xFFE8E3D6);
  static const lightWarnBg = Color(0xFFF3E3C8);
  static const lightWarnInk = Color(0xFF7A4B08);
  static const lightWarn = Color(0xFFB8741A);
  static const lightDestructive = Color(0xFFB3392B);

  // Dark
  static const darkBg = Color(0xFF0F1713);
  static const darkSurface = Color(0xFF17221B);
  static const darkInk = Color(0xFFE8EFE9);
  static const darkMuted = Color(0xFF93A398);
  static const darkPrimary = Color(0xFF3F8F69);
  static const darkSage = Color(0xFF223A2D);
  static const darkLine = Color(0xFF25332A);
  static const darkWarnBg = Color(0xFF3A2E17);
  static const darkWarnInk = Color(0xFFE0B472);
  static const darkWarn = Color(0xFFD89A45);
  static const darkDestructive = Color(0xFFE2705F);

  /// "You are here" marker colour (shared by both themes).
  static const you = Color(0xFF2F7AE5);
  static const onPrimary = Color(0xFFFFFFFF);
}

/// Shape scale from the prototype: 22 hero, 18 rows/cards, 14 buttons, 24 sheets,
/// 12 inputs, 99 pills.
abstract final class AppRadius {
  static const hero = 22.0;
  static const card = 18.0;
  static const button = 14.0;
  static const sheet = 24.0;
  static const input = 12.0;
  static const pill = 99.0;
}

/// Spacing scale (dp). Mostly 4/8/12/16/20/24, with 10px-ish inset steps from the
/// prototype (10, 14) kept because the prototype uses them for row insets.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  /// Minimum touch target on every axis (AGENTS.md).
  static const touchTarget = 48.0;
}

/// Type scale from the prototype.
abstract final class AppType {
  static const wordmarkSize = 12.0;
  static const wordmarkSpacing = 0.14;
  static const titleSize = 28.0;
  static const sectionSize = 13.0;
  static const bodySize = 14.0;
  static const rowSize = 17.0;
  static const heroTimeSize = 40.0;
  static const timeInputSize = 28.0;
}
