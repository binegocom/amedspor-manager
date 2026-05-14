import 'package:flutter/material.dart';

class AppColors {
  // Ultra-Vibrant Premium Brand Core Colors
  static const Color primaryGreen = Color(0xFF0A7A3E); // Rich Stadium Emerald
  static const Color primaryRed = Color(0xFFE51D1A); // High-Energy Crimson
  
  // Ergonomic OLED Dark Mode Backgrounds (True Black Deep Onyx)
  static const Color darkBackground = Color(0xFF050606); // Pure Deep Void
  static const Color surface = Color(0xFF0D1210); // Subtle Metallic Surface
  static const Color card = Color(0xFF141A17); // Premium Frosted Card Base
  static const Color softGreen = Color(0xFF0F3822); // Deep Shadow Green
  
  // Custom Themed Background Base Tokens
  static const Color onyxPlate = Color(0xFF0A0C0B); // Leaderboard/Gamification base
  static const Color tacticalBlueDark = Color(0xFF070E14); // Lineup blueprint base
  
  // Premium Typography
  static const Color white = Color(0xFFF2F5F3);
  static const Color textPrimary = Color(0xFFF2F5F3);
  static const Color textSecondary = Color(0xFFA0ACA3);
  static const Color muted = Color(0xFFA0ACA3);
  
  // Accents
  static const Color gold = Color(0xFFFFB800); // Pure Crown Gold
  static const Color error = primaryRed;
  
  // Aliases for compatibility
  static const Color errorRed = primaryRed;
  static const Color red = primaryRed;

  // Global Primary Multi-Layer Gradients
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

  // Screen-Specific Atmospheric Background Gradients
  // 1. Live Match Center: Deep Turf Radial Aura
  static const RadialGradient liveMatchTurfGradient = RadialGradient(
    center: Alignment(0, -0.2),
    radius: 1.2,
    colors: [
      Color(0xFF0F3822), // Soft emerald illumination from pitch center
      darkBackground,
    ],
    stops: [0.0, 1.0],
  );

  // 2. Lineup Builder: Tactical Blueprint Overlay
  static const LinearGradient tacticalBlueprintGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A141D),
      darkBackground,
    ],
  );

  // 3. Missions/Gamification: Metallic Onyx Armor
  static const LinearGradient onyxArmorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF181C1A),
      Color(0xFF080A09),
    ],
  );
}
