import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/components/premium_card.dart';
import '../../../../data/models/user_mission_model.dart';
import '../../../../data/repositories/gamification_repository.dart';

class MissionItemCard extends StatefulWidget {
  final UserMissionModel mission;
  final String userId;

  const MissionItemCard({
    super.key,
    required this.mission,
    required this.userId,
  });

  @override
  State<MissionItemCard> createState() => _MissionItemCardState();
}

class _MissionItemCardState extends State<MissionItemCard> with SingleTickerProviderStateMixin {
  bool _isClaiming = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    if (_isClaiming) return;
    setState(() => _isClaiming = true);

    try {
      final repo = GamificationRepository();
      // Points reward can be derived or added to the model if needed, 
      // for now we use a default or derive from XP.
      await repo.claimMissionReward(
        userId: widget.userId,
        missionId: widget.mission.id,
        xpReward: widget.mission.xpReward,
        pointsReward: (widget.mission.xpReward / 2).floor(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryGreen,
          content: Text('Tebrikler! ${widget.mission.xpReward} XP kazandın.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text('Hata: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final progress = (mission.progress / mission.requiredCount).clamp(0.0, 1.0);
    final isCompleted = mission.completed;
    final isClaimed = mission.claimed;

    return PremiumCard(
      backgroundColor: isClaimed ? AppColors.surface.withValues(alpha: 0.5) : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMissionIcon(isCompleted, isClaimed),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: isClaimed ? Colors.white60 : Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mission.description,
                      style: TextStyle(
                        color: isClaimed ? AppColors.muted.withValues(alpha: 0.6) : AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClaimed)
                const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 24)
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRewardBadge(mission.xpReward),
              Text(
                '${mission.progress}/${mission.requiredCount}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildProgressBar(progress, isCompleted, isClaimed),
          if (isCompleted && !isClaimed) ...[
            const SizedBox(height: 18),
            _buildClaimButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildMissionIcon(bool completed, bool claimed) {
    final color = claimed 
        ? AppColors.muted 
        : (completed ? AppColors.primaryGreen : AppColors.primaryRed);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Icon(
        claimed ? Icons.done_all_rounded : (completed ? Icons.emoji_events_rounded : Icons.bolt_rounded),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildRewardBadge(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.primaryGreen, size: 14),
          const SizedBox(width: 5),
          Text(
            '+$xp XP',
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress, bool completed, bool claimed) {
    final color = claimed 
        ? Colors.white24 
        : (completed ? AppColors.primaryGreen : AppColors.primaryRed);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          if (completed && !claimed)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: 0.2 * _pulseController.value),
                          Colors.white.withValues(alpha: 0),
                        ],
                        begin: Alignment(-1.0 + (_pulseController.value * 2), 0),
                        end: Alignment(1.0 + (_pulseController.value * 2), 0),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClaimButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isClaiming ? null : _claimReward,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
        ),
        child: _isClaiming
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.redeem_rounded),
                  SizedBox(width: 10),
                  Text(
                    'ÖDÜLÜ AL',
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                  ),
                ],
              ),
      ),
    );
  }
}
