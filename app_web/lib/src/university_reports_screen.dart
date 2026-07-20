import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final universityReportsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(reportRepositoryProvider).universityReports());

class UniversityReportsScreen extends ConsumerWidget {
  const UniversityReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(universityReportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports received')),
      body: reports.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (rows) => rows.isEmpty
            ? const AppEmpty(icon: Icons.folder_shared_outlined, message: 'No reports yet.')
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    children: [for (final r in rows) _ReportCard(report: r)],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
                radius: 18,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.assignment_ind_outlined, size: 18, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Text('${report.studentName ?? 'Student'} — ${report.companyName ?? ''}',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              Pill('Reliability ${report.reliability}', icon: Icons.verified_user_outlined),
              Pill('Skill ${report.skill}', icon: Icons.workspace_premium_outlined),
              Pill('Communication ${report.communication}', icon: Icons.forum_outlined),
            ],
          ),
          if ((report.narrative ?? '').isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            Text(report.narrative!, style: text.bodyMedium),
          ],
        ],
      ),
    );
  }
}
