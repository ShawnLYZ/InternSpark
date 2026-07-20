import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final leaderboardProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(leaderboardRepositoryProvider).leaderboard());

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(leaderboardProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return stats.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: 'Error: $e'),
      data: (rows) {
        final ranked = rankLeaderboard(rows);
        return ListView(
          padding: const EdgeInsets.all(AppTokens.space16),
          children: [
            Text('Responsiveness leaderboard',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Which employers actually get back to matched students.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppTokens.space20),
            for (final (i, s) in ranked.indexed) _RankRow(rank: i + 1, stat: s),
          ],
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.stat});
  final int rank;
  final CompanyGhostStats stat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final medal = switch (rank) {
      1 => const Color(0xFFF2B705),
      2 => const Color(0xFF9AA6B2),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    final hasData = minSampleGate(stat.totalMatches) && stat.avgResponseSecs != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: medal?.withValues(alpha: 0.5) ?? scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (medal ?? scheme.surfaceContainerHighest).withValues(alpha: medal != null ? 0.18 : 1),
              shape: BoxShape.circle,
            ),
            child: Text('$rank',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: medal ?? scheme.onSurfaceVariant,
                )),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.companyName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                if (hasData)
                  Text('avg response ${(stat.avgResponseSecs! / 86400).toStringAsFixed(1)}d',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          GhostBadge(ghostRate: stat.ghostRate, totalMatches: stat.totalMatches),
        ],
      ),
    );
  }
}
