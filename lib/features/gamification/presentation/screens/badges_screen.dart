import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/user_badge_model.dart';
import '../../../../data/repositories/gamification_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  static const String routePath = '/badges';

  @override
  Widget build(BuildContext context) {
    final repo = GamificationRepository();
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const PremiumHeader(title: 'ROZETLERİM', showBackButton: true),
            Expanded(
              child: StreamBuilder<List<UserBadgeModel>>(
                stream: repo.watchUserBadges(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                  }

                  final badges = snapshot.data ?? [];

                  if (badges.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.muted.withValues(alpha: 0.3), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz hiç rozet kazanmadın.\nAktivitelere katılarak rozet topla!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, height: 1.5),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (context, index) {
                      final badge = badges[index];
                      return _BadgeCard(badge: badge);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final UserBadgeModel badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(badge.colorValue).withValues(alpha: 0.1),
              border: Border.all(color: Color(badge.colorValue).withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              _getIcon(badge.icon),
              color: Color(badge.colorValue),
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            badge.category.toUpperCase(),
            style: TextStyle(color: Color(badge.colorValue), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Text(
            '${badge.earnedAt.day} ${_getMonthName(badge.earnedAt.month)} ${badge.earnedAt.year}',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'shield': return Icons.shield_rounded;
      case 'star': return Icons.stars_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'groups': return Icons.groups_rounded;
      case 'sports_soccer': return Icons.sports_soccer_rounded;
      default: return Icons.shield_rounded;
    }
  }

  String _getMonthName(int month) {
    const months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
    return months[month - 1];
  }
}
