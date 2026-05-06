import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../widgets/admin_layout.dart';

class AdminMatchesScreen extends StatelessWidget {
  const AdminMatchesScreen({super.key});

  static const String routePath = '/admin/matches';

  Future<void> _deleteMatch(BuildContext context, MatchRepository repository, MatchModel match) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Maç Silinsin mi?', style: TextStyle(color: Colors.white)),
        content: Text('${match.homeTeam} vs ${match.awayTeam} maçı silinecek.', style: const TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İPTAL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SİL', style: TextStyle(color: AppColors.primaryRed))),
        ],
      ),
    );

    if (confirm == true) {
      await repository.deleteMatch(match.id);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppColors.primaryGreen, content: Text('Maç silindi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return AdminLayout(
      activeRoute: routePath,
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fikstür Yönetimi', style: AppTextStyles.h1),
                  Text('Maçları düzenle, sil ve canlı kontrol merkezine eriş', style: AppTextStyles.body),
                ],
              ),
              AppButton(
                text: 'YENİ MAÇ EKLE',
                width: 200,
                icon: Icons.add_rounded,
                onTap: () => context.go('/admin/matches/create'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          StreamBuilder<List<MatchModel>>(
            stream: matchRepository.watchMatches(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
              }
              final matches = snapshot.data ?? [];
              if (matches.isEmpty) return const Center(child: Text('Henüz maç eklenmedi.', style: TextStyle(color: AppColors.muted)));

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: matches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _AdminMatchCard(
                  match: matches[index],
                  onEdit: () => context.go('/admin/matches/edit/${matches[index].id}'),
                  onLive: () => context.go('/admin/matches/live/${matches[index].id}'),
                  onDelete: () => _deleteMatch(context, matchRepository, matches[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminMatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onEdit;
  final VoidCallback onLive;
  final VoidCallback onDelete;

  const _AdminMatchCard({required this.match, required this.onEdit, required this.onLive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'live';

    return PremiumCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLive ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sports_soccer_rounded, color: isLive ? AppColors.primaryRed : AppColors.muted, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${match.homeTeam} vs ${match.awayTeam}', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  '${match.matchDate.day}.${match.matchDate.month} ${match.matchDate.hour}:${match.matchDate.minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              IconButton(onPressed: onLive, icon: const Icon(Icons.live_tv_rounded, color: AppColors.primaryGreen), tooltip: 'Canlı Kontrol'),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, color: AppColors.gold), tooltip: 'Düzenle'),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, color: AppColors.errorRed), tooltip: 'Sil'),
            ],
          ),
        ],
      ),
    );
  }
}
