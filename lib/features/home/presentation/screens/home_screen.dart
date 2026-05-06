import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routePath = '/home';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),

              const SizedBox(height: 24),

              StreamBuilder<List<MatchModel>>(
                stream: matchRepository.watchMatches(),
                builder: (context, snapshot) {
                  final matches = snapshot.data ?? [];

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    );
                  }

                  if (matches.isEmpty) {
                    return const _DarkCard(
                      child: Text(
                        'Henüz maç eklenmedi.',
                        style: TextStyle(color: Color(0xFFB3B3B3)),
                      ),
                    );
                  }

                  final match = matches.first;

                  return _MatchCard(
                    match: match,
                    onLineup: () => context.go('/lineup/${match.id}'),
                    onPrediction: () => context.go('/prediction/${match.id}'),
                  );
                },
              ),

              const SizedBox(height: 18),

              const _QuestionCard(),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Aktif Sohbetler'),
              const SizedBox(height: 10),
              _ChatRoomTile(
                title: 'Genel Sohbet',
                users: '124 aktif',
                onTap: () => context.go('/chat/general'),
              ),
              _ChatRoomTile(
                title: 'Maç Günü',
                users: '89 aktif',
                onTap: () => context.go('/chat/matchday'),
              ),
              _ChatRoomTile(
                title: 'Transfer',
                users: '36 aktif',
                onTap: () => context.go('/chat/transfer'),
              ),

              const SizedBox(height: 18),

              const _SectionTitle(title: 'Trend Yorum'),
              const SizedBox(height: 10),
              const _TrendPost(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.notifications_none_rounded, color: Colors.white),
        const Spacer(),
        const Text(
          'AMEDSPOR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onLineup;
  final VoidCallback onPrediction;

  const _MatchCard({
    required this.match,
    required this.onLineup,
    required this.onPrediction,
  });

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${match.matchDate.day}.${match.matchDate.month}.${match.matchDate.year}';

    final timeText =
        '${match.matchDate.hour.toString().padLeft(2, '0')}:${match.matchDate.minute.toString().padLeft(2, '0')}';

    return Container(
      height: 260,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text(
            'Haftanın Maçı',
            style: TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamBadge(name: match.homeTeam),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _TeamBadge(name: match.awayTeam),
            ],
          ),
          const Spacer(),
          Text(
            '$dateText • $timeText',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: onLineup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'KADRO KUR',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: onPrediction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF0F6A3D)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'TAHMİN YAP',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamBadge extends StatelessWidget {
  final String name;

  const _TeamBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE53935), width: 2),
          ),
          child: Center(
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard();

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool? answer;

  void _vote(bool value) {
    setState(() => answer = value);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F6A3D),
        content: Text(
          value ? 'Oyun kaydedildi: Evet' : 'Oyun kaydedildi: Hayir',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 Bugünün Sorusu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Bu hafta çift forvet oynamalı mıyız?',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _vote(true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F6A3D),
                    side: const BorderSide(color: Color(0xFF0F6A3D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(answer == true ? 'EVET ✓' : 'EVET'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _vote(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(answer == false ? 'HAYIR ✓' : 'HAYIR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  final String title;
  final String users;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.title,
    required this.users,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _DarkCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0F6A3D),
          child: Icon(Icons.forum_rounded, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(users, style: const TextStyle(color: Color(0xFFB3B3B3))),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white),
      ),
    );
  }
}

class _TrendPost extends StatelessWidget {
  const _TrendPost();

  @override
  Widget build(BuildContext context) {
    return const _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@tribunlideri',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bu hafta erken pres yaparsak maç bizim olur.',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          SizedBox(height: 12),
          Text('👍 120 beğeni', style: TextStyle(color: Color(0xFFB3B3B3))),
        ],
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
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;

  const _DarkCard({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
