import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/match_event_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../../../../data/services/gamification_service.dart';

class LiveMatchCenterScreen extends StatefulWidget {
  final String matchId;

  const LiveMatchCenterScreen({super.key, required this.matchId});

  static const String routePath = '/match-live/:matchId';

  @override
  State<LiveMatchCenterScreen> createState() => _LiveMatchCenterScreenState();
}

class _LiveMatchCenterScreenState extends State<LiveMatchCenterScreen> {
  @override
  void initState() {
    super.initState();
    _awardLiveMatchXp();
  }

  Future<void> _awardLiveMatchXp() async {
    final user = authService.currentUser;
    if (user != null) {
      await GamificationService().awardXp(
        userId: user.uid,
        amount: GamificationService.xpLiveMatchOpened,
        reason: 'Canlı maçı takip ettiğin için',
        eventType: 'live_match_opened',
        sourceType: 'match',
        sourceId: widget.matchId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: StreamBuilder<MatchModel?>(
        stream: matchRepository.watchMatch(widget.matchId),
        builder: (context, matchSnapshot) {
          if (matchSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
          }

          final match = matchSnapshot.data;
          if (match == null) {
            return const Center(child: Text('Maç bulunamadı.', style: TextStyle(color: Colors.white)));
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.liveMatchTurfGradient,
            ),
            child: SafeArea(
            child: Column(
              children: [
                PremiumHeader(
                  title: 'MAÇ MERKEZİ',
                  actions: [
                    _ChatAction(matchId: widget.matchId),
                  ],
                ),
                _ScoreCenter(match: match),
                _HypeMeterWidget(match: match, matchRepository: matchRepository),
                if (match.isMotmVotingActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _MotmVoting(match: match, matchRepository: matchRepository),
                  ),
                const SizedBox(height: 32),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Text('MAÇ HİKAYESİ', style: AppTextStyles.label),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<List<MatchEventModel>>(
                            stream: matchRepository.watchMatchEvents(widget.matchId),
                            builder: (context, eventSnapshot) {
                              final events = eventSnapshot.data ?? [];
                              if (events.isEmpty) {
                                return const Center(
                                  child: Text('Henüz bir olay gerçekleşmedi.',
                                      style: TextStyle(color: Colors.white38)),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                itemCount: events.length,
                                itemBuilder: (context, index) {
                                  return _EventTile(event: events[index]);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }
}

class _ChatAction extends StatelessWidget {
  final String matchId;
  const _ChatAction({required this.matchId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/chat/$matchId'),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryGreen, size: 20),
      ),
    );
  }
}

class _ScoreCenter extends StatelessWidget {
  final MatchModel match;

  const _ScoreCenter({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'live';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          if (isLive)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, val, child) {
                final double glow = (val > 0.5 ? 1.0 - val : val) * 2.0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryRed.withValues(alpha: 0.2 + (glow * 0.4)),
                        blurRadius: 8 + (glow * 8),
                        spreadRadius: 1 + (glow * 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${match.minute}\'',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            )
          else
            Text(
              match.status == 'finished' ? 'MAÇ SONUCU' : 'YAKLAŞAN MAÇ',
              style: AppTextStyles.label,
            ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _TeamLarge(name: match.homeTeam, logo: match.homeLogo)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Expanded(child: _TeamLarge(name: match.awayTeam, logo: match.awayLogo)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamLarge extends StatelessWidget {
  final String name;
  final String? logo;

  const _TeamLarge({required this.name, this.logo});

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? 'Takım' : name;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
          ),
          child: logo != null && logo!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logo!,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.shield,
                    color: AppColors.muted,
                    size: 40,
                  ),
                )
              : const Center(child: Icon(Icons.shield, color: AppColors.muted, size: 40)),
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MotmVoting extends StatefulWidget {
  final MatchModel match;
  final MatchRepository matchRepository;

  const _MotmVoting({required this.match, required this.matchRepository});

  @override
  State<_MotmVoting> createState() => _MotmVotingState();
}

class _MotmVotingState extends State<_MotmVoting> {
  String? selectedPlayer;
  String? votedPlayer;
  bool isVoting = false;
  bool hasVoted = false;

  @override
  void initState() {
    super.initState();
    _checkIfVoted();
  }

  Future<void> _checkIfVoted() async {
    final user = authService.currentUser;
    if (user == null) return;

    final vote = await widget.matchRepository.getUserMotmVote(widget.match.id, user.uid);
    if (vote != null && mounted) {
      setState(() {
        votedPlayer = vote;
        hasVoted = true;
      });
    }
  }

  Future<void> _vote() async {
    if (selectedPlayer == null || isVoting) return;

    final user = authService.currentUser;
    if (user == null) {
      context.push('/login');
      return;
    }

    setState(() => isVoting = true);

    final success = await widget.matchRepository.voteForMotm(
      matchId: widget.match.id,
      userId: user.uid,
      candidate: selectedPlayer!,
    );

    if (mounted) {
      setState(() {
        isVoting = false;
        if (success) {
          votedPlayer = selectedPlayer;
          hasVoted = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = widget.match.motmResults.values.fold(0, (sum, v) => sum + v);

    return PremiumCard(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Text('MAÇIN ADAMI OYLAMASI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              const Spacer(),
              if (hasVoted) const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Doğru tahmine anında +250 XP ve Nakit Bonus!',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (hasVoted)
            ...widget.match.motmCandidates.map((player) {
              final votes = widget.match.motmResults[player] ?? 0;
              final percent = totalVotes > 0 ? (votes / totalVotes) : 0.0;
              final isVoted = player == votedPlayer;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(player, style: TextStyle(color: isVoted ? Colors.white : AppColors.muted, fontWeight: isVoted ? FontWeight.bold : FontWeight.normal)),
                        Text('%${(percent * 100).toInt()}', style: AppTextStyles.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.white10,
                        color: isVoted ? AppColors.primaryGreen : AppColors.muted.withValues(alpha: 0.2),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.match.motmCandidates.map((player) {
                    final isSelected = selectedPlayer == player;
                    return ChoiceChip(
                      label: Text(player),
                      selected: isSelected,
                      onSelected: (val) => setState(() => selectedPlayer = val ? player : null),
                      backgroundColor: AppColors.darkBackground,
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.muted, fontSize: 12),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'OY VER',
                  isLoading: isVoting,
                  onTap: selectedPlayer != null ? _vote : null,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final MatchEventModel event;

  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (event.type) {
      case 'goal':
        iconData = Icons.sports_soccer;
        iconColor = AppColors.primaryGreen;
        break;
      case 'yellowCard':
        iconData = Icons.square;
        iconColor = AppColors.gold;
        break;
      case 'redCard':
        iconData = Icons.square;
        iconColor = AppColors.primaryRed;
        break;
      case 'substitution':
        iconData = Icons.swap_vert_circle;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.info;
        iconColor = AppColors.muted;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text('${event.minute}\'', style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Icon(iconData, color: iconColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                if (event.type == 'substitution' && event.playerNameOut != null)
                  Text('Çıkan: ${event.playerNameOut}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                if (event.description.isNotEmpty)
                  Text(event.description, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HypeMeterWidget extends StatefulWidget {
  final MatchModel match;
  final MatchRepository matchRepository;

  const _HypeMeterWidget({required this.match, required this.matchRepository});

  @override
  State<_HypeMeterWidget> createState() => _HypeMeterWidgetState();
}

class _HypeMeterWidgetState extends State<_HypeMeterWidget> with TickerProviderStateMixin {
  int _pendingHypeCount = 0;
  int _sessionTaps = 0;
  bool _isFlashing = false;
  final List<_HypeBubble> _bubbles = [];
  int _bubbleCounter = 0;

  void _triggerHypeTap() {
    setState(() {
      _pendingHypeCount++;
      _sessionTaps++;
      _isFlashing = true;

      final bubbleId = _bubbleCounter++;
      final double offset = ((_sessionTaps % 5) - 2) * 25.0;
      _bubbles.add(_HypeBubble(id: bubbleId, startX: offset, text: '+1 HYPE 🔥'));
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isFlashing = false);
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _bubbles.removeWhere((b) => b.id == _bubbleCounter - 1 || true);
          // Let's pop oldest or let's clean safely to avoid reference issues
          if (_bubbles.isNotEmpty) _bubbles.removeAt(0);
        });
      }
    });

    _commitBatchHype();

    if (_sessionTaps % 25 == 0) {
      final user = authService.currentUser;
      if (user != null) {
        GamificationService().awardXp(
          userId: user.uid,
          amount: 50,
          reason: 'Tribün Hype Patlaması!',
          eventType: 'tribune_hype_reward',
          sourceType: 'match_hype',
          sourceId: widget.match.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.gold,
            content: Text('🔥 Hype Serisi: +50 XP Kazandın!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  void _commitBatchHype() {
    if (_pendingHypeCount > 0) {
      final toCommit = _pendingHypeCount;
      _pendingHypeCount = 0;
      widget.matchRepository.incrementHypeScore(widget.match.id, toCommit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentHype = widget.match.hypeScore;
    int targetGoal = 5000;
    if (currentHype >= 5000) targetGoal = 25000;
    if (currentHype >= 25000) targetGoal = 100000;

    final double progress = (currentHype / targetGoal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            _isFlashing ? AppColors.primaryRed.withValues(alpha: 0.25) : AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFlashing ? AppColors.primaryRed : AppColors.white.withValues(alpha: 0.08),
          width: _isFlashing ? 2 : 1,
        ),
        boxShadow: [
          if (_isFlashing)
            BoxShadow(
              color: AppColors.primaryRed.withValues(alpha: 0.3),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primaryRed, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'TARAFTAR HYPE METRE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Hedef: $targetGoal',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 22,
                  backgroundColor: Colors.black26,
                  color: AppColors.primaryRed,
                ),
              ),
              Positioned(
                child: Text(
                  '$currentHype / $targetGoal HYPE',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ..._bubbles.map((b) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(b.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, val, child) {
                      return Positioned(
                        bottom: 20 + (val * 40),
                        left: (MediaQuery.of(context).size.width / 2) - 80 + b.startX,
                        child: Opacity(
                          opacity: (1.0 - val).clamp(0.0, 1.0),
                          child: Text(
                            b.text,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                ElevatedButton.icon(
                  onPressed: _triggerHypeTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.bolt_rounded, color: AppColors.gold),
                  label: const Text(
                    'TİTRET & HYPE PATLAT 🔥',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
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

class _HypeBubble {
  final int id;
  final double startX;
  final String text;

  _HypeBubble({required this.id, required this.startX, required this.text});
}
