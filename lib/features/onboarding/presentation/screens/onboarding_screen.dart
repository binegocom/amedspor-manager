import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/app_content_model.dart';
import '../../../../data/repositories/app_content_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String routePath = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final _repository = AppContentRepository();
  late final Stream<AppContentModel> _contentStream;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _contentStream = _repository.watchContent('onboarding');
  }

  Future<void> _completeOnboarding(String? actionUrl) async {
    await appStateService.setOnboardingCompleted();
    if (!mounted) return;

    if (actionUrl != null && actionUrl.startsWith('/')) {
      context.go(actionUrl);
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<AppContentModel>(
        stream: _contentStream,
        builder: (context, snapshot) {
          final content = snapshot.data ?? AppContentModel.defaultOnboarding();
          final items = content.isActive && content.items.isNotEmpty
              ? content.items
              : AppContentModel.defaultOnboarding().items;
          final lastPageIndex = items.length - 1;
          if (_currentPage > lastPageIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _currentPage = lastPageIndex);
              if (_controller.hasClients) {
                _controller.jumpToPage(lastPageIndex);
              }
            });
          }

          return Stack(
            children: [
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = items[index];
                  final isAsset = slide.imageUrl.startsWith('assets/');
                  final isFile = slide.imageUrl.startsWith('C:') || slide.imageUrl.startsWith('c:') || slide.imageUrl.startsWith('/');

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image rendering
                      if (slide.imageUrl.isNotEmpty)
                        if (isAsset)
                          Image.asset(
                            slide.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: const Color(0xFF111111)),
                          )
                        else if (isFile && !kIsWeb)
                          Image.file(
                            File(slide.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: const Color(0xFF111111)),
                          )
                        else
                          Image.network(
                            slide.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: const Color(0xFF111111)),
                          ),

                      // Premium dark gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),

                      // Dynamic Text Contents
                      Positioned(
                        left: 32,
                        right: 32,
                        bottom: 120,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryRed.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'AMEDSPOR DİJİTAL TRİBÜN',
                                style: TextStyle(
                                  color: AppColors.primaryRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.body,
                              style: const TextStyle(
                                color: Color(0xFFCCCCCC),
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Top Right "GEÇ" (Skip) Button
            if (_currentPage < lastPageIndex)
              Positioned(
                top: 60,
                right: 24,
                child: TextButton(
                  onPressed: () => _completeOnboarding(null),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'GEÇ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

            // Bottom Controls Overlay: Indicators + Action Button
            Positioned(
                left: 32,
                right: 32,
                bottom: 42,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        items.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 6,
                          width: _currentPage == index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.primaryRed
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),

                    // Action Button
                    ElevatedButton(
                      onPressed: () {
                        final currentSlide = items[_currentPage];
                        if (_currentPage == lastPageIndex) {
                          _completeOnboarding(
                            currentSlide.actionUrl.isNotEmpty
                                ? currentSlide.actionUrl
                                : null,
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            items[_currentPage].actionText.isNotEmpty
                                ? items[_currentPage].actionText
                                : (_currentPage == items.length - 1
                                      ? 'BAŞLA'
                                      : 'İLERİ'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
