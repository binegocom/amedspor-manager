import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../widgets/admin_layout.dart';
import '../../../../data/models/badge_model.dart';
import '../../../../data/models/mission_model.dart';
import '../../../../data/repositories/gamification_repository.dart';

import 'package:uuid/uuid.dart';

class AdminGamificationScreen extends StatefulWidget {
  const AdminGamificationScreen({super.key});

  static const String routePath = '/admin/gamification';

  @override
  State<AdminGamificationScreen> createState() => _AdminGamificationScreenState();
}

class _AdminGamificationScreenState extends State<AdminGamificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final repo = GamificationRepository();
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBadgeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final xpController = TextEditingController();
    final pointsController = TextEditingController();
    final countController = TextEditingController();
    String category = 'general';
    String requiredEvent = 'daily_login';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yeni Rozet Oluştur', style: AppTextStyles.h2),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Başlık', labelStyle: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'XP Ödülü', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Puan Ödülü', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: requiredEvent,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Gerekli Olay', labelStyle: TextStyle(color: AppColors.muted)),
                        items: const [
                          DropdownMenuItem(value: 'daily_login', child: Text('Günlük Giriş')),
                          DropdownMenuItem(value: 'lineup_created', child: Text('Kadro Kurma')),
                          DropdownMenuItem(value: 'prediction_created', child: Text('Tahmin Yapma')),
                          DropdownMenuItem(value: 'post_created', child: Text('Post Paylaşma')),
                        ],
                        onChanged: (val) => setModalState(() => requiredEvent = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: countController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Hedef Sayı', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'ROZETİ OLUŞTUR',
                  onTap: () async {
                    final badge = BadgeModel(
                      id: uuid.v4(),
                      title: titleController.text,
                      description: descController.text,
                      category: category,
                      icon: 'shield_rounded',
                      colorValue: 0xFFE53935,
                      xpReward: int.tryParse(xpController.text) ?? 0,
                      pointsReward: int.tryParse(pointsController.text) ?? 0,
                      requiredEvent: requiredEvent,
                      requiredCount: int.tryParse(countController.text) ?? 1,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await repo.createBadge(badge);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMissionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final xpController = TextEditingController();
    final pointsController = TextEditingController();
    final countController = TextEditingController();
    final keyController = TextEditingController();
    String type = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yeni Görev Oluştur', style: AppTextStyles.h2),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Başlık', labelStyle: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: keyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Görev Anahtarı', hintText: 'örn: daily_login', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Tür', labelStyle: TextStyle(color: AppColors.muted)),
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Günlük')),
                          DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                          DropdownMenuItem(value: 'seasonal', child: Text('Sezonluk')),
                        ],
                        onChanged: (val) => setModalState(() => type = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: xpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'XP Ödülü', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Puan Ödülü', labelStyle: TextStyle(color: AppColors.muted)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Gerekli Sayı', labelStyle: TextStyle(color: AppColors.muted)),
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'GÖREVİ OLUŞTUR',
                  onTap: () async {
                    final mission = MissionModel(
                      id: uuid.v4(),
                      title: titleController.text,
                      description: descController.text,
                      type: type,
                      missionKey: keyController.text,
                      requiredCount: int.tryParse(countController.text) ?? 1,
                      xpReward: int.tryParse(xpController.text) ?? 0,
                      pointsReward: int.tryParse(pointsController.text) ?? 0,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await repo.createMission(mission);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminGamificationScreen.routePath,
      title: 'Oyunlaştırma Yönetimi',
      subtitle: 'Rozetler, görevler ve sistem kuralları',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryRed,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.muted,
              tabs: const [
                Tab(text: 'ROZETLER'),
                Tab(text: 'GÖREVLER'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BadgesTab(repo: repo, onCreate: _showBadgeDialog),
                _MissionsTab(repo: repo, onCreate: _showMissionDialog),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesTab extends StatelessWidget {
  final GamificationRepository repo;
  final VoidCallback onCreate;
  const _BadgesTab({required this.repo, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tüm Rozetler', style: AppTextStyles.h2),
            AppButton(
              text: 'YENİ ROZET',
              width: 160,
              onTap: onCreate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<BadgeModel>>(
          stream: repo.watchAllBadges(),
          builder: (context, snapshot) {
            final badges = snapshot.data ?? [];
            if (badges.isEmpty) return const Center(child: Text('Henüz rozet tanımlanmamış.', style: TextStyle(color: Colors.white38)));

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return PremiumCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_rounded, color: Color(badge.colorValue), size: 32),
                      const SizedBox(height: 12),
                      Text(badge.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      Text(badge.category, style: TextStyle(color: Color(badge.colorValue), fontSize: 10)),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _MissionsTab extends StatelessWidget {
  final GamificationRepository repo;
  final VoidCallback onCreate;
  const _MissionsTab({required this.repo, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Aktif Görevler', style: AppTextStyles.h2),
            AppButton(
              text: 'YENİ GÖREV',
              width: 160,
              onTap: onCreate,
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<MissionModel>>(
          stream: repo.watchAllMissions(),
          builder: (context, snapshot) {
            final missions = snapshot.data ?? [];
            if (missions.isEmpty) return const Center(child: Text('Henüz görev tanımlanmamış.', style: TextStyle(color: Colors.white38)));

            return Column(
              children: missions.map((mission) => PremiumCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryRed,
                    child: Icon(Icons.assignment_rounded, color: Colors.white),
                  ),
                  title: Text(mission.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(mission.description, style: const TextStyle(color: AppColors.muted)),
                  trailing: Text('${mission.xpReward} XP', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
