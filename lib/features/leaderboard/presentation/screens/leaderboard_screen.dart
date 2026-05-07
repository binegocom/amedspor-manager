import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/app_user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  static const String routePath = '/leaderboard';

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedTab = 'Haftalık';

  final List<String> tabs = const ['Haftalık', 'Aylık', 'Genel'];

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFB300);
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFB87333);
    return const Color(0xFF0F6A3D);
  }

  @override
  Widget build(BuildContext context) {
    final userRepository = UserRepository();
    final currentUser = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/profile')),

            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final tab = tabs[index];

                  return _TabChip(
                    title: tab,
                    active: selectedTab == tab,
                    onTap: () => setState(() => selectedTab = tab),
                  );
                },
              ),
            ),

            Expanded(
              child: StreamBuilder<List<AppUserModel>>(
                stream: userRepository.watchLeaderboard(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  final users = snapshot.data ?? [];

                  if (users.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz sıralama verisi yok.',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  // Firestore already returns sorted by points via watchLeaderboard()

                  final topThree = users.take(3).toList();
                  final rest = users.skip(3).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    children: [
                      if (topThree.isNotEmpty)
                        _PodiumCard(
                          users: topThree,
                          rankColor: _rankColor,
                          onUserTap: (user) {
                            if (currentUser != null &&
                                user.id == currentUser.uid) {
                              context.go('/profile');
                            } else {
                              context.go('/profile/${user.id}');
                            }
                          },
                        ),

                      const SizedBox(height: 22),

                      const Text(
                        'Tüm Taraftarlar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...rest.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        final rank = index + 4;

                        return _LeaderTile(
                          user: user,
                          rank: rank,
                          color: _rankColor(rank),
                          isMe:
                              currentUser != null && user.id == currentUser.uid,
                          onTap: () {
                            if (currentUser != null &&
                                user.id == currentUser.uid) {
                              context.go('/profile');
                            } else {
                              context.go('/profile/${user.id}');
                            }
                          },
                        );
                      }),
                    ],
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Icon(Icons.leaderboard_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Liderlik Tablosu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F6A3D) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? const Color(0xFF0F6A3D) : Colors.white10,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFFB3B3B3),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final List<AppUserModel> users;
  final Color Function(int rank) rankColor;
  final ValueChanged<AppUserModel> onUserTap;

  const _PodiumCard({
    required this.users,
    required this.rankColor,
    required this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final show2 = users.length > 1;
    final show3 = users.length > 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: show2 ? _PodiumUser(
              user: users[1],
              rank: 2,
              height: 112,
              color: rankColor(2),
              onTap: () => onUserTap(users[1]),
            ) : const SizedBox(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PodiumUser(
              user: users[0],
              rank: 1,
              height: 144,
              color: rankColor(1),
              onTap: () => onUserTap(users[0]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: show3 ? _PodiumUser(
              user: users[2],
              rank: 3,
              height: 96,
              color: rankColor(3),
              onTap: () => onUserTap(users[2]),
            ) : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _PodiumUser extends StatelessWidget {
  final AppUserModel user;
  final int rank;
  final double height;
  final Color color;
  final VoidCallback onTap;

  const _PodiumUser({
    required this.user,
    required this.rank,
    required this.height,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: rank == 1 ? 34 : 28,
            backgroundColor: color,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            username,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${user.xp.toInt()} XP',
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.7)),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: color,
              size: rank == 1 ? 42 : 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  final AppUserModel user;
  final int rank;
  final Color color;
  final bool isMe;
  final VoidCallback onTap;

  const _LeaderTile({
    required this.user,
    required this.rank,
    required this.color,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = user.username.startsWith('@')
        ? user.username
        : '@${user.username}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF202020) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isMe ? const Color(0xFFE53935) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'L${user.level}',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    user.levelTitle,
                    style: const TextStyle(
                      color: Color(0xFFB3B3B3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${user.xp.toInt()}',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'XP',
              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
