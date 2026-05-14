import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../shared/components/premium_card.dart';

class SquadHubScreen extends ConsumerStatefulWidget {
  const SquadHubScreen({super.key});

  @override
  ConsumerState<SquadHubScreen> createState() => _SquadHubScreenState();
}

class _SquadHubScreenState extends ConsumerState<SquadHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _mentality = 'Hücum';
  String _pressing = 'Yüksek Pres';
  String _passing = 'Kısa Pas';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.groups_rounded, color: AppColors.primaryGreen, size: 24),
            SizedBox(width: 8),
            Text(
              'TAKIM MERKEZİ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'DİZİLİŞ'),
            Tab(text: 'EMİRLER'),
            Tab(text: 'AI DANIŞMAN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. PANEL: DİZİLİŞ
          _buildLineupPanel(context),

          // 2. PANEL: EMİRLER
          _buildOrdersPanel(context),

          // 3. PANEL: AI DANIŞMANLIK
          _buildAIPanel(context),
        ],
      ),
    );
  }

  Widget _buildLineupPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            backgroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AKTİF DİZİLİŞ: 4-2-3-1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.sports_soccer_rounded, color: AppColors.gold),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stadium_rounded,
                          color: AppColors.primaryGreen,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Saha Yerleşimi Aktif',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Taktiksel uyum: %94',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.push('/lineups/me'),
                    child: const Text(
                      'KADRO DÜZENLEYİCİYİ AÇ',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'HIZLI DURUM',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          PremiumCard(
            backgroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusBadge(title: 'Kondisyon', value: '%88', color: Colors.green),
                _StatusBadge(title: 'Moral', value: 'Mükemmel', color: AppColors.gold),
                _StatusBadge(title: 'Kadro', value: '24 Oyuncu', color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersPanel(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'TAKIM ZİHNİYETİ',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSelector(
          options: ['Savunma', 'Dengeli', 'Hücum', 'Ultra Hücum'],
          current: _mentality,
          onChanged: (val) => setState(() => _mentality = val),
        ),
        const SizedBox(height: 20),

        const Text(
          'PRES ŞİDDETİ',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSelector(
          options: ['Kendi Yarı Sahanda', 'Dengeli Pres', 'Yüksek Pres'],
          current: _pressing,
          onChanged: (val) => setState(() => _pressing = val),
        ),
        const SizedBox(height: 20),

        const Text(
          'PAS ODAĞI',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildSelector(
          options: ['Kısa Pas', 'Karma', 'Uzun Top', 'Kanatlara Aç'],
          current: _passing,
          onChanged: (val) => setState(() => _passing = val),
        ),
        const SizedBox(height: 30),

        PremiumCard(
          backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Taktiksel emirler anında yerel motora işlendi. Maç motoru bu talimatları baz alacaktır.',
                  style: TextStyle(color: AppColors.primaryGreen, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAIPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            backgroundColor: AppColors.gold.withValues(alpha: 0.08),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      'AMEDSPOR AI ASİSTAN',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yapay zeka asistanımız sıradaki rakibinizin zayıf yönlerini analiz eder ve optimum kadro kurgusunu otomatik hazırlar.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_rounded, size: 18),
                    label: const Text(
                      'RAKİP ANALİZ RAPORU ÜRET (10 Jeton)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.gold,
                          content: Text(
                            'AI Raporu hazırlanıyor... Rakip sol kanat zayıf!',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector({
    required List<String> options,
    required String current,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == current;
        return PremiumCard(
          onTap: () => onChanged(opt),
          backgroundColor:
              isSelected ? AppColors.primaryGreen : const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            opt,
            style: TextStyle(
              color: isSelected ? Colors.black : AppColors.muted,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatusBadge({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
