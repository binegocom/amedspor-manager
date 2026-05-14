import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/premium_card.dart';

class ClubHubScreen extends ConsumerStatefulWidget {
  const ClubHubScreen({super.key});

  @override
  ConsumerState<ClubHubScreen> createState() => _ClubHubScreenState();
}

class _ClubHubScreenState extends ConsumerState<ClubHubScreen> {
  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.gold, size: 24),
            SizedBox(width: 8),
            Text(
              'KULÜP MERKEZİ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.muted),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, color: AppColors.gold),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: clubAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Hata: $err',
              style: const TextStyle(color: AppColors.primaryRed),
            ),
          ),
          data: (club) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ekonomik Göstergeler & Bütçe Kartı
                        PremiumCard(
                          backgroundColor: const Color(0xFF121212),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KULÜP KASASI & REZERVLER',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        club != null
                                            ? '${_formatCurrency(club.cash)} ₺'
                                            : '---',
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Nakit Bütçe',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.generating_tokens_rounded,
                                          color: AppColors.gold,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          club != null ? '${club.tokens}' : '-',
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.muted,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        club != null
                                            ? 'Kulüp İtibarı: ${club.reputation} / 100 • Taraftar: ${club.fans}'
                                            : 'Kulüp bilgileri yükleniyor...',
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'KURUMSAL YÖNETİM MODÜLLERİ',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Modül Listesi
                        _ClubModuleCard(
                          title: 'AI Taktik & Basın Direktörü',
                          subtitle:
                              'Kulüp verileri, taraftar coşkusu ve stadyum parametrelerine dayalı stratejik oyunlaştırma asistanı.',
                          icon: Icons.auto_awesome_rounded,
                          color: AppColors.primaryGreen,
                          onTap: () => context.push('/ai-assistant'),
                        ),
                        const SizedBox(height: 12),

                        _ClubModuleCard(
                          title: 'Tesisler & Stadyum',
                          subtitle:
                              'Stadyum kapasitesini artır, antrenman ve sağlık merkezlerini inşa et.',
                          icon: Icons.business_rounded,
                          color: AppColors.primaryGreen,
                          onTap: () => context.push('/facilities'),
                        ),
                        const SizedBox(height: 12),

                        _ClubModuleCard(
                          title: 'Finans & Sponsorluklar',
                          subtitle:
                              'Sponsorluk tekliflerini değerlendir, imza parası ve nakit akışını yönet.',
                          icon: Icons.handshake_rounded,
                          color: AppColors.gold,
                          onTap: () => context.push('/sponsorships'),
                        ),
                        const SizedBox(height: 12),

                        _ClubModuleCard(
                          title: 'Amedspor Akademisi',
                          subtitle:
                              'Altyapıdan genç yetenekleri keşfet, A takıma kazandır.',
                          icon: Icons.school_rounded,
                          color: Colors.orangeAccent,
                          onTap: () => context.push('/academy'),
                        ),
                        const SizedBox(height: 12),

                        _ClubModuleCard(
                          title: 'Kulüp Müzesi & Başarılar',
                          subtitle:
                              'Kazanılan kupalar, derbi zaferleri ve kulüp tarihini incele.',
                          icon: Icons.museum_rounded,
                          color: AppColors.primaryRed,
                          onTap: () => context.push('/museum'),
                        ),
                        const SizedBox(height: 12),

                        _ClubModuleCard(
                          title: 'Taraftar Dernekleri',
                          subtitle:
                              'Dernek haritası, imece bütçe destekleri ve taraftar etkileşimi.',
                          icon: Icons.groups_3_rounded,
                          color: Colors.deepPurpleAccent,
                          onTap: () => context.push('/associations'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class _ClubModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ClubModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      backgroundColor: const Color(0xFF121212),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
