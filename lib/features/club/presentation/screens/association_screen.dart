import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class AssociationScreen extends ConsumerStatefulWidget {
  const AssociationScreen({super.key});

  @override
  ConsumerState<AssociationScreen> createState() => _AssociationScreenState();
}

class _AssociationScreenState extends ConsumerState<AssociationScreen> {
  final Set<String> _joinedAssociations = {'BARİKAT'}; // Varsayılan üyelik
  bool _isProcessing = false;
  String? _joiningAssocName;

  Future<void> _joinAssociation(
    BuildContext context,
    ClubModel club,
    String name,
  ) async {
    if (_isProcessing || _joinedAssociations.contains(name)) return;

    setState(() {
      _isProcessing = true;
      _joiningAssocName = name;
    });

    try {
      final clubRepo = ClubRepository();

      // Taraftar sayısını kalıcı olarak +50 artır
      await clubRepo.updateClub(club.copyWith(fans: club.fans + 50));

      setState(() {
        _joinedAssociations.add(name);
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text(
            '🚩 $name derneğine resmi olarak katıldınız! Tribün desteğiniz +50 Taraftar arttı.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryRed,
          content: Text('Derneğe katılım başarısız: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _joiningAssocName = null;
        });
      }
    }
  }

  void _openAssociationRoom(BuildContext context, String name) {
    final roomId = 'assoc-${name.toLowerCase().replaceAll(' ', '-')}';
    context.push('/chat/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    final clubAsync = ref.watch(currentClubStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('TARAFTAR DERNEKLERİ', style: AppTextStyles.h3),
      ),
      body: clubAsync.when(
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
          if (club == null) {
            return const Center(
              child: Text(
                'Kulüp bilgisi bulunamadı.',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Taraftar Desteği Özeti
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOPLAM TARAFTAR GÜCÜ:',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${club.fans} 🚩',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildAssociationCard(
                context,
                club,
                name: 'BARİKAT',
                members: 1250,
                level: 15,
                description:
                    'Amedspor\'un her zaman yanındaki sarsılmaz barikat.',
              ),
              const SizedBox(height: 16),
              _buildAssociationCard(
                context,
                club,
                name: 'DİREN HA',
                members: 850,
                level: 10,
                description:
                    'Direnişin ve onurlu mücadelenin tribündeki asi sesi.',
              ),
              const SizedBox(height: 16),
              _buildAssociationCard(
                context,
                club,
                name: 'MOR BARİKAT',
                members: 450,
                level: 8,
                description:
                    'Kadın taraftarların güçlü, coşkulu ve sarsılmaz temsilcisi.',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssociationCard(
    BuildContext context,
    ClubModel club, {
    required String name,
    required int members,
    required int level,
    required String description,
  }) {
    final isJoined = _joinedAssociations.contains(name);
    final currentMembers = isJoined && name != 'BARİKAT'
        ? members + 1
        : members;
    final isThisLoading = _isProcessing && _joiningAssocName == name;

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.h2),
                    Text(
                      '$currentMembers Üye | Seviye $level',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isJoined) const _JoinedBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: isJoined ? 'ODAYA GİT' : 'KATIL (+50 Taraftar)',
                  color: isJoined
                      ? AppColors.primaryGreen
                      : AppColors.primaryRed,
                  isLoading: isThisLoading,
                  onTap: () {
                    if (isJoined) {
                      _openAssociationRoom(context, name);
                    } else {
                      _joinAssociation(context, club, name);
                    }
                  },
                ),
              ),
              if (isJoined) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Taraftar Odasını Aç',
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.gold,
                  ),
                  onPressed: () => _openAssociationRoom(context, name),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinedBadge extends StatelessWidget {
  const _JoinedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.5),
        ),
      ),
      child: const Text(
        'ÜYESİN',
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
