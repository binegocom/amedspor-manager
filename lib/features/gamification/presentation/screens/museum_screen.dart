import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/legend_model.dart';
import '../../../../shared/components/premium_card.dart';

class MuseumScreen extends StatelessWidget {
  const MuseumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final legends = [
      LegendModel(
        id: '1',
        name: 'Deniz Naki',
        role: 'Unutulmaz Forvet',
        rating: 92,
        imageUrl: '',
        story: 'Amedspor ruhunun sahadaki en büyük temsilcilerinden.',
        isUnlocked: true,
      ),
      LegendModel(
        id: '2',
        name: 'Şehmus Özer',
        role: 'Efsane Kaptan',
        rating: 95,
        imageUrl: '',
        story: 'Kaptan, lider ve her zaman kalbimizde.',
        isUnlocked: false,
      ),
      LegendModel(
        id: '3',
        name: 'Mansur Çalar',
        role: 'Orta Saha Dinamosu',
        rating: 89,
        imageUrl: '',
        story: 'Yıllarca formayı terleten, pes etmeyen karakter.',
        isUnlocked: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('EFSANELER MÜZESİ', style: AppTextStyles.h3),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: legends.length,
        itemBuilder: (context, index) {
          final legend = legends[index];
          return _LegendCard(legend: legend);
        },
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  final LegendModel legend;

  const _LegendCard({required this.legend});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 16),
      backgroundColor: legend.isUnlocked ? AppColors.surface : Colors.black45,
      child: Opacity(
        opacity: legend.isUnlocked ? 1.0 : 0.5,
        child: Row(
          children: [
            Container(
              width: 70,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.gold.withValues(alpha: 0.2), Colors.transparent],
                ),
              ),
              child: const Icon(Icons.person, color: AppColors.gold, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(legend.name, style: AppTextStyles.h3.copyWith(color: AppColors.gold)),
                  Text(legend.role, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    legend.story,
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!legend.isUnlocked)
              const Icon(Icons.lock_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
