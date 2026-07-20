import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final reportableStudentsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(reportRepositoryProvider).reportableStudents());

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key, required this.companyName});
  final String companyName;
  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  ReportableStudent? _student;
  int _reliability = 3, _skill = 3, _communication = 3;
  final _narrative = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _narrative.dispose();
    super.dispose();
  }

  Future<void> _draft() async {
    if (_student == null) return;
    setState(() => _busy = true);
    final text = await ref.read(reportRepositoryProvider).draftNarrative(
        studentName: _student!.fullName, reliability: _reliability, skill: _skill, communication: _communication);
    if (mounted) {
      setState(() {
        _narrative.text = text;
        _busy = false;
      });
    }
  }

  Future<void> _file() async {
    if (_student == null) return;
    setState(() => _busy = true);
    await ref.read(reportRepositoryProvider).fileReport(
        studentId: _student!.studentId,
        studentName: _student!.fullName,
        companyName: widget.companyName,
        reliability: _reliability,
        skill: _skill,
        communication: _communication,
        narrative: _narrative.text.trim());
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _score(String label, int value, ValueChanged<int> onChange) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$value',
              onChanged: (v) => setState(() => onChange(v.round())),
            ),
          ),
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text('$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = ref.watch(reportableStudentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('File a report')),
      body: students.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (list) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space24),
              children: [
                DropdownButtonFormField<ReportableStudent>(
                  initialValue: _student,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: [for (final s in list) DropdownMenuItem(value: s, child: Text(s.fullName))],
                  onChanged: (s) => setState(() => _student = s),
                ),
                const SizedBox(height: AppTokens.space16),
                _score('Reliability', _reliability, (v) => _reliability = v),
                _score('Skill', _skill, (v) => _skill = v),
                _score('Communication', _communication, (v) => _communication = v),
                const SizedBox(height: AppTokens.space12),
                TextField(
                  controller: _narrative,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Narrative', alignLabelWithHint: true),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _draft,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('AI draft')],
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space8),
                FilledButton(
                  key: const Key('file-report'),
                  onPressed: (_student == null || _busy) ? null : _file,
                  child: const Text('File report'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
