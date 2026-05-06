import 'package:flutter/material.dart';

import '../../../../data/models/lineup_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../widgets/admin_layout.dart';

class AdminLineupsScreen extends StatelessWidget {
  const AdminLineupsScreen({super.key});

  static const String routePath = '/admin/lineups';

  @override
  Widget build(BuildContext context) {
    final lineupRepository = LineupRepository();

    return AdminLayout(
      activeRoute: AdminLineupsScreen.routePath,
      title: 'Kadro Yönetimi',
      subtitle: 'Taraftar kadrolarını incele ve haftanın kazananını seç.',
      child: StreamBuilder<List<LineupModel>>(
        stream: lineupRepository.watchTopLineups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            );
          }

          final lineups = snapshot.data ?? [];

          if (lineups.isEmpty) {
            return const Center(
              child: Text(
                'Henüz kadro kurulmadı.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            itemCount: lineups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lineup = lineups[index];
              final isWinner = lineup.toMap()['isWeeklyWinner'] == true;

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isWinner ? const Color(0xFFFFB300) : Colors.white10,
                    width: isWinner ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'GÜÇ: ${lineup.power}',
                                style: const TextStyle(
                                  color: Color(0xFF0F6A3D),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'BEĞENİ: ${lineup.likes}',
                                style: const TextStyle(
                                  color: Color(0xFFE53935),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diziliş: ${lineup.formation}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kullanıcı ID: ${lineup.userId}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWinner)
                      const Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFB300),
                          ),
                          Text(
                            'KAZANAN',
                            style: TextStyle(
                              color: Color(0xFFFFB300),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    else
                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A1A),
                              title: const Text(
                                'Emin misiniz?',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Bu kadroyu haftanın kadrosu seçeceksiniz. Kullanıcıya 100 puan ve rozet verilecek.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('İptal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFB300),
                                  ),
                                  child: const Text('KAZANAN SEÇ'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await lineupRepository.selectWeeklyWinner(
                              lineup.id,
                              lineup.userId,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F6A3D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('HAFTANIN KAZANANI YAP'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
