import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LineupBuilderScreen extends StatefulWidget {
  final String matchId;

  const LineupBuilderScreen({
    super.key,
    required this.matchId,
  });

  static const String routePath = '/lineup/:matchId';

  @override
  State<LineupBuilderScreen> createState() => _LineupBuilderScreenState();
}

class _LineupBuilderScreenState extends State<LineupBuilderScreen> {
  final lineupRepository = LineupRepository();
  final uuid = const Uuid();

  String selectedFormation = '4-3-3';
  String? captainName;
  bool isSaving = false;

  final List<String> formations = const [
    '4-3-3',
    '4-2-3-1',
    '3-5-2',
    '4-4-2',
  ];

  final List<_Player> players = [
    _Player(name: 'Kaleci', position: 'GK', top: 0.84, left: 0.50),
    _Player(name: 'Sol Bek', position: 'DEF', top: 0.66, left: 0.18),
    _Player(name: 'Stoper 1', position: 'DEF', top: 0.68, left: 0.38),
    _Player(name: 'Stoper 2', position: 'DEF', top: 0.68, left: 0.62),
    _Player(name: 'Sağ Bek', position: 'DEF', top: 0.66, left: 0.82),
    _Player(name: 'Orta Saha 1', position: 'MID', top: 0.45, left: 0.30),
    _Player(name: 'Orta Saha 2', position: 'MID', top: 0.45, left: 0.50),
    _Player(name: 'Orta Saha 3', position: 'MID', top: 0.45, left: 0.70),
    _Player(name: 'Sol Kanat', position: 'FWD', top: 0.22, left: 0.22),
    _Player(name: 'Forvet', position: 'FWD', top: 0.18, left: 0.50),
    _Player(name: 'Sağ Kanat', position: 'FWD', top: 0.22, left: 0.78),
  ];

  int get lineupPower {
    final formationBonus = selectedFormation == '4-3-3' ? 8 : 5;
    final captainBonus = captainName == null ? 0 : 12;
    final filledPlayers = players.where((p) => !p.name.contains('Oyuncu')).length;

    return (filledPlayers * 6 + formationBonus + captainBonus).clamp(0, 100);
  }

  void _showLoginRequired() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFE53935),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Üyelik Gerekli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kadronu kaydetmek, paylaşmak ve puan kazanmak için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                Navigator.pop(sheetContext);
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'GİRİŞ YAP',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeFormation(String formation) {
    setState(() {
      selectedFormation = formation;

      if (formation == '4-3-3') {
        players[0] = players[0].copyWith(top: 0.84, left: 0.50);
        players[1] = players[1].copyWith(top: 0.66, left: 0.18);
        players[2] = players[2].copyWith(top: 0.68, left: 0.38);
        players[3] = players[3].copyWith(top: 0.68, left: 0.62);
        players[4] = players[4].copyWith(top: 0.66, left: 0.82);
        players[5] = players[5].copyWith(top: 0.45, left: 0.30);
        players[6] = players[6].copyWith(top: 0.45, left: 0.50);
        players[7] = players[7].copyWith(top: 0.45, left: 0.70);
        players[8] = players[8].copyWith(top: 0.22, left: 0.22);
        players[9] = players[9].copyWith(top: 0.18, left: 0.50);
        players[10] = players[10].copyWith(top: 0.22, left: 0.78);
      }

      if (formation == '4-2-3-1') {
        players[5] = players[5].copyWith(top: 0.50, left: 0.40);
        players[6] = players[6].copyWith(top: 0.50, left: 0.60);
        players[7] = players[7].copyWith(top: 0.35, left: 0.50);
        players[8] = players[8].copyWith(top: 0.28, left: 0.22);
        players[9] = players[9].copyWith(top: 0.16, left: 0.50);
        players[10] = players[10].copyWith(top: 0.28, left: 0.78);
      }

      if (formation == '3-5-2') {
        players[1] = players[1].copyWith(top: 0.66, left: 0.28);
        players[2] = players[2].copyWith(top: 0.68, left: 0.50);
        players[3] = players[3].copyWith(top: 0.66, left: 0.72);
        players[4] = players[4].copyWith(top: 0.48, left: 0.14);
        players[5] = players[5].copyWith(top: 0.45, left: 0.35);
        players[6] = players[6].copyWith(top: 0.42, left: 0.50);
        players[7] = players[7].copyWith(top: 0.45, left: 0.65);
        players[8] = players[8].copyWith(top: 0.48, left: 0.86);
        players[9] = players[9].copyWith(top: 0.18, left: 0.40);
        players[10] = players[10].copyWith(top: 0.18, left: 0.60);
      }

      if (formation == '4-4-2') {
        players[5] = players[5].copyWith(top: 0.46, left: 0.20);
        players[6] = players[6].copyWith(top: 0.46, left: 0.40);
        players[7] = players[7].copyWith(top: 0.46, left: 0.60);
        players[8] = players[8].copyWith(top: 0.46, left: 0.80);
        players[9] = players[9].copyWith(top: 0.18, left: 0.40);
        players[10] = players[10].copyWith(top: 0.18, left: 0.60);
      }
    });
  }

  void _openPlayerSheet(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        final suggestions = [
          'Oyuncu A',
          'Oyuncu B',
          'Oyuncu C',
          'Genç Yetenek',
          'Formda İsim',
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${players[index].position} Oyuncu Seç',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...suggestions.map(
                (name) => ListTile(
                  onTap: () {
                    setState(() {
                      players[index] = players[index].copyWith(name: name);
                    });
                  Navigator.pop(sheetContext);
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0F6A3D),
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    players[index].position,
                    style: const TextStyle(color: Color(0xFFB3B3B3)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLineup() async {
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    setState(() => isSaving = true);

    try {
      final lineup = LineupModel(
        id: uuid.v4(),
        userId: user.uid,
        matchId: widget.matchId,
        formation: selectedFormation,
        players: players.map((player) {
          return {
            'name': player.name,
            'position': player.position,
            'top': player.top,
            'left': player.left,
            'captain': player.name == captainName,
          };
        }).toList(),
        likes: 0,
        createdAt: DateTime.now(),
      );

      await lineupRepository.saveLineup(lineup);

      await firestoreService.users.doc(user.uid).update({
        'points': FieldValue.increment(10),
      });

      if (!mounted) return;

      _showResultSheet();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFE53935),
          content: Text('Kadro kaydetme hatası: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showResultSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFB300),
                size: 54,
              ),
              const SizedBox(height: 16),
              const Text(
                'Kadron Kaydedildi!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kadro gücü: $lineupPower/100 • +10 puan kazandın.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB3B3B3),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                Navigator.pop(sheetContext);
                    context.go('/lineups/me');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'KADROLARIMA GİT',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareLineup() {
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F6A3D),
        content: Text('Paylaşım sistemi bir sonraki adımda Feed’e bağlanacak.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () => context.go('/home'),
              matchId: widget.matchId,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: _PowerCard(
                power: lineupPower,
                formation: selectedFormation,
                captainName: captainName,
              ),
            ),

            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: formations.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final formation = formations[index];

                  return _FormationChip(
                    title: formation,
                    active: selectedFormation == formation,
                    onTap: () => _changeFormation(formation),
                  );
                },
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: _Pitch(
                  players: players,
                  captainName: captainName,
                  onPlayerTap: _openPlayerSheet,
                  onCaptainSelected: (name) {
                    setState(() => captainName = name);
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareLineup,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF0F6A3D)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text(
                        'PAYLAŞ',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _saveLineup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        isSaving ? 'KAYDEDİLİYOR' : 'KAYDET',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
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
  final String matchId;

  const _Header({
    required this.onBack,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFFE53935),
            child: Icon(Icons.sports_soccer_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Taraftar Teknik Direktör',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Maç ID: $matchId',
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerCard extends StatelessWidget {
  final int power;
  final String formation;
  final String? captainName;

  const _PowerCard({
    required this.power,
    required this.formation,
    required this.captainName,
  });

  @override
  Widget build(BuildContext context) {
    final color = power >= 80
        ? const Color(0xFF0F6A3D)
        : power >= 60
            ? const Color(0xFFFFB300)
            : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Icon(Icons.bolt_rounded, color: color, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kadro Gücü: $power/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: power / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Formasyon: $formation • Kaptan: ${captainName ?? 'Seçilmedi'}',
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormationChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _FormationChip({
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
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
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Pitch extends StatelessWidget {
  final List<_Player> players;
  final String? captainName;
  final ValueChanged<int> onPlayerTap;
  final ValueChanged<String> onCaptainSelected;

  const _Pitch({
    required this.players,
    required this.captainName,
    required this.onPlayerTap,
    required this.onCaptainSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F6A3D),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white24, width: 2),
          ),
          child: Stack(
            children: [
              const _PitchLines(),
              ...players.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;

                return Positioned(
                  top: constraints.maxHeight * player.top - 28,
                  left: constraints.maxWidth * player.left - 36,
                  child: _PlayerChip(
                    player: player,
                    isCaptain: captainName == player.name,
                    onTap: () => onPlayerTap(index),
                    onLongPress: () => onCaptainSelected(player.name),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PitchLines extends StatelessWidget {
  const _PitchLines();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PitchPainter(),
      size: Size.infinite,
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
      paint,
    );

    canvas.drawLine(
      Offset(18, size.height / 2),
      Offset(size.width - 18, size.height / 2),
      paint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      48,
      paint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 18),
        width: 150,
        height: 70,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 18),
        width: 150,
        height: 70,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerChip extends StatelessWidget {
  final _Player player;
  final bool isCaptain;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PlayerChip({
    required this.player,
    required this.isCaptain,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    isCaptain ? const Color(0xFFFFB300) : const Color(0xFFE53935),
                child: const Icon(Icons.person_rounded, color: Colors.white),
              ),
              if (isCaptain)
                const Positioned(
                  right: -6,
                  top: -6,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Text(
                      'C',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              player.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Player {
  final String name;
  final String position;
  final double top;
  final double left;

  const _Player({
    required this.name,
    required this.position,
    required this.top,
    required this.left,
  });

  _Player copyWith({
    String? name,
    String? position,
    double? top,
    double? left,
  }) {
    return _Player(
      name: name ?? this.name,
      position: position ?? this.position,
      top: top ?? this.top,
      left: left ?? this.left,
    );
  }
}