import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/match_event_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class LiveMatchCenterScreen extends StatelessWidget {
  final String matchId;

  const LiveMatchCenterScreen({super.key, required this.matchId});

  static const String routePath = '/match-live/:matchId';

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: StreamBuilder<MatchModel?>(
        stream: matchRepository.watchMatch(matchId),
        builder: (context, matchSnapshot) {
          if (matchSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
          }

          final match = matchSnapshot.data;
          if (match == null) {
            return const Center(child: Text('Maç bulunamadı.', style: TextStyle(color: Colors.white)));
          }

          return SafeArea(
            child: Column(
              children: [
                PremiumHeader(
                  title: 'MAÇ MERKEZİ',
                  actions: [
                    _ChatAction(matchId: matchId),
                  ],
                ),
                _ScoreCenter(match: match),
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
                            stream: matchRepository.watchMatchEvents(matchId),
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
          );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryRed.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Text(
                '${match.minute}\'',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
              ),
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
              _TeamLarge(name: match.homeTeam),
              Column(
                children: [
                  Text(
                    '${match.homeScore} - ${match.awayScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              _TeamLarge(name: match.awayTeam),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamLarge extends StatelessWidget {
  final String name;

  const _TeamLarge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
          ),
          child: const Center(child: Icon(Icons.shield, color: AppColors.muted, size: 48)),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
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
