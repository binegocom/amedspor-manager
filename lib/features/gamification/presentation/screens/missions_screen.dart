import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/user_mission_model.dart';
import '../../../../data/repositories/gamification_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/mission_item_card.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  static const String routePath = '/missions';

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with SingleTickerProviderStateMixin {
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
    final repo = GamificationRepository();
    final user = authService.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: StreamBuilder<List<UserMissionModel>>(
          stream: repo.watchUserMissions(user.uid),
          builder: (context, snapshot) {
            final allMissions = snapshot.data ?? [];
            return Column(
              children: [
                PremiumHeader(
                  title: 'GÖREV MERKEZİ',
                  showBackButton: true,
                ),
                _buildStatsSummary(allMissions),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primaryRed,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.muted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                  tabs: const [
                    Tab(text: 'GÜNLÜK'),
                    Tab(text: 'HAFTALIK'),
                    Tab(text: 'SEZONLUK'),
                  ],
                ),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _MissionList(
                              userId: user.uid,
                              missions: allMissions.where((m) => m.category == 'daily').toList(),
                            ),
                            _MissionList(
                              userId: user.uid,
                              missions: allMissions.where((m) => m.category == 'weekly').toList(),
                            ),
                            _MissionList(
                              userId: user.uid,
                              missions: allMissions.where((m) => m.category == 'season').toList(),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<UserMissionModel> missions) {
    final total = missions.length;
    final completed = missions.where((m) => m.completed).length;
    final claimed = missions.where((m) => m.claimed).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Toplam', value: '$total', color: Colors.white),
          _StatItem(label: 'Tamamlanan', value: '$completed', color: AppColors.primaryGreen),
          _StatItem(label: 'Alınan', value: '$claimed', color: AppColors.gold),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<UserMissionModel> missions;
  final String userId;
  const _MissionList({required this.missions, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: AppColors.muted.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Bu kategoride henüz bir görev yok.',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: missions.length,
      itemBuilder: (context, index) {
        return MissionItemCard(
          mission: missions[index],
          userId: userId,
        );
      },
    );
  }
}
