import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _goToTab(BuildContext context, int index) {
    if (index == currentIndex) return;

    HapticFeedback.lightImpact();

    switch (index) {
      case 0:
        context.go('/club-hub');
        break;
      case 1:
        context.go('/squad-hub');
        break;
      case 2:
        context.go('/training');
        break;
      case 3:
        context.go('/transfer-hub');
        break;
      case 4:
        context.go('/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF090D0B), // Harmonious deep OLED container
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.muted,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      currentIndex: currentIndex,
      onTap: (index) => _goToTab(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.shield_rounded),
          label: 'Kulüp',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_rounded),
          label: 'Takım',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_rounded),
          label: 'Antrenman',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_rounded),
          label: 'Transfer',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_soccer_rounded),
          label: 'Maçlar',
        ),
      ],
    );
  }
}
