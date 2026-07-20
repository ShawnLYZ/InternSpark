import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

import 'company_reviews_screen.dart';
import 'sandbox_screen.dart';

final myApplicationsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(applicationRepositoryProvider).myApplications());

final mySandboxesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(sandboxRepositoryProvider).mySandboxes());

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(myApplicationsProvider);
    return apps.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: 'Error: $e'),
      data: (rows) {
        final sandboxes = ref.watch(mySandboxesProvider).value ?? const <SandboxSubmission>[];
        final openSandboxes = sandboxes.where((s) => s.status == SandboxStatus.draft).toList();
        return ListView(
          padding: const EdgeInsets.all(AppTokens.space16),
          children: [
            for (final s in openSandboxes) _SandboxCard(submission: s),
            if (rows.isEmpty && openSandboxes.isEmpty) const _NoMatches(),
            for (final a in rows) _ApplicationTile(app: a),
          ],
        );
      },
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space48),
      child: Column(
        children: [
          const BrandMark(size: 52, showWordmark: false),
          const SizedBox(height: AppTokens.space16),
          Text('No applications yet — start swiping!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

class _SandboxCard extends ConsumerWidget {
  const _SandboxCard({required this.submission});
  final SandboxSubmission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: scheme.onTertiaryContainer),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('48h try-out · ${submission.jobTitle}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer, fontWeight: FontWeight.w700,
                        )),
                if (submission.deadlineAt != null) ...[
                  const SizedBox(height: 4),
                  SparkCountdown(deadline: submission.deadlineAt!),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          FilledButton(
            onPressed: () async {
              await Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SandboxScreen(submission: submission)));
              ref.invalidate(mySandboxesProvider);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {
  const _ApplicationTile({required this.app});
  final Application app;

  (String, PillTone, IconData) _status() => switch (app.status) {
        ApplicationStatus.applied => ('Applied', PillTone.info, Icons.send_rounded),
        ApplicationStatus.matched => ("It's a Spark!", PillTone.brand, Icons.bolt_rounded),
        ApplicationStatus.interview => ('Interview', PillTone.info, Icons.event_rounded),
        ApplicationStatus.offer => ('Offer!', PillTone.success, Icons.workspace_premium_rounded),
        ApplicationStatus.accepted => ('Placed', PillTone.success, Icons.verified_rounded),
        ApplicationStatus.declined => ('Declined', PillTone.neutral, Icons.close_rounded),
        _ => (app.status.name, PillTone.neutral, Icons.info_outline_rounded),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (label, tone, icon) = _status();
    final tappable = app.companyId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tappable
            ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    CompanyReviewsScreen(companyId: app.companyId, companyName: app.companyName)))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.jobTitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                        Text(app.companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Pill(label, tone: tone),
                ],
              ),
              _trailing(context, ref, scheme, text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trailing(BuildContext context, WidgetRef ref, ColorScheme scheme, TextTheme text) {
    switch (app.status) {
      case ApplicationStatus.matched when app.matchedAt != null:
        return Padding(
          padding: const EdgeInsets.only(top: AppTokens.space12),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text('Employer responds within ', style: text.bodySmall),
              SparkCountdown(deadline: ghostDeadline(app.matchedAt!)),
            ],
          ),
        );
      case ApplicationStatus.offer:
        return Padding(
          padding: const EdgeInsets.only(top: AppTokens.space12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await ref.read(applicationRepositoryProvider).declineOffer(app.id);
                  ref.invalidate(myApplicationsProvider);
                },
                child: const Text('Decline'),
              ),
              const SizedBox(width: AppTokens.space8),
              FilledButton(
                key: const Key('accept'),
                onPressed: () async {
                  await ref.read(applicationRepositoryProvider).acceptOffer(app.id);
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        key: const Key('disclosure'),
                        icon: const Icon(Icons.handshake_outlined),
                        title: const Text("You're placed!"),
                        content: Text('${app.companyName} and your university can now coordinate '
                            'about your internship. Your reviews stay anonymous.'),
                        actions: [
                          FilledButton(
                              onPressed: () => Navigator.pop(context), child: const Text('Got it')),
                        ],
                      ),
                    );
                  }
                  ref.invalidate(myApplicationsProvider);
                },
                child: const Text('Accept'),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
