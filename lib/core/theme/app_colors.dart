import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colours
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryContainer = Color(0xFFD8EEEA);
  static const Color onPrimaryContainer = Color(0xFF0F766E);
  static const Color accentAmber = Color(0xFFD97706);
  static const Color warningAmber = Color(0xFFD97706);
  static const Color successGreen = Color(0xFF15803D);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color infoBlue = Color(0xFF2563EB);

  // Light Theme
  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightOutline = Color(0xFFE2E8F0);
  static const Color lightOutlineVariant = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF172033);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Dark Theme
  static const Color darkBg = Color(0xFF0B1215);
  static const Color darkSurface = Color(0xFF131C21);
  static const Color darkCard = Color(0xFF131C21);
  static const Color darkOutline = Color(0xFF223038);
  static const Color darkOutlineVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Preset Accent Swatches
  static const List<Color> presetColors = [
    Color(0xFF0F766E), // Teal (default)
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFFD97706), // Warm Amber
    Color(0xFF059669), // Emerald
    Color(0xFFE11D48), // Rose
    Color(0xFF334155), // Slate
  ];
}
