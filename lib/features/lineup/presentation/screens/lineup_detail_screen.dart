import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_card.dart';
import '../../../../shared/components/app_header.dart';
import '../../../../shared/components/app_button.dart';
import '../../../../shared/components/app_text_field.dart';
import '../../../../data/models/lineup_model.dart';
import '../../../../data/models/comment_model.dart';
import '../../../../data/repositories/lineup_repository.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

class LineupDetailScreen extends StatefulWidget {
  final String lineupId;

  const LineupDetailScreen({
    super.key,
    required this.lineupId,
  });

  static const String routePath = '/lineup-detail/:lineupId';

  @override
  State<LineupDetailScreen> createState() => _LineupDetailScreenState();
}

class _LineupDetailScreenState extends State<LineupDetailScreen> {
  final lineupRepository = LineupRepository();
  final commentController = TextEditingController();
  final uuid = const Uuid();

  Future<void> _sendComment() async {
    final text = commentController.text.trim();
    final user = authService.currentUser;

    if (user == null) {
      context.go('/login');
      return;
    }

    if (text.isEmpty) return;

    final comment = CommentModel(
      id: uuid.v4(),
      postId: widget.lineupId,
      userId: user.uid,
      username: user.email ?? 'Taraftar',
      text: text,
      createdAt: DateTime.now(),
    );

    await lineupRepository.addLineupComment(
      lineupId: widget.lineupId,
      comment: comment,
    );

    commentController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _like() async {
    final user = authService.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    final liked = await lineupRepository.likeLineup(
      lineupId: widget.lineupId,
      userId: user.uid,
    );

    HapticFeedback.mediumImpact();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: liked ? AppColors.primaryGreen : AppColors.gold,
        content: Text(liked ? 'Kadroyu beğendin!' : 'Zaten beğendin.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: StreamBuilder<List<LineupModel>>(
          stream: lineupRepository.watchAllLineups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
            }

            final lineup = snapshot.data?.firstWhere((l) => l.id == widget.lineupId, orElse: () => null as dynamic);
            if (lineup == null) {
              return const Center(child: Text('Kadro bulunamadı.', style: TextStyle(color: AppColors.muted)));
            }

            return Column(
              children: [
                const AppHeader(title: 'KADRO DETAYI', showBackButton: true),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: AppCard(
                    child: Row(
                      children: [
                        _StatItem(label: 'Güç', value: '${lineup.power}', icon: Icons.bolt_rounded),
                        const VerticalDivider(color: Colors.white10, indent: 8, endIndent: 8),
                        _StatItem(label: 'Beğeni', value: '${lineup.likes}', icon: Icons.thumb_up_rounded),
                        const SizedBox(width: 12),
                        AppButton(
                          text: 'BEĞEN',
                          type: AppButtonType.primary,
                          onTap: _like,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _PitchView(players: lineup.players),
                ),
                _CommentSection(
                  lineupId: widget.lineupId,
                  commentController: commentController,
                  onSend: _sendComment,
                  lineupRepository: lineupRepository,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.h3),
          Text(label, style: AppTextStyles.label),
        ],
      ),
    );
  }
}

class _PitchView extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  const _PitchView({required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryGreen.withValues(alpha: 0.9), AppColors.primaryGreen.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
              ...players.map((p) {
                final top = (p['top'] ?? 0.5) as double;
                final left = (p['left'] ?? 0.5) as double;
                final isCaptain = p['captain'] == true;

                return Positioned(
                  top: top * h - 28,
                  left: left * w - 28,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: isCaptain ? AppColors.gold : AppColors.white, width: 2),
                        ),
                        child: Center(
                          child: Text('${p['number'] ?? '0'}', style: TextStyle(color: isCaptain ? AppColors.gold : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                        child: Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawRect(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommentSection extends StatelessWidget {
  final String lineupId;
  final TextEditingController commentController;
  final VoidCallback onSend;
  final LineupRepository lineupRepository;

  const _CommentSection({
    required this.lineupId,
    required this.commentController,
    required this.onSend,
    required this.lineupRepository,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: lineupRepository.watchLineupComments(lineupId),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('İlk yorumu sen yap!', style: TextStyle(color: AppColors.muted)));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(backgroundColor: AppColors.primaryGreen, radius: 16, child: Icon(Icons.person, color: Colors.white, size: 16)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.username, style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(c.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Row(
              children: [
                Expanded(child: AppTextField(hint: 'Yorum yaz...', controller: commentController)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
