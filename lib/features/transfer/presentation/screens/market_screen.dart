import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../domain/services/pack_generator_service.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _clubRepo = ClubRepository();
  final _playerRepo = PlayerRepository();
  final _packService = PackGeneratorService();

  bool _isLoading = false;

  Future<void> _buyPack(PackType type, int cost) async {
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final club = await _clubRepo.getClub(user.uid);
      if (club == null) {
        throw Exception('Kulüp bilgisi bulunamadı.');
      }

      if (club.cash < cost) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yetersiz bakiye! ₺ kazanmak için maç yapın.'),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Parayı düş
      await _clubRepo.updateResources(user.uid, cash: -cost);

      // Paketi aç ve oyuncuyu veritabanına ekle
      final newPlayer = _packService.openPack(type: type, ownerId: user.uid);
      await _playerRepo.createPlayer(newPlayer);

      if (mounted) {
        _showNewPlayerDialog(newPlayer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewPlayerDialog(PlayerModel player) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✨ YENİ OYUNCU ✨',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: player.position == 'GK'
                        ? AppColors.gold
                        : AppColors.primaryGreen,
                    child: Text(
                      '${player.number}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${player.position} • OVR: ${player.rating}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      player.stars,
                      (index) => const Icon(
                        Icons.star,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Değer: ${player.marketValue} ₺',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
              ),
              child: const Text(
                'Kadroma Ekle',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackCard({
    required String title,
    required String description,
    required int cost,
    required Color color,
    required PackType type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Icon(Icons.style, color: color, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '$cost ₺',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _buyPack(type, cost),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SATIN AL',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final clubAsync = ref.watch(currentClubStreamProvider);
    final club = clubAsync.valueOrNull;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Giriş yapılmadı')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Transfer Pazarı',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (club != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primaryGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${club.cash} ₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Paketleri açarak kadronu güçlendir!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _buildPackCard(
                title: 'Standart Paket',
                description:
                    'Genç yetenekler ve rotasyon oyuncuları (OVR 50-70).',
                cost: 2000,
                color: Colors.brown.shade300,
                type: PackType.standard,
              ),
              _buildPackCard(
                title: 'Gümüş Paket',
                description: 'İlk 11 için kaliteli oyuncular (OVR 65-80).',
                cost: 5000,
                color: Colors.grey.shade400,
                type: PackType.silver,
              ),
              _buildPackCard(
                title: 'Altın Paket',
                description: 'Dünya yıldızları ve efsaneler (OVR 78-95).',
                cost: 15000,
                color: AppColors.gold,
                type: PackType.gold,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            ),
        ],
      ),
    );
  }
}
