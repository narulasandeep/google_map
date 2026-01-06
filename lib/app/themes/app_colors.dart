import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4361EE);
  static const Color primaryDark = Color(0xFF3A56D4);
  static const Color primaryLight = Color(0xFF4895EF);

  // Secondary Colors
  static const Color secondary = Color(0xFF7209B7);
  static const Color accent = Color(0xFF4CC9F0);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFE9ECEF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Map Colors
  static const Color routeColor = Color(0xFF4361EE);
  static const Color startMarker = Color(0xFF4CAF50);
  static const Color endMarker = Color(0xFFF44336);
  static const Color userMarker = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}