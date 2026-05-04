import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class LineupBuilderScreen extends StatefulWidget {
  final String matchId;

  const LineupBuilderScreen({super.key, required this.matchId});

  static const String routePath = '/lineup/:matchId';

  @override
  State<LineupBuilderScreen> createState() => _LineupBuilderScreenState();
}

class _LineupBuilderScreenState extends State<LineupBuilderScreen> {
  String selectedFormation = '4-3-3';

  final lineupRepository = LineupRepository();
  final uuid = const Uuid();

  final List<String> formations = const ['4-3-3', '4-2-3-1', '3-5-2', '4-4-2'];

  final List<_PlayerNodeData> players = const [
    _PlayerNodeData(name: 'Ahmet', top: 48, left: 150),
    _PlayerNodeData(name: 'Baran', top: 132, left: 58),
    _PlayerNodeData(name: 'Rojhat', top: 132, left: 242),
    _PlayerNodeData(name: 'Serhat', top: 210, left: 150),
    _PlayerNodeData(name: 'Azad', top: 294, left: 42),
    _PlayerNodeData(name: 'Deniz', top: 294, left: 122),
    _PlayerNodeData(name: 'Miran', top: 294, left: 205),
    _PlayerNodeData(name: 'Eren', top: 294, left: 286),
    _PlayerNodeData(name: 'Cemal', top: 382, left: 82),
    _PlayerNodeData(name: 'Ferhat', top: 382, left: 224),
    _PlayerNodeData(name: 'Mazlum', top: 462, left: 150),
  ];

  Future<void> _saveLineup() async {
    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    final lineup = LineupModel(
      id: uuid.v4(),
      userId: user.uid,
      matchId: widget.matchId,
      formation: selectedFormation,
      players: players.map((player) {
        return {'name': player.name, 'top': player.top, 'left': player.left};
      }).toList(),
      likes: 0,
      createdAt: DateTime.now(),
    );

    await lineupRepository.saveLineup(lineup);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F6A3D),
        content: Text('Kadron kaydedildi.'),
      ),
    );

    context.go('/lineups/me');
  }

  void _showLoginRequired() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFFE53935),
                size: 44,
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
                'Kadronu kaydetmek veya paylaşmak için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFB3B3B3), height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Vazgeç',
                  style: TextStyle(color: Color(0xFFB3B3B3)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerPicker(String playerName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Oyuncu Değiştir',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _PlayerPickerTile(name: playerName, selected: true),
              const _PlayerPickerTile(name: 'Mehmet', selected: false),
              const _PlayerPickerTile(name: 'Diyar', selected: false),
              const _PlayerPickerTile(name: 'Yusuf', selected: false),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.go('/home')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MatchInfoCard(),
                    const SizedBox(height: 18),
                    _PitchCard(
                      players: players,
                      onPlayerTap: _showPlayerPicker,
                    ),
                    const SizedBox(height: 18),
                    _FormationSelector(
                      value: selectedFormation,
                      formations: formations,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedFormation = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saveLineup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'KAYDET',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _showLoginRequired,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF0F6A3D),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'PAYLAŞ',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Text(
            'Kadro Kur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              '4-3-3',
              style: TextStyle(
                color: Color(0xFFB3B3B3),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  const _MatchInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          _SmallTeamLogo(label: 'A'),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amedspor vs Altay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '12 Mayıs • 20:00',
                  style: TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _SmallTeamLogo(label: 'AL'),
        ],
      ),
    );
  }
}

class _SmallTeamLogo extends StatelessWidget {
  final String label;

  const _SmallTeamLogo({required this.label});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: const Color(0xFF0F6A3D),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PitchCard extends StatelessWidget {
  final List<_PlayerNodeData> players;
  final ValueChanged<String> onPlayerTap;

  const _PitchCard({required this.players, required this.onPlayerTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F6A3D),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / 360;

          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
              ...players.map(
                (player) => Positioned(
                  top: player.top,
                  left: player.left * scaleX,
                  child: _PlayerNode(
                    name: player.name,
                    onTap: () => onPlayerTap(player.name),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerNode extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _PlayerNode({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE53935), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormationSelector extends StatelessWidget {
  final String value;
  final List<String> formations;
  final ValueChanged<String?> onChanged;

  const _FormationSelector({
    required this.value,
    required this.formations,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1A1A1A),
          iconEnabledColor: Colors.white,
          isExpanded: true,
          items: formations
              .map(
                (formation) => DropdownMenuItem(
                  value: formation,
                  child: Text(
                    'Formasyon: $formation',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PlayerPickerTile extends StatelessWidget {
  final String name;
  final bool selected;

  const _PlayerPickerTile({required this.name, required this.selected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: selected
            ? const Color(0xFFE53935)
            : const Color(0xFF0F6A3D),
        child: const Icon(Icons.person_rounded, color: Colors.white),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFE53935))
          : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      onTap: () => Navigator.pop(context),
    );
  }
}

class _PlayerNodeData {
  final String name;
  final double top;
  final double left;

  const _PlayerNodeData({
    required this.name,
    required this.top,
    required this.left,
  });
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
        const Radius.circular(20),
      ),
      linePaint,
    );

    canvas.drawLine(
      Offset(14, centerY),
      Offset(size.width - 14, centerY),
      linePaint,
    );

    canvas.drawCircle(Offset(size.width / 2, centerY), 54, linePaint);

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, 14, size.width * 0.5, 72),
      linePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height - 86, size.width * 0.5, 72),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
