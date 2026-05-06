import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF0F6A3D);
  static const Color primaryRed = Color(0xFFE53935);
  static const Color darkBackground = Color(0xFF080C0A);
  static const Color surface = Color(0xFF111713);
  static const Color card = Color(0xFF172019);
  static const Color softGreen = Color(0xFF143D2A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFA7B3AA);
  static const Color gold = Color(0xFFFFB300);
  static const Color error = Color(0xFFE53935);
  static const Color red = Color(0xFFE53935);
  static const Color errorRed = Color(0xFFE53935);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA7B3AA);

  // Gradient definitions
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, darkBackground],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [card, surface],
  );
}
