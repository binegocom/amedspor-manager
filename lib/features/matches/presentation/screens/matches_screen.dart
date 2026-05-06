import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../shared/components/app_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_header.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/repositories/match_repository.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  static const String routePath = '/matches';

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _selectedSegment = 0; // 0: Yaklaşan, 1: Canlı, 2: Biten

  @override
  Widget build(BuildContext context) {
    final matchRepository = MatchRepository();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(title: 'MAÇLAR', showBackButton: false),
            const SizedBox(height: 8),
            _SegmentedControl(
              selectedIndex: _selectedSegment,
              onChanged: (index) => setState(() => _selectedSegment = index),
            ),
            Expanded(
              child: StreamBuilder<List<MatchModel>>(
                stream: matchRepository.watchMatches(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
                  }

                  final allMatches = snapshot.data ?? [];
                  final filteredMatches = allMatches.where((m) {
                    if (_selectedSegment == 0) return m.status == 'upcoming';
                    if (_selectedSegment == 1) return m.status == 'live';
                    return m.status == 'finished';
                  }).toList();

                  if (filteredMatches.isEmpty) {
                    return Center(
                      child: Text(
                        'Bu kategoride maç bulunamadı.',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredMatches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _MatchListItem(match: filteredMatches[index]),
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

class _SegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final segments = ['YAKLAŞAN', 'CANLI', 'BİTEN'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  segments[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MatchListItem extends StatelessWidget {
  final MatchModel match;

  const _MatchListItem({required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.status == 'live';
    final isFinished = match.status == 'finished';

    return AppCard(
      onTap: () => context.push('/match-live/${match.id}'),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TeamMini(name: match.homeTeam),
              Column(
                children: [
                  if (isLive || isFinished)
                    Text('${match.homeScore} - ${match.awayScore}', style: AppTextStyles.h2)
                  else
                    const Text('VS', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryRed, borderRadius: BorderRadius.circular(4)),
                      child: Text('${match.minute}\'', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else
                    Text(
                      isFinished ? 'MAÇ SONUCU' : '19:00',
                      style: AppTextStyles.label.copyWith(fontSize: 10),
                    ),
                ],
              ),
              _TeamMini(name: match.awayTeam),
            ],
          ),
          if (!isFinished) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'KADRO KUR',
                    type: AppButtonType.secondary,
                    onTap: () => context.go('/lineup/${match.id}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'TAHMİN',
                    type: AppButtonType.outline,
                    onTap: () => context.go('/prediction/${match.id}'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamMini extends StatelessWidget {
  final String name;

  const _TeamMini({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: const Center(child: Icon(Icons.shield, color: AppColors.muted, size: 24)),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
