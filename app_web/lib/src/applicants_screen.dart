import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'next_step_panel.dart';

/// Holds the job whose applicants are shown (set when the employer opens a job).
class _SelectedJobIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  // ignore: use_setters_to_change_properties
  void set(String? id) => state = id;
}

final selectedJobIdProvider =
    NotifierProvider<_SelectedJobIdNotifier, String?>(_SelectedJobIdNotifier.new);

final applicantsProvider = FutureProvider.autoDispose<List<ApplicantRow>>((ref) async {
  final jobId = ref.watch(selectedJobIdProvider);
  if (jobId == null) return [];
  return ref.watch(applicantsRepositoryProvider).applicants(jobId);
});

class ApplicantsScreen extends ConsumerWidget {
  const ApplicantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicants = ref.watch(applicantsProvider);
    return applicants.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: 'Error: $e'),
      data: (rows) {
        if (rows.isEmpty) {
          return const AppEmpty(icon: Icons.people_outline_rounded, message: 'No applicants yet.');
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space8),
                  child: Text('${rows.length} applicant${rows.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space16),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('Skills verified by InternSpark',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                for (final r in rows) _ApplicantCard(row: r),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ApplicantCard extends ConsumerWidget {
  const _ApplicantCard({required this.row});
  final ApplicantRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fit = fitScore(requiredSkills: row.requiredSkills, studentSkills: row.studentSkills);
    final displayName = row.matched ? (row.fullName ?? 'Candidate') : 'Anonymous candidate';
    final fitColor = FitRing.bandColor(fit.percent);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space16),
      padding: const EdgeInsets.all(AppTokens.space20),
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
                radius: 22,
                backgroundColor: row.matched ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
                child: Icon(row.matched ? Icons.person_rounded : Icons.lock_outline_rounded,
                    color: row.matched ? scheme.onTertiaryContainer : scheme.onSurfaceVariant),
              ),
              const SizedBox(width: AppTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(row.matched ? (row.major ?? 'Matched candidate') : 'Identity hidden until you match',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: fitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                ),
                child: Text('${(fit.percent * 100).round()}% fit',
                    style: text.labelLarge?.copyWith(color: fitColor, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (row.growthStatement != null) ...[
            const SizedBox(height: AppTokens.space12),
            Text(row.growthStatement!, style: text.bodyMedium),
          ],
          if (fit.matchedChips.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [for (final chip in fit.matchedChips) Chip(label: Text(chip))],
            ),
          ],
          const Divider(height: AppTokens.space32),
          Row(
            children: [
              TextButton.icon(
                key: const Key('view-resume'),
                onPressed: () => _viewResume(context, ref),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: const Text('View resume'),
              ),
              const Spacer(),
              _action(context, ref),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref) {
    switch (row.status) {
      case ApplicationStatus.applied:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              key: const Key('reject'),
              onPressed: () async {
                await ref
                    .read(applicantsRepositoryProvider)
                    .employerSwipe(applicationId: row.applicationId, direction: 'left');
                ref.invalidate(applicantsProvider);
              },
              child: const Text('Reject'),
            ),
            const SizedBox(width: AppTokens.space12),
            FilledButton.icon(
              key: const Key('match'),
              onPressed: () async {
                await ref
                    .read(applicantsRepositoryProvider)
                    .employerSwipe(applicationId: row.applicationId, direction: 'right');
                ref.invalidate(applicantsProvider);
              },
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: const Text('Match'),
            ),
          ],
        );
      case ApplicationStatus.matched:
      case ApplicationStatus.interview:
        return NextStepPanel(applicationId: row.applicationId);
      case ApplicationStatus.offer:
        return const Pill('Offer sent', icon: Icons.workspace_premium_rounded, tone: PillTone.success);
      case ApplicationStatus.accepted:
        return const Pill('Placed', icon: Icons.verified_rounded, tone: PillTone.success);
      default:
        return Text(row.status.name, style: Theme.of(context).textTheme.labelMedium);
    }
  }

  Future<void> _viewResume(BuildContext context, WidgetRef ref) async {
    final resume = await ref.read(resumeRepositoryProvider).applicantResume(row.applicationId);
    if (!context.mounted || resume == null) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(resume.name), // 'Candidate' until matched
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (resume.headline.isNotEmpty) Text(resume.headline),
              if (resume.summary.isNotEmpty) ...[
                const SizedBox(height: AppTokens.space8),
                Text(resume.summary),
              ],
              for (final s in resume.sections) ...[
                const SizedBox(height: AppTokens.space12),
                Text(s.title, style: Theme.of(context).textTheme.titleSmall),
                for (final b in s.bullets) Text('• $b'),
              ],
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
