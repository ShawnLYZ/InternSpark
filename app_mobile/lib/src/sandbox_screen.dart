import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

class SandboxScreen extends ConsumerStatefulWidget {
  const SandboxScreen({super.key, required this.submission});
  final SandboxSubmission submission;
  @override
  ConsumerState<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends ConsumerState<SandboxScreen> {
  late final _answer = TextEditingController(text: widget.submission.text ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    await ref
        .read(sandboxRepositoryProvider)
        .saveDraft(submissionId: widget.submission.id, text: _answer.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.')));
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(sandboxRepositoryProvider).submit(widget.submission.id);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final closed = s.status != SandboxStatus.draft;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('48h try-out · ${s.jobTitle}'),
        actions: [
          if (s.deadlineAt != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.space12),
              child: Center(child: SparkCountdown(deadline: s.deadlineAt!)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space20),
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.space16),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.assignment_outlined, color: scheme.onTertiaryContainer, size: 20),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Text(
                    s.prompt.isEmpty ? 'Complete the try-out task.' : s.prompt,
                    style: text.bodyMedium?.copyWith(color: scheme.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          const SectionHeader('Your answer', icon: Icons.edit_note_rounded),
          TextField(
            controller: _answer,
            maxLines: 8,
            enabled: !closed,
            decoration: const InputDecoration(hintText: 'Draft your response…'),
          ),
          const SizedBox(height: AppTokens.space20),
          if (closed)
            Container(
              padding: const EdgeInsets.all(AppTokens.space16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      'Status: ${s.status.name} (this is optional and never affects your application).',
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('save-draft'),
                    onPressed: _busy ? null : _saveDraft,
                    child: const Text('Save draft'),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: FilledButton(
                    key: const Key('submit'),
                    onPressed: _busy ? null : _submit,
                    child: const Text('Submit (final)'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
