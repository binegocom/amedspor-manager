import 'package:flutter/material.dart';
import '../../domain/models/match_event.dart';

/// Bir maç olayını liste halinde gösteren widget.
class MatchEventTile extends StatelessWidget {
  final MatchEvent event;
  final bool isDark;
  final bool compact;

  const MatchEventTile({
    super.key,
    required this.event,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                "${event.minute}'",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(_getIcon(), size: 12, color: _getIconColor()),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${event.minute}'",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(_getIcon(), size: 16, color: _getIconColor()),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              event.description,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (event.type) {
      case MatchEventType.kickoff:
        return Icons.play_circle_outline;
      case MatchEventType.goal:
        return Icons.sports_soccer;
      case MatchEventType.shot:
        return Icons.arrow_upward;
      case MatchEventType.save:
        return Icons.shield;
      case MatchEventType.tackle:
        return Icons.flash_on;
      case MatchEventType.foul:
        return Icons.block;
      case MatchEventType.yellowCard:
        return Icons.credit_card;
      case MatchEventType.redCard:
        return Icons.credit_card;
      case MatchEventType.corner:
        return Icons.flag;
      case MatchEventType.throwIn:
        return Icons.swap_horiz;
      case MatchEventType.freeKick:
        return Icons.sports_handball;
      case MatchEventType.penalty:
        return Icons.gps_fixed;
      case MatchEventType.offside:
        return Icons.outlined_flag;
      case MatchEventType.goalKick:
        return Icons.sports_kabaddi;
      case MatchEventType.injury:
        return Icons.healing;
      case MatchEventType.substitution:
        return Icons.swap_vert;
      case MatchEventType.boost:
        return Icons.flash_on;
      case MatchEventType.fulltime:
        return Icons.stop;
    }
  }

  Color _getIconColor() {
    switch (event.type) {
      case MatchEventType.goal:
        return Colors.green;
      case MatchEventType.yellowCard:
        return Colors.yellow.shade700;
      case MatchEventType.redCard:
        return Colors.red;
      case MatchEventType.penalty:
        return Colors.red.shade700;
      case MatchEventType.injury:
        return Colors.orange;
      case MatchEventType.boost:
        return Colors.purple;
      case MatchEventType.fulltime:
        return Colors.red;
      default:
        return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  Color _getBackgroundColor() {
    switch (event.type) {
      case MatchEventType.goal:
        return Colors.green.shade700;
      case MatchEventType.yellowCard:
        return Colors.yellow.shade800;
      case MatchEventType.redCard:
        return Colors.red;
      case MatchEventType.penalty:
        return Colors.red.shade700;
      case MatchEventType.boost:
        return Colors.purple.shade700;
      case MatchEventType.fulltime:
        return Colors.red.shade700;
      default:
        return isDark ? Colors.grey.shade700 : Colors.grey.shade500;
    }
  }
}
