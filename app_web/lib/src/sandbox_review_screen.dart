import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final jobSandboxSubmissionsProvider =
    FutureProvider.autoDispose.family<List<SandboxSubmission>, String>(
        (ref, jobId) => ref.watch(sandboxRepositoryProvider).jobSubmissions(jobId));

class SandboxReviewScreen extends ConsumerWidget {
  const SandboxReviewScreen({super.key, required this.jobId, required this.jobTitle});
  final String jobId;
  final String jobTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subs = ref.watch(jobSandboxSubmissionsProvider(jobId));
    return Scaffold(
      appBar: AppBar(title: Text('Try-out submissions · $jobTitle')),
      body: subs.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (rows) => rows.isEmpty
            ? const AppEmpty(icon: Icons.assignment_outlined, message: 'No submissions yet.')
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    children: [for (final s in rows) _SubmissionTile(jobId: jobId, sub: s)],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SubmissionTile extends ConsumerStatefulWidget {
  const _SubmissionTile({required this.jobId, required this.sub});
  final String jobId;
  final SandboxSubmission sub;

  @override
  ConsumerState<_SubmissionTile> createState() => _SubmissionTileState();
}

class _SubmissionTileState extends ConsumerState<_SubmissionTile> {
  final _notes = TextEditingController();
  String? _assessment;
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _assess() async {
    setState(() => _busy = true);
    final a = await ref.read(sandboxRepositoryProvider).assess(widget.sub.text ?? '');
    setState(() {
      _assessment = a;
      _busy = false;
    });
  }

  Future<void> _record(String verdict) async {
    setState(() => _busy = true);
    await ref.read(sandboxRepositoryProvider).recordVerdict(
        submissionId: widget.sub.id, verdict: verdict, notes: _notes.text.trim(), aiAssessment: _assessment);
    ref.invalidate(jobSandboxSubmissionsProvider(widget.jobId));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sub;
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
          Text('${s.studentName} · ${s.status.name}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTokens.space12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTokens.space12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Text(s.text ?? '(no answer submitted)', style: text.bodyMedium),
          ),
          if (_assessment != null) ...[
            const SizedBox(height: AppTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: scheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_assessment!,
                      style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Verdict notes'),
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('assess'),
                onPressed: _busy ? null : _assess,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('AI assess'),
              ),
              const Spacer(),
              TextButton(onPressed: _busy ? null : () => _record('weak'), child: const Text('Weak')),
              const SizedBox(width: AppTokens.space8),
              FilledButton(
                key: const Key('strong'),
                onPressed: _busy ? null : () => _record('strong'),
                child: const Text('Strong'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space8),
          Text('Informs your decision — it does not gate interview/offer/pass.',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
