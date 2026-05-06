import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const h1 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 30,
    fontWeight: FontWeight.w900,
  );

  static const h2 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w900,
  );

  static const h3 = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static const body = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 1.45,
  );

  static const caption = TextStyle(color: AppColors.textMuted, fontSize: 12);

  static const button = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w900,
  );
}
