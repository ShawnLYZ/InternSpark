import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final creditQueueProvider = FutureProvider.autoDispose((ref) => ref.watch(creditRepositoryProvider).queue());

class CreditQueueScreen extends ConsumerWidget {
  const CreditQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(creditQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Credit approvals')),
      body: queue.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (rows) => rows.isEmpty
            ? const AppEmpty(icon: Icons.verified_outlined, message: 'No credit requests yet.')
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    children: [for (final r in rows) _CreditTile(request: r)],
                  ),
                ),
              ),
      ),
    );
  }
}

class _CreditTile extends ConsumerStatefulWidget {
  const _CreditTile({required this.request});
  final CreditRequest request;
  @override
  ConsumerState<_CreditTile> createState() => _CreditTileState();
}

class _CreditTileState extends ConsumerState<_CreditTile> {
  CreditMapping? _mapping;
  final _signer = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _mapping = widget.request.mapping;
  }

  @override
  void dispose() {
    _signer.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final m = await ref.read(creditRepositoryProvider).generateMapping(widget.request.jobId);
    await ref.read(creditRepositoryProvider).attachMapping(
        requestId: widget.request.id,
        jobTitle: widget.request.jobTitle,
        studentName: widget.request.studentName,
        mapping: m);
    setState(() {
      _mapping = m;
      _busy = false;
    });
  }

  Future<void> _approve() async {
    if (_signer.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await ref.read(creditRepositoryProvider).approve(requestId: widget.request.id, signerName: _signer.text.trim());
    ref.invalidate(creditQueueProvider);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
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
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                child: Icon(Icons.workspace_premium_outlined, size: 18, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Text('${r.studentName} — ${r.jobTitle}',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          if (r.isApproved)
            Pill('Approved by ${r.signerName}', icon: Icons.verified_rounded, tone: PillTone.success)
          else if (_mapping == null)
            FilledButton.icon(
              key: const Key('generate'),
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Generate mapping'),
            )
          else ...[
            Text(_mapping!.summary, style: text.bodyMedium),
            const SizedBox(height: AppTokens.space8),
            for (final s in _mapping!.satisfied)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 16, color: AppTokens.success),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${s.skill} — ${s.evidence}', style: text.bodySmall)),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _signer,
                    decoration: const InputDecoration(labelText: 'Signer name'),
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                FilledButton(
                  key: const Key('approve'),
                  onPressed: _busy ? null : _approve,
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
