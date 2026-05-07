import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../core/theme/app_text_styles.dart';

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
          PageView.builder(
            controller: _controller,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final item = _items[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    item.image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: const Color(0xFF0F6A3D), size: 48),
                        const SizedBox(height: 24),
                        Text(
                          item.title,
                          style: AppTextStyles.h1.copyWith(height: 1.1),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 32 : 8,
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
                FloatingActionButton(
                  onPressed: _next,
                  backgroundColor: const Color(0xFF0F6A3D),
                  child: Icon(
                    _currentPage == _items.length - 1
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
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
