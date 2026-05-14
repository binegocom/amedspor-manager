import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_card.dart';
import '../controllers/ai_assistant_controller.dart';

class AiAssistantScreen extends ConsumerWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiAssistantProvider);
    final clubAsync = ref.watch(currentClubStreamProvider);

    final categories = ['Taktik', 'Basın Açıklaması', 'Finans', 'Akademi'];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B09),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGreen, size: 22),
            SizedBox(width: 8),
            Text(
              'AI TAKTİK & BASIN DİREKTÖRÜ',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: clubAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: AppColors.primaryRed))),
          data: (club) {
            return Column(
              children: [
                // Asistan Başlık & Kimlik Kartı
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B09),
                    border: Border(bottom: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.15))),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Image.asset('assets/images/app_icon.png'),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Amedspor GPT-4o', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                SizedBox(width: 8),
                                _StatusBadge(),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Kulüp verileri, taraftar coşkusu ve rakip analizlerine dayalı stratejik oyunlaştırma danışmanı.',
                              style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Kategori Seçim Çubuğu
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = state.selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => ref.read(aiAssistantProvider.notifier).setCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGreen : Colors.white10,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getCategoryIcon(cat),
                                  color: isSelected ? AppColors.primaryGreen : AppColors.muted,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Analiz Gösterim Alanı
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.isLoading)
                          const PremiumCard(
                            backgroundColor: Color(0xFF101010),
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                CircularProgressIndicator(color: AppColors.primaryGreen),
                                SizedBox(height: 16),
                                Text(
                                  'Amedspor taktik tahtası ve ekonomik parametreler taranıyor...\nGenkit / LLM motoru devrede.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          )
                        else if (state.displayedText.isNotEmpty)
                          PremiumCard(
                            backgroundColor: const Color(0xFF101010),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(state.selectedCategory),
                                          color: AppColors.gold,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${state.selectedCategory.toUpperCase()} STRATEJİSİ',
                                          style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                                        ),
                                      ],
                                    ),
                                    if (state.isTypingCompleted)
                                      const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 16)
                                    else
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(color: AppColors.primaryGreen, strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),
                                SelectableText(
                                  state.displayedText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.6,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          PremiumCard(
                            backgroundColor: const Color(0xFF101010),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.biotech_rounded, color: AppColors.muted.withValues(alpha: 0.5), size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Henüz analiz üretilmedi',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Kulübünüzün güncel mali verilerini, stadyum seviyesini veya taraftar coşkusunu analiz ettirmek için aşağıdaki butonu kullanın.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.8), fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Zeka Üret Butonu
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: AppButton(
                    text: state.isLoading ? 'ANALİZ EDİLİYOR...' : '⚡ ${state.selectedCategory.toUpperCase()} STRATEJİSİ ÜRET',
                    type: AppButtonType.primary,
                    isLoading: state.isLoading,
                    onTap: () => ref.read(aiAssistantProvider.notifier).generateAdvice(club),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Taktik':
        return Icons.sports_soccer_rounded;
      case 'Basın Açıklaması':
        return Icons.mic_rounded;
      case 'Finans':
        return Icons.account_balance_wallet_rounded;
      case 'Akademi':
        return Icons.school_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.circle, color: AppColors.primaryGreen, size: 6),
          SizedBox(width: 4),
          Text('ON-DEVICE AI', style: TextStyle(color: AppColors.primaryGreen, fontSize: 8, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
