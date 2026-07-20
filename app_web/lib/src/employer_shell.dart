import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

import 'account_menu.dart';
import 'applicants_screen.dart';
import 'chat_screen.dart';
import 'job_form_screen.dart';
import 'report_form_screen.dart';

final myCompanyProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(employerRepositoryProvider).fetchMyCompany());
final myJobsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(jobRepositoryProvider).myJobs());
final myGhostStatProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(leaderboardRepositoryProvider).myCompanyStat());

class EmployerShell extends ConsumerWidget {
  const EmployerShell({super.key});

  void _newJob(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JobFormScreen(onSaved: () {
        ref.invalidate(myJobsProvider);
        Navigator.of(context).pop();
      }),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(myCompanyProvider);
    final jobs = ref.watch(myJobsProvider);
    final companyName = company.asData?.value?.name ?? 'Your company';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.space24,
        title: const BrandMark(size: 28),
        actions: [
          const AccountMenu(),
          IconButton(
            tooltip: 'File report',
            icon: const Icon(Icons.assignment_outlined),
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportFormScreen(companyName: companyName))),
          ),
          IconButton(
            tooltip: 'Chat',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
          const SizedBox(width: AppTokens.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space8),
            child: FilledButton.icon(
              onPressed: () => _newJob(context, ref),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('New job'),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.space24),
            children: [
              _CompanyHeader(name: companyName),
              const SizedBox(height: AppTokens.space24),
              const SectionHeader('Your postings', icon: Icons.work_outline_rounded),
              jobs.when(
                loading: () => const Padding(
                    padding: EdgeInsets.only(top: AppTokens.space48), child: AppLoading()),
                error: (e, _) => AppError(message: 'Error: $e'),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const AppEmpty(
                      icon: Icons.work_outline_rounded,
                      message: 'No postings yet. Create your first internship to start matching.',
                    );
                  }
                  return Column(children: [for (final j in rows) _JobCard(job: j)]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyHeader extends ConsumerWidget {
  const _CompanyHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stat = ref.watch(myGhostStatProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Icon(Icons.apartment_rounded, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('Employer workspace',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (stat != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Responsiveness',
                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                GhostBadge(ghostRate: stat.ghostRate, totalMatches: stat.totalMatches),
              ],
            ),
        ],
      ),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const _JobCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(selectedJobIdProvider.notifier).set(job.id);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('Applicants · ${job.title}')),
              body: const ApplicantsScreen(),
            ),
          ));
        },
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(Icons.badge_outlined, size: 20, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: AppTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if ((job.remoteMode ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Pill(job.remoteMode!, icon: Icons.laptop_mac_rounded),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Text('View applicants',
                      style: text.labelLarge?.copyWith(color: scheme.tertiary)),
                  Icon(Icons.chevron_right_rounded, color: scheme.tertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
