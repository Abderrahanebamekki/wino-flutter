import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF05424E);
  static const Color primary = Color(0xFF346A76);
  static const Color primaryLight = Color(0xFF234A52);
  static const Color primaryAlt = Color(0xFF012F39);

  static const Color background = Color(0xFFF7F6F6);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color cardBorderAlt = Color(0xFFEAEAEA);
  static const Color divider = Color(0xFFD9D9D9);

  static const Color textPrimary = Color(0xFF05424E);
  static const Color textBody = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textHint = Colors.grey;

  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
  static const Color warning = Colors.orange;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 18;
  static const double radiusPanel = 24;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets formPadding = EdgeInsets.all(16);
}
