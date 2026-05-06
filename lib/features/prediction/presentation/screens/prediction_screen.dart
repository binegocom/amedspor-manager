import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/prediction_model.dart';
import '../../../../data/repositories/prediction_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class PredictionScreen extends StatefulWidget {
  final String matchId;

  const PredictionScreen({super.key, required this.matchId});

  static const String routePath = '/prediction/:matchId';

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  int amedScore = 2;
  int rivalScore = 1;
  String selectedScorer = 'Ahmet';

  final predictionRepository = PredictionRepository();
  final uuid = const Uuid();

  final List<String> scorers = const ['Ahmet', 'Baran', 'Rojhat', 'Serhat'];
  bool isSubmitting = false;

  bool get isLoggedIn => authService.currentUser != null;

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
                'Tahmin yapmak için giriş yapmalısın.',
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

  Future<void> _submitPrediction() async {
    if (isSubmitting) return;

    final user = authService.currentUser;

    if (user == null) {
      _showLoginRequired();
      return;
    }

    final prediction = PredictionModel(
      id: uuid.v4(),
      userId: user.uid,
      matchId: widget.matchId,
      homeScore: amedScore,
      awayScore: rivalScore,
      firstScorer: selectedScorer,
      pointsEarned: 0,
      createdAt: DateTime.now(),
    );

    setState(() => isSubmitting = true);

    try {
      await predictionRepository.savePrediction(prediction);
    } catch (_) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE53935),
          content: Text('Tahmin kaydedilemedi. Lutfen tekrar deneyin.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF0F6A3D),
        content: Text('Tahminin kaydedildi.'),
      ),
    );

    context.go('/predictions/me');
  }

  void _increaseAmed() {
    setState(() => amedScore++);
  }

  void _decreaseAmed() {
    if (amedScore == 0) return;
    setState(() => amedScore--);
  }

  void _increaseRival() {
    setState(() => rivalScore++);
  }

  void _decreaseRival() {
    if (rivalScore == 0) return;
    setState(() => rivalScore--);
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _MatchCard(),
                    const SizedBox(height: 18),
                    _DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skor Tahmini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _ScoreBox(
                                  team: 'Amedspor',
                                  score: amedScore,
                                  onMinus: _decreaseAmed,
                                  onPlus: _increaseAmed,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _ScoreBox(
                                  team: 'Altay',
                                  score: rivalScore,
                                  onMinus: _decreaseRival,
                                  onPlus: _increaseRival,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'İlk Golü Kim Atar?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RadioGroup<String>(
                            groupValue: selectedScorer,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => selectedScorer = value);
                            },
                            child: Column(
                              children: scorers
                                  .map(
                                    (player) => RadioListTile<String>(
                                      value: player,
                                      activeColor: const Color(0xFFE53935),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        player,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DarkCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Kazanılacak Puan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 12),
                          _PointRow(label: 'Doğru skor', point: '+50'),
                          _PointRow(label: 'Doğru galip', point: '+20'),
                          _PointRow(label: 'İlk golcü', point: '+30'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _submitPrediction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'TAHMİN YAP',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                      ),
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
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFE53935)),
          const SizedBox(width: 10),
          const Text(
            'Tahmin',
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

class _MatchCard extends StatelessWidget {
  const _MatchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6A3D), Color(0xFF111111)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFE53935),
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 14),
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
          Icon(Icons.sports_soccer_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String team;
  final int score;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  const _ScoreBox({
    required this.team,
    required this.score,
    required this.onMinus,
    required this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            team,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(icon: Icons.remove_rounded, onTap: onMinus),
              const SizedBox(width: 12),
              _CircleButton(icon: Icons.add_rounded, onTap: onPlus),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final String label;
  final String point;

  const _PointRow({required this.label, required this.point});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFB3B3B3))),
          const Spacer(),
          Text(
            point,
            style: const TextStyle(
              color: Color(0xFF0F6A3D),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkCard extends StatelessWidget {
  final Widget child;

  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
