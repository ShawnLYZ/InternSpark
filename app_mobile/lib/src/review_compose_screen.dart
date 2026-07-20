import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

class ReviewComposeScreen extends ConsumerStatefulWidget {
  const ReviewComposeScreen({super.key, required this.companyId, required this.companyName});
  final String companyId;
  final String companyName;
  @override
  ConsumerState<ReviewComposeScreen> createState() => _ReviewComposeScreenState();
}

class _ReviewComposeScreenState extends ConsumerState<ReviewComposeScreen> {
  int _mentorship = 3, _workload = 3, _psych = 3;
  final _comment = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (containsProfanity(_comment.text)) {
      setState(() => _error = 'Please remove inappropriate language.');
      return;
    }

    // Soft comment-gate: warn (never block) if no report was filed about me.
    String myId;
    try {
      myId = ref.read(supabaseClientProvider).auth.currentUser?.id ?? '';
    } catch (_) {
      myId = '';
    }
    final refs = await ref.read(reviewRepositoryProvider).myReportRefs();
    final gate = commentGate(studentId: myId, companyId: widget.companyId, reports: refs);
    if (gate.warn && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Post anyway?'),
          content: Text('${widget.companyName} hasn\'t shared your performance report '
              'with your university yet. You can still post your review.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              key: const Key('post-anyway'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Post anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return; // user chose to wait — nothing is blocked, they simply declined
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reviewRepositoryProvider).postReview(
            companyId: widget.companyId,
            mentorship: _mentorship,
            workload: _workload,
            psychSafety: _psych,
            comment: _comment.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      setState(() {
        _busy = false;
        _error = 'Could not post — are you a verified intern here?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Review ${widget.companyName}')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12, vertical: AppTokens.space8),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: scheme.onTertiaryContainer),
                const SizedBox(width: 6),
                Text('Posted anonymously as a Verified intern',
                    style: text.labelMedium?.copyWith(color: scheme.onTertiaryContainer)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          _Stars(label: 'Mentorship', value: _mentorship, onChange: (v) => setState(() => _mentorship = v)),
          _Stars(label: 'Realistic workload', value: _workload, onChange: (v) => setState(() => _workload = v)),
          _Stars(label: 'Psychological safety', value: _psych, onChange: (v) => setState(() => _psych = v)),
          const SizedBox(height: AppTokens.space16),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Comment (optional)', alignLabelWithHint: true),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space12),
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
                const SizedBox(width: AppTokens.space8),
                Expanded(child: Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error))),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space24),
          FilledButton(
            key: const Key('post-review'),
            onPressed: _busy ? null : _submit,
            child: const Text('Post as Verified intern'),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.label, required this.value, required this.onChange});
  final String label;
  final int value;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          for (var i = 1; i <= 5; i++)
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 26,
              color: const Color(0xFFF2B705),
              icon: Icon(i <= value ? Icons.star_rounded : Icons.star_border_rounded),
              onPressed: () => onChange(i),
            ),
        ],
      ),
    );
  }
}
