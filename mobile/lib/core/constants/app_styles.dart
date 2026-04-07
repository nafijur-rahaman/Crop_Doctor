import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Padding & Margin
  static const double paddingScreen = 20.0;
  static const double cardPadding = 18.0;

  // Border Radius
  static const double radiusLarge = 30.0;
  static const double radiusCard = 22.0;
  static const double radiusSmall = 12.0;

  // Shadows
  static List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 10,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> highlightShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
