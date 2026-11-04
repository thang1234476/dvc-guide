import 'package:flutter/material.dart';

/// Application color palette.
/// All colors are defined here to maintain consistency across the app.
///
/// Usage: AppColors.primary, AppColors.surface, etc.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Brand Colors ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);       // Deep Blue
  static const Color primaryLight = Color(0xFF1E88E5);  // Medium Blue
  static const Color primaryDark = Color(0xFF0D47A1);   // Dark Blue

  static const Color secondary = Color(0xFF00897B);     // Teal
  static const Color secondaryLight = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF00695C);

  // ── Surface Colors ──────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFF);
  static const Color surfaceDark = Color(0xFF0F1923);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A2533);

  // ── Text Colors ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textPrimaryDark = Color(0xFFF0F4FF);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  // ── Status Colors ────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFC62828);
  static const Color warning = Color(0xFFE65100);
  static const Color info = Color(0xFF1565C0);

  // ── Neutral ─────────────────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE0E7EF);
  static const Color dividerDark = Color(0xFF2D3748);
}
