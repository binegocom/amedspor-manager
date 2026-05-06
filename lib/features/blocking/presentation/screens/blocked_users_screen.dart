import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../data/repositories/block_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/models/app_user_model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _blockRepository = BlockRepository();
  final _userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PremiumHeader(title: 'Engellenen Kişiler'),
          Expanded(
            child: currentUser == null
                ? const Center(child: Text('Lütfen giriş yapın.'))
                : StreamBuilder<List<String>>(
                    stream: _blockRepository.getBlockedUserIds(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      final blockedIds = snapshot.data!;

                      if (blockedIds.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_rounded, size: 64, color: AppColors.muted.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Engellenen kimse yok.',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: blockedIds.length,
                        separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                        itemBuilder: (context, index) {
                          return FutureBuilder<AppUserModel?>(
                            future: _userRepository.getUser(blockedIds[index]),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) return const SizedBox(height: 72);
                              final user = userSnapshot.data!;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(user.avatarUrl),
                                  backgroundColor: AppColors.card,
                                ),
                                title: Text(user.username, style: AppTextStyles.h4),
                                subtitle: Text(user.role, style: AppTextStyles.bodySmall.copyWith(color: AppColors.muted)),
                                trailing: TextButton(
                                  onPressed: () => _blockRepository.unblockUser(currentUser.uid, user.id),
                                  child: const Text('ENGELİ KALDIR', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
