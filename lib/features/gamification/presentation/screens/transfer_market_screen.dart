import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';

class TransferMarketScreen extends StatelessWidget {
  const TransferMarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        title: const Text('TRANSFER PAZARI', style: AppTextStyles.h3),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MarketItem(name: 'Deniz Naki (Efsane)', rating: 88, price: 500000, position: 'FWD'),
          const SizedBox(height: 16),
          _MarketItem(name: 'Mansur Çalar', rating: 82, price: 250000, position: 'MID'),
          const SizedBox(height: 16),
          _MarketItem(name: 'Şehmus Özer (Efsane)', rating: 90, price: 750000, position: 'FWD'),
        ],
      ),
    );
  }
}

class _MarketItem extends StatelessWidget {
  final String name;
  final int rating;
  final int price;
  final String position;

  const _MarketItem({required this.name, required this.rating, required this.price, required this.position});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      backgroundColor: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person, color: AppColors.muted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.h3),
                Text('$position | Güç: $rating', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$price ₺', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: 80,
                child: AppButton(text: 'AL', onTap: () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
