import 'package:flutter/material.dart';
import '../domain/ghost_stats.dart';
import 'app_ui.dart';

/// The deck card's ghost-rate badge (fills the Phase 1 placeholder slot).
/// Gated to "Not enough data" under the min sample; tone-coded otherwise
/// (green = responsive, amber = ghosts a lot).
class GhostBadge extends StatelessWidget {
  const GhostBadge({super.key, required this.ghostRate, required this.totalMatches});
  final double? ghostRate;
  final int totalMatches;

  @override
  Widget build(BuildContext context) {
    if (!minSampleGate(totalMatches) || ghostRate == null) {
      return const Pill('Not enough data', icon: Icons.help_outline_rounded, tone: PillTone.neutral);
    }
    final pct = (ghostRate! * 100).round();
    final responsive = pct <= 20;
    return Pill(
      '$pct% ghosted',
      icon: responsive ? Icons.verified_outlined : Icons.warning_amber_rounded,
      tone: responsive ? PillTone.success : PillTone.warning,
    );
  }
}
