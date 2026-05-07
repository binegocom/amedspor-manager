import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/premium_header.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const PremiumHeader(title: 'FİKSTÜR'),
            Expanded(
              child: StreamBuilder<List<MatchModel>>(
                stream: matchRepository.watchMatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                  }

                  final matches = snapshot.data ?? [];
                  if (matches.isEmpty) {
                    return const Center(child: Text('Henüz maç bilgisi bulunmuyor.', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _MatchCard(match: matches[index]);
                    },
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

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'live';

    return PremiumCard(
      onTap: () => context.push('/match-live/${match.id}'),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLive) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text('CANLI', style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
              ] else
                Text(
                  match.status == 'finished' ? 'BİTTİ' : 'GELECEK MAÇ',
                  style: AppTextStyles.label,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TeamMini(name: match.homeTeam, logo: match.homeLogo)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  match.status == 'upcoming' ? 'VS' : '${match.homeScore} - ${match.awayScore}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(child: _TeamMini(name: match.awayTeam, logo: match.awayLogo)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${match.matchDate.day}.${match.matchDate.month}.${match.matchDate.year} - ${match.matchDate.hour}:${match.matchDate.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String name;
  final String logo;
  const _TeamMini({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
          child: logo.isNotEmpty 
            ? Image.network(logo, fit: BoxFit.contain)
            : const Icon(Icons.shield, color: AppColors.muted, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
