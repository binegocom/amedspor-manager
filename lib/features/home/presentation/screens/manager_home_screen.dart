import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/app_user_model.dart';
import '../../../../data/models/club_model.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/match_event_model.dart';
import '../../../../data/repositories/club_repository.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../shared/components/login_required_modal.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/resource_bar.dart';

class ManagerHomeScreen extends ConsumerStatefulWidget {
  const ManagerHomeScreen({super.key});

  static const String routePath = '/home';

  @override
  ConsumerState<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends ConsumerState<ManagerHomeScreen> {
  final _clubNameController = TextEditingController(text: 'AMEDSPOR FC');
  final _managerNameController = TextEditingController();
  final _clubRepository = ClubRepository();
  final _userRepository = UserRepository();

  bool _isCreatingClub = false;

  @override
  void initState() {
    super.initState();
    final displayName = authService.currentUser?.displayName?.trim();
    _managerNameController.text = displayName?.isNotEmpty == true
        ? displayName!
        : 'Menajer';
  }

  @override
  void dispose() {
    _clubNameController.dispose();
    _managerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final clubAsync = ref.watch(currentClubStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        child: clubAsync.when(
          loading: () => const CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: _PanelLoadingCard(),
                ),
              ),
            ],
          ),
          error: (err, stack) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: _PanelErrorCard(
                    title: 'Kulüp bilgileri alınamadı',
                    message: '$err',
                  ),
                ),
              ),
            ],
          ),
          data: (club) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeTopBar(
                          club: club,
                          userId: user?.uid,
                          userRepository: _userRepository,
                        ),
                        const SizedBox(height: 18),
                        if (club == null)
                          _CreateClubCard(
                            clubNameController: _clubNameController,
                            managerNameController: _managerNameController,
                            isLoggedIn: user != null,
                            isLoading: _isCreatingClub,
                            onCreate: user == null
                                ? () => showLoginRequiredModal(context)
                                : () => _handleCreateClub(user.uid),
                          )
                        else
                          _ManagerDashboard(club: club),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleCreateClub(String userId) async {
    if (_isCreatingClub) return;

    final clubName = _clubNameController.text.trim();
    final managerName = _managerNameController.text.trim();

    if (clubName.length < 3 || managerName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kulüp ve menajer adını eksiksiz yaz.')),
      );
      return;
    }

    final newClub = ClubModel(
      id: userId,
      name: clubName,
      managerName: managerName,
      createdAt: DateTime.now(),
      lastResourceUpdate: DateTime.now(),
    );

    setState(() => _isCreatingClub = true);

    try {
      await _clubRepository.createClub(newClub);
      await _userRepository.markClubCreated(userId, newClub.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kulübün oluşturuldu.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kulüp oluşturulamadı: $error')));
    } finally {
      if (mounted) {
        setState(() => _isCreatingClub = false);
      }
    }
  }
}

class _HomeTopBar extends StatelessWidget {
  final ClubModel? club;
  final String? userId;
  final UserRepository userRepository;

  const _HomeTopBar({
    required this.club,
    required this.userId,
    required this.userRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: club == null
              ? const _BrandHeader()
              : _ClubSummaryHeader(
                  club: club!,
                  userId: userId,
                  userRepository: userRepository,
                ),
        ),
        const SizedBox(width: 12),
        _HeaderIcon(
          icon: Icons.dynamic_feed_rounded,
          onTap: () => context.go('/feed'),
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.forum_rounded,
          onTap: () => context.go('/chat/general'),
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.search_rounded,
          onTap: () => context.go('/search'),
        ),
        const SizedBox(width: 8),
        _HeaderIcon(
          icon: Icons.notifications_none_rounded,
          onTap: () => context.go('/notifications'),
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Image.asset('assets/images/app_icon.png'),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amedspor Panel', style: AppTextStyles.h3),
              SizedBox(height: 2),
              Text(
                'Menajer kariyerine başla',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubSummaryHeader extends StatelessWidget {
  final ClubModel club;
  final String? userId;
  final UserRepository userRepository;

  const _ClubSummaryHeader({
    required this.club,
    required this.userId,
    required this.userRepository,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Image.asset('assets/images/app_icon.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              club.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelBadge(level: club.reputation),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menajer: ${club.managerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              FutureBuilder<AppUserModel?>(
                future: userId != null ? userRepository.getUser(userId!) : null,
                builder: (context, snapshot) {
                  return ResourceBar(
                    tokens: club.tokens,
                    cash: club.cash,
                    energy: snapshot.data?.energy ?? 100,
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ManagerDashboard extends ConsumerWidget {
  final ClubModel club;

  const _ManagerDashboard({required this.club});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroOverview(club: club),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'SIRADAKİ MAÇ'),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const _PanelLoadingCard(compact: true),
          error: (err, stack) => _PanelErrorCard(
            title: 'Maç bilgisi alınamadı',
            message: '$err',
          ),
          data: (matches) => _NextMatchCard(match: _pickNextMatch(matches)),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'KULÜP DURUMU'),
        const SizedBox(height: 12),
        _ClubStatusGrid(club: club),
      ],
    );
  }

  MatchModel? _pickNextMatch(List<MatchModel> matches) {
    final now = DateTime.now();
    final active = matches.where((match) => !match.isFinished).toList()
      ..sort((a, b) {
        if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
        return a.matchDate.compareTo(b.matchDate);
      });

    final upcoming = active
        .where((match) => match.matchDate.isAfter(now))
        .toList();
    if (upcoming.isNotEmpty) return upcoming.first;
    if (active.isNotEmpty) return active.first;
    if (matches.isNotEmpty) return matches.first;
    return null;
  }
}

class _HeroOverview extends StatelessWidget {
  final ClubModel club;

  const _HeroOverview({required this.club});

  @override
  Widget build(BuildContext context) {
    final reputationProgress = (club.reputation / 10).clamp(0.0, 1.0);

    return PremiumCard(
      backgroundColor: AppColors.card,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MENAJER MERKEZİ',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      club.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${club.fans} taraftar seni takip ediyor',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _ScoreRing(value: club.reputation, label: 'İtibar'),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: reputationProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextMatchCard extends StatelessWidget {
  final MatchModel? match;

  const _NextMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    if (match == null) {
      return PremiumCard(
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const _EmptyPanelMessage(
              icon: Icons.event_busy_rounded,
              title: 'Planlanmış maç yok',
              message: 'Fikstür eklendiğinde hazırlık aksiyonları burada görünür.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: '🔴 CANLI MERKEZ',
                    height: 44,
                    type: AppButtonType.primary,
                    onTap: () async {
                      final matchRepo = MatchRepository();
                      final newMatch = MatchModel(
                        id: 'derbi_canli',
                        homeTeam: 'Amedspor',
                        awayTeam: 'Diyarbekirspor',
                        homeLogo: '',
                        awayLogo: '',
                        matchDate: DateTime.now(),
                        status: 'live',
                        homeScore: 2,
                        awayScore: 1,
                        minute: 68,
                        motmCandidates: ['Deniz Naki', 'Şehmus Özer', 'Mansur Çalar'],
                        isMotmVotingActive: true,
                        motmResults: {'Deniz Naki': 15, 'Şehmus Özer': 42, 'Mansur Çalar': 8},
                      );
                      await matchRepo.createMatch(newMatch);

                      await matchRepo.addMatchEvent(
                        matchId: 'derbi_canli',
                        event: MatchEventModel(
                          id: 'ev1',
                          type: 'goal',
                          minute: 34,
                          team: 'home',
                          playerName: 'Deniz Naki',
                          description: 'Ceza sahası dışından harika bir şut!',
                          createdAt: DateTime.now(),
                        ),
                      );
                      await matchRepo.addMatchEvent(
                        matchId: 'derbi_canli',
                        event: MatchEventModel(
                          id: 'ev2',
                          type: 'goal',
                          minute: 52,
                          team: 'home',
                          playerName: 'Şehmus Özer',
                          description: 'Kafa vuruşuyla topu ağlara gönderdi.',
                          createdAt: DateTime.now(),
                        ),
                      );

                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.primaryGreen,
                          content: Text('Canlı Derbi Merkezi aktif edildi!'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: '🎮 2D SİMÜLASYON',
                    height: 44,
                    type: AppButtonType.secondary,
                    onTap: () => context.push('/match-simulation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final isLive = match!.isLive;

    return PremiumCard(
      backgroundColor: AppColors.card,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _TeamMini(name: match!.homeTeam, logo: match!.homeLogo),
              Expanded(
                child: Column(
                  children: [
                    _StatusPill(
                      text: isLive
                          ? 'CANLI ${match!.minute}\''
                          : _formatDate(match!.matchDate),
                      color: isLive
                          ? AppColors.primaryRed
                          : AppColors.primaryGreen,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isLive
                          ? '${match!.homeScore} - ${match!.awayScore}'
                          : 'VS',
                      style: AppTextStyles.h1,
                    ),
                  ],
                ),
              ),
              _TeamMini(name: match!.awayTeam, logo: match!.awayLogo),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: isLive ? 'CANLI MERKEZ' : 'MAÇA HAZIRLAN',
                  height: 48,
                  onTap: () => isLive
                      ? context.push('/match-live/${match!.id}')
                      : context.push('/match-simulation'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 52,
                child: AppButton(
                  text: '',
                  height: 48,
                  icon: Icons.list_alt_rounded,
                  type: AppButtonType.secondary,
                  onTap: () => context.push('/match-report/${match!.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    if (sameDay) return 'BUGÜN $hour:$minute';
    return '${date.day}.${date.month}.${date.year} $hour:$minute';
  }
}

class _TeamMini extends StatelessWidget {
  final String name;
  final String logo;

  const _TeamMini({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Takım' : name;

    return SizedBox(
      width: 94,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: logo.isNotEmpty
                ? Image.network(
                    logo,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.shield_rounded,
                      color: AppColors.muted,
                    ),
                  )
                : const Icon(Icons.shield_rounded, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubStatusGrid extends StatelessWidget {
  final ClubModel club;

  const _ClubStatusGrid({required this.club});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatusItem('Taraftar', '${club.fans}', Icons.people_alt_rounded),
      _StatusItem('Stadyum', 'LVL ${club.stadiumLevel}', Icons.stadium_rounded),
      _StatusItem(
        'Antrenman',
        'LVL ${club.trainingLevel}',
        Icons.fitness_center_rounded,
      ),
      _StatusItem(
        'Sağlık',
        'LVL ${club.medicalLevel}',
        Icons.health_and_safety_rounded,
      ),
      _StatusItem(
        'Bütçe',
        _formatCash(club.cash),
        Icons.account_balance_wallet_rounded,
      ),
      _StatusItem('Token', '${club.tokens}', Icons.monetization_on_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) => _StatusTile(item: stats[index]),
        );
      },
    );
  }

  String _formatCash(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }
}

class _StatusItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatusItem(this.label, this.value, this.icon);
}

class _StatusTile extends StatelessWidget {
  final _StatusItem item;

  const _StatusTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(item.icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateClubCard extends StatelessWidget {
  final TextEditingController clubNameController;
  final TextEditingController managerNameController;
  final bool isLoggedIn;
  final bool isLoading;
  final VoidCallback onCreate;

  const _CreateClubCard({
    required this.clubNameController,
    required this.managerNameController,
    required this.isLoggedIn,
    required this.isLoading,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PremiumCard(
          backgroundColor: AppColors.card,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.sports_soccer_rounded,
                    color: AppColors.primaryGreen,
                    size: 34,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('KULÜBÜNÜ KUR', style: AppTextStyles.h2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Menajer merkezini açmak için kulüp adını ve menajer profilini oluştur.',
                style: TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Kulüp adı',
                hint: 'AMEDSPOR FC',
                controller: clubNameController,
                icon: Icons.shield_rounded,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Menajer adı',
                hint: 'Menajer',
                controller: managerNameController,
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 18),
              AppButton(
                text: isLoggedIn ? 'KULÜBÜ OLUŞTUR' : 'GİRİŞ YAP',
                onTap: onCreate,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _StarterChecklist(),
      ],
    );
  }
}

class _StarterChecklist extends StatelessWidget {
  const _StarterChecklist();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Başlangıç bütçesi', '10K nakit'),
      ('Taraftar kitlesi', '100 kişi'),
      ('Tesis seviyesi', 'Seviye 1'),
    ];

    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].$1,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                Text(
                  items[i].$2,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (i != items.length - 1)
              const Divider(color: Colors.white10, height: 22),
          ],
        ],
      ),
    );
  }
}

class _PanelLoadingCard extends StatelessWidget {
  final bool compact;

  const _PanelLoadingCard({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: SizedBox(
        height: compact ? 92 : 150,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      ),
    );
  }
}

class _PanelErrorCard extends StatelessWidget {
  final String title;
  final String message;

  const _PanelErrorCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: _EmptyPanelMessage(
        icon: Icons.error_outline_rounded,
        title: title,
        message: message,
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyPanelMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.muted, size: 34),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final int value;
  final String label;

  const _ScoreRing({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
          width: 2,
        ),
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Text(
        'LVL $level',
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
