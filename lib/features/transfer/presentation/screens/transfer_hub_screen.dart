import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../shared/components/premium_card.dart';

class TransferHubScreen extends ConsumerStatefulWidget {
  const TransferHubScreen({super.key});

  @override
  ConsumerState<TransferHubScreen> createState() => _TransferHubScreenState();
}

class _TransferHubScreenState extends ConsumerState<TransferHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D0B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_rounded, color: AppColors.primaryRed, size: 24),
            SizedBox(width: 8),
            Text(
              'TRANSFER MERKEZİ',
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
          indicatorColor: AppColors.primaryRed,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CANLI PAZAR'),
            Tab(text: 'GÖZLEMCİ'),
            Tab(text: 'MAĞAZA'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. PANEL: CANLI PAZAR
          _buildMarketPanel(context),

          // 2. PANEL: GÖZLEMCİ AĞI
          _buildScoutingPanel(context),

          // 3. PANEL: MAĞAZA & EFSANELER
          _buildStorePanel(context),
        ],
      ),
    );
  }

  Widget _buildMarketPanel(BuildContext context) {
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
                  children: [
                    Icon(Icons.timer_rounded, color: AppColors.primaryRed),
                    SizedBox(width: 8),
                    Text(
                      'MÜZAYEDELER DEVAM EDİYOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Küresel transfer pazarında her saat başı yeni yetenekler listelenir. Rakiplerinizden önce teklif verin.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.push('/transfers'),
                    child: const Text(
                      'CANLI TRANSFER PAZARINA GİR',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ÖNE ÇIKAN FIRSATLAR',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _PlayerDealCard(
            name: 'Barış Zümrüt',
            position: 'OS / MO',
            rating: 84,
            price: '4.500.000 ₺',
            timeLeft: '14 Dk',
            onTap: () => context.push('/transfers'),
          ),
          const SizedBox(height: 10),
          _PlayerDealCard(
            name: 'Azad Yılmaz',
            position: 'ST / SF',
            rating: 88,
            price: '8.200.000 ₺',
            timeLeft: '2 Dk',
            onTap: () => context.push('/transfers'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoutingPanel(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PremiumCard(
          backgroundColor: AppColors.gold.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(16),
          child: const Row(
            children: [
              Icon(Icons.travel_explore_rounded, color: AppColors.gold, size: 28),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ELİT GÖZLEMCİ AĞI',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Gözlemcilerimiz Amedspor felsefesine tam uyumlu yıldızları listeler. Bu oyuncular doğrudan imzaya açıktır.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'GÖZLEMCİ LİSTESİ (ANINDA İMZA)',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _ScoutPlayerCard(
          name: 'Ciwan Şiyar',
          position: 'KL',
          rating: 91,
          tokenCost: 49,
          cashCost: '12.000.000 ₺',
        ),
        const SizedBox(height: 12),
        _ScoutPlayerCard(
          name: 'Renas Dicle',
          position: 'SLB / ST',
          rating: 89,
          tokenCost: 39,
          cashCost: '9.500.000 ₺',
        ),
      ],
    );
  }

  Widget _buildStorePanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PremiumCard(
            backgroundColor: const Color(0xFF121212),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.store_rounded, color: AppColors.gold, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'RESMİ KULÜP MAĞAZASI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jeton paketleri, özel moral drilleri ve stadyum bilet artırıcıları.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => context.push('/store'),
                    child: const Text(
                      'MAĞAZAYI GÖRÜNTÜLE',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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

class _PlayerDealCard extends StatelessWidget {
  final String name;
  final String position;
  final int rating;
  final String price;
  final String timeLeft;
  final VoidCallback onTap;

  const _PlayerDealCard({
    required this.name,
    required this.position,
    required this.rating,
    required this.price,
    required this.timeLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      backgroundColor: const Color(0xFF121212),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              position,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kalan Süre: $timeLeft',
                  style: const TextStyle(color: AppColors.primaryRed, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '⚡ $rating',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(price, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoutPlayerCard extends StatelessWidget {
  final String name;
  final String position;
  final int rating;
  final int tokenCost;
  final String cashCost;

  const _ScoutPlayerCard({
    required this.name,
    required this.position,
    required this.rating,
    required this.tokenCost,
    required this.cashCost,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: const Color(0xFF121212),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              position,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'İmza Bedeli: $cashCost',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.generating_tokens_rounded, size: 14),
            label: Text(
              '$tokenCost',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.primaryGreen,
                  content: Text('$name kulübe katıldı!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
