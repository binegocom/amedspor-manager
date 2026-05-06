import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_card.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../data/models/match_model.dart';
import '../../../../data/models/match_event_model.dart';
import '../../../../data/repositories/match_repository.dart';
import '../../widgets/admin_layout.dart';

class AdminLiveMatchScreen extends StatefulWidget {
  final String matchId;
  const AdminLiveMatchScreen({super.key, required this.matchId});

  static const String routePath = '/admin/matches/live/:matchId';

  @override
  State<AdminLiveMatchScreen> createState() => _AdminLiveMatchScreenState();
}

class _AdminLiveMatchScreenState extends State<AdminLiveMatchScreen> {
  final matchRepository = MatchRepository();
  final uuid = const Uuid();

  late TextEditingController homeScoreContr;
  late TextEditingController awayScoreContr;
  late TextEditingController minuteContr;
  String selectedStatus = 'upcoming';

  @override
  void initState() {
    super.initState();
    homeScoreContr = TextEditingController();
    awayScoreContr = TextEditingController();
    minuteContr = TextEditingController();
  }

  Future<void> _updateBasicInfo() async {
    await matchRepository.updateMatchLive(
      matchId: widget.matchId,
      homeScore: int.tryParse(homeScoreContr.text) ?? 0,
      awayScore: int.tryParse(awayScoreContr.text) ?? 0,
      minute: int.tryParse(minuteContr.text) ?? 0,
      status: selectedStatus,
    );
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('Bilgiler güncellendi.'),
        ),
      );
  }

  Future<void> _addEventDialog() async {
    final typeContr = TextEditingController(text: 'goal');
    final playerContr = TextEditingController();
    final playerOutContr = TextEditingController();
    final teamContr = TextEditingController(text: 'home');
    final minuteContrEvent = TextEditingController(text: minuteContr.text);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('Yeni Olay Ekle', style: AppTextStyles.h2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: typeContr.text,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Olay Tipi',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'goal', child: Text('GOL')),
                    DropdownMenuItem(
                      value: 'yellowCard',
                      child: Text('SARI KART'),
                    ),
                    DropdownMenuItem(
                      value: 'redCard',
                      child: Text('KIRMIZI KART'),
                    ),
                    DropdownMenuItem(
                      value: 'substitution',
                      child: Text('OYUNCU DEĞİŞİKLİĞİ'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => typeContr.text = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: teamContr.text,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Takım',
                    labelStyle: TextStyle(color: AppColors.muted),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'home', child: Text('EV SAHİBİ')),
                    DropdownMenuItem(value: 'away', child: Text('DEPLASMAN')),
                  ],
                  onChanged: (v) => setDialogState(() => teamContr.text = v!),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Dakika',
                  controller: minuteContrEvent,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                AppTextField(label: 'Oyuncu Adı', controller: playerContr),
                if (typeContr.text == 'substitution') ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Çıkan Oyuncu',
                    controller: playerOutContr,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'VAZGEÇ',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            AppButton(
              text: 'EKLE',
              width: 100,
              onTap: () async {
                final event = MatchEventModel(
                  id: uuid.v4(),
                  type: typeContr.text,
                  minute: int.tryParse(minuteContrEvent.text) ?? 0,
                  team: teamContr.text,
                  playerName: playerContr.text,
                  playerNameOut: playerOutContr.text.isNotEmpty
                      ? playerOutContr.text
                      : null,
                  description: '',
                  createdAt: DateTime.now(),
                );
                await matchRepository.addMatchEvent(
                  matchId: widget.matchId,
                  event: event,
                );
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      activeRoute: AdminLiveMatchScreen.routePath,
      child: StreamBuilder<MatchModel?>(
        stream: matchRepository.watchMatch(widget.matchId),
        builder: (context, snapshot) {
          final match = snapshot.data;
          if (match == null)
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );

          if (homeScoreContr.text.isEmpty) {
            homeScoreContr.text = match.homeScore.toString();
            awayScoreContr.text = match.awayScore.toString();
            minuteContr.text = match.minute.toString();
            selectedStatus = match.status;
          }

          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Canlı Kontrol Merkezi',
                        style: AppTextStyles.h1,
                      ),
                      Text(
                        '${match.homeTeam} vs ${match.awayTeam}',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                  _StatusChip(status: selectedStatus),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Maç Durumu', style: AppTextStyles.h3),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Ev Sahibi',
                                      controller: homeScoreContr,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Deplasman',
                                      controller: awayScoreContr,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Dakika',
                                      controller: minuteContr,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<String>(
                                initialValue: selectedStatus,
                                dropdownColor: AppColors.surface,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Maç Durumu',
                                  labelStyle: TextStyle(color: AppColors.muted),
                                ),
                                items:
                                    [
                                      'upcoming',
                                      'live',
                                      'halftime',
                                      'finished',
                                    ].map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(s.toUpperCase()),
                                      );
                                    }).toList(),
                                onChanged: (val) =>
                                    setState(() => selectedStatus = val!),
                              ),
                              const SizedBox(height: 32),
                              AppButton(
                                text: 'GÜNCELLE',
                                onTap: _updateBasicInfo,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Maçın Adamı Oylaması',
                                    style: AppTextStyles.h3,
                                  ),
                                  _StatusChip(
                                    status: match.isMotmVotingActive
                                        ? 'live'
                                        : 'finished',
                                    text: match.isMotmVotingActive
                                        ? 'AKTİF'
                                        : 'KAPALI',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _MotmAdminPanel(
                                match: match,
                                matchRepository: matchRepository,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Olaylar', style: AppTextStyles.h3),
                              IconButton(
                                onPressed: _addEventDialog,
                                icon: const Icon(
                                  Icons.add_circle_rounded,
                                  color: AppColors.primaryRed,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StreamBuilder<List<MatchEventModel>>(
                            stream: matchRepository.watchMatchEvents(
                              widget.matchId,
                            ),
                            builder: (context, eventSnapshot) {
                              final events = eventSnapshot.data ?? [];
                              if (events.isEmpty)
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      'Henüz olay yok.',
                                      style: TextStyle(color: AppColors.muted),
                                    ),
                                  ),
                                );

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: events.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final e = events[index];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.darkBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryRed
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${e.minute}\'',
                                              style: const TextStyle(
                                                color: AppColors.primaryRed,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.playerName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                e.type.toUpperCase(),
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          _getEventIcon(e.type),
                                          color: _getEventColor(e.type),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getEventIcon(String type) {
    return switch (type) {
      'goal' => Icons.sports_soccer_rounded,
      'yellowCard' => Icons.rectangle_rounded,
      'redCard' => Icons.rectangle_rounded,
      'substitution' => Icons.sync_rounded,
      _ => Icons.event_note_rounded,
    };
  }

  Color _getEventColor(String type) {
    return switch (type) {
      'goal' => AppColors.primaryGreen,
      'yellowCard' => AppColors.gold,
      'redCard' => AppColors.primaryRed,
      'substitution' => Colors.blue,
      _ => AppColors.muted,
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String? text;
  const _StatusChip({required this.status, this.text});

  @override
  Widget build(BuildContext context) {
    final color = status == 'live'
        ? AppColors.primaryGreen
        : status == 'finished'
        ? AppColors.muted
        : AppColors.primaryRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text ?? status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MotmAdminPanel extends StatefulWidget {
  final MatchModel match;
  final MatchRepository matchRepository;
  const _MotmAdminPanel({required this.match, required this.matchRepository});

  @override
  State<_MotmAdminPanel> createState() => _MotmAdminPanelState();
}

class _MotmAdminPanelState extends State<_MotmAdminPanel> {
  late TextEditingController candidatesContr;

  @override
  void initState() {
    super.initState();
    candidatesContr = TextEditingController(
      text: widget.match.motmCandidates.join(', '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Aday Oyuncular (Virgülle ayırın)',
          controller: candidatesContr,
          hint: 'Player 1, Player 2...',
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'ADAYLARI GÜNCELLE',
                onTap: () {
                  final list = candidatesContr.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  widget.matchRepository.updateMotmCandidates(
                    widget.match.id,
                    list,
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: widget.match.isMotmVotingActive
                    ? 'OYLAMAYI DURDUR'
                    : 'OYLAMAYI BAŞLAT',
                color: widget.match.isMotmVotingActive
                    ? AppColors.errorRed
                    : AppColors.primaryGreen,
                onTap: () => widget.matchRepository.toggleMotmVoting(
                  widget.match.id,
                  !widget.match.isMotmVotingActive,
                ),
              ),
            ),
          ],
        ),
        if (widget.match.motmResults.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'GÜNCEL OY DAĞILIMI',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.match.motmResults.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${e.value} Oy',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
