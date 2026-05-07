import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../data/models/player_model.dart';
import '../../../../data/repositories/player_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';
import '../widgets/admin_layout.dart';

class AdminPlayersScreen extends StatefulWidget {
  const AdminPlayersScreen({super.key});

  static const String routePath = '/admin/players';

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final playerRepository = PlayerRepository();
  final uuid = const Uuid();
  String selectedFilter = 'all';

  List<PlayerModel> _filterPlayers(List<PlayerModel> players) {
    if (selectedFilter == 'all') return players;
    return players.where((player) => player.position == selectedFilter).toList();
  }

  Future<void> _openPlayerDialog({PlayerModel? player}) async {
    final nameController = TextEditingController(text: player?.name ?? '');
    final numberController = TextEditingController(text: player == null ? '' : player.number.toString());
    final ratingController = TextEditingController(text: player == null ? '70' : player.rating.toString());
    String position = player?.position ?? 'MID';
    bool active = player?.active ?? true;

    final result = await showDialog<PlayerModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(player == null ? 'Yeni Oyuncu' : 'Oyuncu Düzenle', style: AppTextStyles.h2),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(label: 'Oyuncu Adı', controller: nameController, hint: 'Örn: Mesut Özil'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: AppTextField(label: 'Forma No', controller: numberController, hint: '10', keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: AppTextField(label: 'Güç', controller: ratingController, hint: '85', keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: position,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Pozisyon',
                        labelStyle: const TextStyle(color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.darkBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'GK', child: Text('Kaleci')),
                        DropdownMenuItem(value: 'DEF', child: Text('Defans')),
                        DropdownMenuItem(value: 'MID', child: Text('Orta Saha')),
                        DropdownMenuItem(value: 'FWD', child: Text('Forvet')),
                      ],
                      onChanged: (v) => setDialogState(() => position = v!),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Aktif Oyuncu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Kadro kurarken görünüp görünmeyeceğini belirler.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      value: active,
                      activeThumbColor: AppColors.primaryGreen,
                      onChanged: (v) => setDialogState(() => active = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('VAZGEÇ', style: TextStyle(color: AppColors.muted))),
                AppButton(
                  text: 'KAYDET',
                  width: 120,
                  onTap: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context, PlayerModel(
                      id: player?.id ?? uuid.v4(),
                      name: name,
                      position: position,
                      number: int.tryParse(numberController.text) ?? 0,
                      rating: int.tryParse(ratingController.text) ?? 70,
                      active: active,
                    ));
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (player == null) {
        await playerRepository.createPlayer(result);
      } else {
        await playerRepository.updatePlayer(result);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: AppColors.primaryGreen, content: Text('İşlem başarılı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminPlayersScreen.routePath,
      title: 'Oyuncu Havuzu',
      subtitle: 'Kadro oluşturma için kullanılacak oyuncu listesi',
      actions: [
        AppButton(
          text: 'DEMO KADRO',
          width: 160,
          type: AppButtonType.secondary,
          icon: Icons.auto_awesome_rounded,
          onTap: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              await seedService.seedAmedspor2026Squad();
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primaryGreen,
                  content: Text('2025-2026 Sezonu Kadrosu Başarıyla Yüklendi!'),
                ),
              );
            } catch (e) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.errorRed,
                  content: Text('Hata: $e'),
                ),
              );
            }
          },
        ),
        const SizedBox(width: 12),
        AppButton(
          text: 'YENİ OYUNCU',
          width: 180,
          icon: Icons.add_rounded,
          onTap: () => _openPlayerDialog(),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            children: [
              _FilterChip(title: 'Tümü', active: selectedFilter == 'all', onTap: () => setState(() => selectedFilter = 'all')),
              _FilterChip(title: 'Kaleci', active: selectedFilter == 'GK', onTap: () => setState(() => selectedFilter = 'GK')),
              _FilterChip(title: 'Defans', active: selectedFilter == 'DEF', onTap: () => setState(() => selectedFilter = 'DEF')),
              _FilterChip(title: 'Orta Saha', active: selectedFilter == 'MID', onTap: () => setState(() => selectedFilter = 'MID')),
              _FilterChip(title: 'Forvet', active: selectedFilter == 'FWD', onTap: () => setState(() => selectedFilter = 'FWD')),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<PlayerModel>>(
            stream: playerRepository.watchAllPlayers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
              }
              final players = _filterPlayers(snapshot.data ?? []);
              if (players.isEmpty) return const Center(child: Text('Oyuncu bulunamadı.', style: TextStyle(color: AppColors.muted)));

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: players.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemBuilder: (context, index) => _PlayerCard(
                      player: players[index],
                      onTap: () => _openPlayerDialog(player: players[index]),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.title, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primaryGreen : AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Text(title, style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final PlayerModel player;
  final VoidCallback onTap;
  const _PlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                child: Center(child: Text('${player.number}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: player.active ? AppColors.primaryGreen.withValues(alpha: 0.1) : AppColors.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(player.active ? 'AKTİF' : 'PASİF', style: TextStyle(color: player.active ? AppColors.primaryGreen : AppColors.errorRed, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(player.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(player.position, style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 12)),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 16),
              const SizedBox(width: 4),
              Text('${player.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.edit_note_rounded, color: AppColors.muted, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
