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
  State<AdminGamificationScreen> createState() =>
      _AdminGamificationScreenState();
}

class _AdminGamificationScreenState extends State<AdminGamificationScreen>
    with SingleTickerProviderStateMixin {
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
    final boosterController = TextEditingController(text: '0.0');
    String category = 'general';
    String requiredEvent = 'daily_login';
    String tier = 'bronze';

    int colorForTier(String t) {
      switch (t) {
        case 'bronze':
          return 0xFFCD7F32;
        case 'silver':
          return 0xFFC0C0C0;
        case 'gold':
          return 0xFFFFD700;
        case 'platinum':
          return 0xFFE5E4E2;
        case 'diamond':
          return 0xFFB9F2FF;
        default:
          return 0xFFCD7F32;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Premium Rozet Oluştur',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: tier,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Kademe (Tier)',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'bronze',
                            child: Text('Bronz'),
                          ),
                          DropdownMenuItem(
                            value: 'silver',
                            child: Text('Gümüş'),
                          ),
                          DropdownMenuItem(value: 'gold', child: Text('Altın')),
                          DropdownMenuItem(
                            value: 'platinum',
                            child: Text('Platin'),
                          ),
                          DropdownMenuItem(
                            value: 'diamond',
                            child: Text('Elmas'),
                          ),
                        ],
                        onChanged: (val) => setModalState(() => tier = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: boosterController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'XP Booster (%)',
                          hintText: 'örn: 0.15',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'XP Ödülü',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Puan Ödülü',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Gerekli Olay',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily_login',
                            child: Text('Günlük Giriş'),
                          ),
                          DropdownMenuItem(
                            value: 'lineup_created',
                            child: Text('Kadro Kurma'),
                          ),
                          DropdownMenuItem(
                            value: 'prediction_created',
                            child: Text('Tahmin Yapma'),
                          ),
                          DropdownMenuItem(
                            value: 'post_created',
                            child: Text('Post Paylaşma'),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => requiredEvent = val!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: countController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Hedef Sayı',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
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
                      colorValue: colorForTier(tier),
                      xpReward: int.tryParse(xpController.text) ?? 0,
                      pointsReward: int.tryParse(pointsController.text) ?? 0,
                      requiredEvent: requiredEvent,
                      requiredCount: int.tryParse(countController.text) ?? 1,
                      tier: tier,
                      xpBooster: double.tryParse(boosterController.text) ?? 0.0,
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
    final nextMissionController = TextEditingController();
    String type = 'daily';
    bool isChained = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Yeni Bağlı Görev Oluştur', style: AppTextStyles.h2),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: keyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Görev Anahtarı',
                          hintText: 'örn: daily_login',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Tür',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Günlük'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Haftalık'),
                          ),
                          DropdownMenuItem(
                            value: 'seasonal',
                            child: Text('Sezonluk'),
                          ),
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
                        decoration: const InputDecoration(
                          labelText: 'XP Ödülü',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Puan Ödülü',
                          labelStyle: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Gerekli Sayı',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primaryRed,
                  title: const Text(
                    'Bağlı Görev (Chained Mission)',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Bu görev bittiğinde zincirleme başka görevi tetikler',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  value: isChained,
                  onChanged: (val) => setModalState(() => isChained = val),
                ),
                if (isChained) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: nextMissionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Sonraki Görev ID',
                      hintText: 'Tetiklenecek hedefin tam ID\'si',
                      labelStyle: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
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
                      isChained: isChained,
                      nextMissionId: isChained
                          ? nextMissionController.text.trim()
                          : null,
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

  String _tierName(String t) {
    switch (t) {
      case 'bronze':
        return 'Bronz';
      case 'silver':
        return 'Gümüş';
      case 'gold':
        return 'Altın';
      case 'platinum':
        return 'Platin';
      case 'diamond':
        return 'Elmas';
      default:
        return 'Bronz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Premium Kademeli Rozetler', style: AppTextStyles.h2),
            AppButton(text: 'YENİ ROZET', width: 160, onTap: onCreate),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<BadgeModel>>(
          stream: repo.watchAllBadges(),
          builder: (context, snapshot) {
            final badges = snapshot.data ?? [];
            if (badges.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz premium rozet tanımlanmamış.',
                  style: TextStyle(color: Colors.white38),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return PremiumCard(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            color: Color(badge.colorValue),
                            size: 40,
                          ),
                          if (badge.xpBooster > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+%${(badge.xpBooster * 100).toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        badge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_tierName(badge.tier)} Seviye',
                        style: TextStyle(
                          color: Color(badge.colorValue),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.category,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
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
            const Text(
              'Bağlı (Chained) Görev Akışları',
              style: AppTextStyles.h2,
            ),
            AppButton(text: 'YENİ GÖREV', width: 160, onTap: onCreate),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<List<MissionModel>>(
          stream: repo.watchAllMissions(),
          builder: (context, snapshot) {
            final missions = snapshot.data ?? [];
            if (missions.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz bağlı görev tanımlanmamış.',
                  style: TextStyle(color: Colors.white38),
                ),
              );
            }

            return Column(
              children: missions
                  .map(
                    (mission) => PremiumCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: mission.isChained
                              ? const Color(0xFF7B1FA2)
                              : AppColors.primaryRed,
                          child: Icon(
                            mission.isChained
                                ? Icons.link_rounded
                                : Icons.assignment_rounded,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mission.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (mission.isChained)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7B1FA2,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF7B1FA2),
                                  ),
                                ),
                                child: const Text(
                                  'Bağlı Zincir',
                                  style: TextStyle(
                                    color: Color(0xFFE1BEE7),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              mission.description,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            if (mission.isChained &&
                                mission.nextMissionId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Tetikler: ${mission.nextMissionId}',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${mission.xpReward} XP',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (mission.pointsReward > 0)
                              Text(
                                '+${mission.pointsReward} Puan',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
