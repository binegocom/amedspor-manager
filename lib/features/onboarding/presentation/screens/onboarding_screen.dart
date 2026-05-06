import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/firebase/firebase_providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'TAKIMINI KUR\nSTRATEJİNİ BELİRLE\nZAFERE ULAŞ!',
      description: 'Amedspor’un başına geç, kendi hikayeni yazmaya başla.',
      icon: Icons.stadium_rounded,
      image: 'assets/images/onboarding_1.png',
    ),
    _OnboardingItem(
      title: 'KULÜBÜNÜ YÖNET',
      description: 'Transferleri yap, kadronu güçlendir ve takımını şampiyonluğa taşı.',
      icon: Icons.groups_rounded,
      image: 'assets/images/onboarding_2.png',
    ),
    _OnboardingItem(
      title: 'TAKTİĞİNİ OLUŞTUR',
      description: 'Formasyonunu seç, taktiklerini belirle ve rakiplerine üstünlük kur.',
      icon: Icons.psychology_rounded,
      image: 'assets/images/onboarding_3.png',
    ),
  ];

  Future<void> _next() async {
    if (_currentPage == _items.length - 1) {
      await appStateService.setOnboardingCompleted();
      if (!mounted) return;
      context.go('/home');
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Interactive Area
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _next,
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                final item = _items[index];

                return Stack(
                  children: [
                    // Image Background (Original Quality)
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(item.image),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SafeArea(
                      child: Column(
                        children: [
                          Spacer(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Indicators
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF0F6A3D)
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final String image;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.image,
  });
}
