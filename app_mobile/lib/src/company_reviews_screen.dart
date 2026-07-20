import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

import 'matches_screen.dart' show myApplicationsProvider;
import 'review_compose_screen.dart';

final companyReviewsProvider = FutureProvider.autoDispose.family<List<Review>, String>(
    (ref, companyId) => ref.watch(reviewRepositoryProvider).companyReviews(companyId));

class CompanyReviewsScreen extends ConsumerWidget {
  const CompanyReviewsScreen({super.key, required this.companyId, required this.companyName});
  final String companyId;
  final String companyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(companyReviewsProvider(companyId));
    final apps = ref.watch(myApplicationsProvider).asData?.value ?? const <Application>[];
    final eligible = canReview(companyId: companyId, applications: apps);

    return Scaffold(
      appBar: AppBar(title: Text('$companyName — reviews')),
      floatingActionButton: eligible
          ? FloatingActionButton.extended(
              onPressed: () async {
                final posted = await Navigator.of(context).push<bool>(MaterialPageRoute(
                  builder: (_) => ReviewComposeScreen(companyId: companyId, companyName: companyName),
                ));
                if (posted == true) ref.invalidate(companyReviewsProvider(companyId));
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Write a review'),
            )
          : null,
      body: reviews.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (rows) {
          final score = mentorshipScore(rows);
          return ListView(
            padding: const EdgeInsets.all(AppTokens.space16),
            children: [
              Container(
                padding: const EdgeInsets.all(AppTokens.space16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Anonymous, verified-intern reviews',
                          style: Theme.of(context).textTheme.titleSmall),
                    ),
                    MentorshipBadge(score: score, reviewCount: rows.length),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space16),
              for (final r in rows) _ReviewCard(review: r),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  Widget _rating(BuildContext context, IconData icon, String label, int value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text('$label $value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: scheme.tertiaryContainer,
                child: Icon(Icons.verified_user_outlined, size: 15, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: AppTokens.space8),
              Expanded(
                child: Text('Verified intern', // never the author's name
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                iconSize: 18,
                tooltip: 'Report',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reported for moderation.')),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space8),
          Wrap(
            spacing: AppTokens.space12,
            runSpacing: 6,
            children: [
              _rating(context, Icons.school_outlined, 'Mentorship', review.mentorship),
              _rating(context, Icons.balance_rounded, 'Workload', review.workload),
              _rating(context, Icons.health_and_safety_outlined, 'Safety', review.psychSafety),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            Text(review.comment!, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}
