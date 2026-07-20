import 'package:flutter/material.dart';
import '../design/app_tokens.dart';
import 'app_ui.dart';

/// The deck card's mentorship-score badge (fills the Phase 1 placeholder slot).
class MentorshipBadge extends StatelessWidget {
  const MentorshipBadge({super.key, required this.score, required this.reviewCount});
  final double score;
  final int reviewCount;

  static const _amber = Color(0xFFF2B705);

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return const Pill('No reviews', icon: Icons.star_border_rounded, tone: PillTone.neutral);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.warningContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: _amber),
          const SizedBox(width: 5),
          Text(
            '${score.toStringAsFixed(1)} mentorship ($reviewCount)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTokens.onWarningContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
