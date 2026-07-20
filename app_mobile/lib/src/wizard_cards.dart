import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

/// What the OS file picker hands back (Task seam for tests).
typedef PickedCert = ({Uint8List bytes, String name});

final universitiesProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(universityRepositoryProvider).listUniversities());

/// One agent-console line: the persisted log rendered verbatim.
class LogEntryTile extends StatelessWidget {
  const LogEntryTile({super.key, required this.entry});
  final VerificationLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color) = switch (entry.kind) {
      VerificationLogKind.user => (Icons.person_rounded, scheme.primary),
      VerificationLogKind.action => (Icons.settings_suggest_rounded, scheme.onSurfaceVariant),
      VerificationLogKind.ok => (Icons.check_circle_rounded, scheme.tertiary),
      VerificationLogKind.warn => (Icons.warning_amber_rounded, AppTokens.warning),
      VerificationLogKind.fail => (Icons.error_rounded, scheme.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, style: text.bodyMedium),
                if (entry.detail != null)
                  Text(entry.detail!,
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card chrome for the interactive step cards.
class WizardCard extends StatelessWidget {
  const WizardCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.space8),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTokens.space12),
          child,
        ],
      ),
    );
  }
}

class ProgramFormCard extends ConsumerStatefulWidget {
  const ProgramFormCard({super.key, required this.busy, this.initial, required this.onSubmit});
  final bool busy;
  final StudentProfile? initial;
  final void Function(String universityId, String course, int year, int semester) onSubmit;
  @override
  ConsumerState<ProgramFormCard> createState() => _ProgramFormCardState();
}

class _ProgramFormCardState extends ConsumerState<ProgramFormCard> {
  late final TextEditingController _course =
      TextEditingController(text: widget.initial?.major ?? '');
  String? _universityId;
  late int _year = (widget.initial?.studyYear ?? 1).clamp(1, 6);
  late int _semester = (widget.initial?.semester ?? 1).clamp(1, 3);

  @override
  void initState() {
    super.initState();
    _universityId = widget.initial?.universityId;
  }

  @override
  void dispose() {
    _course.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universities = ref.watch(universitiesProvider);
    return WizardCard(
      title: 'Your program',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          universities.when(
            loading: () => const LinearProgressIndicator(minHeight: 4),
            error: (e, _) => Text('Could not load universities: $e'),
            data: (list) {
              final ids = list.map((u) => u.id).toSet();
              final value = ids.contains(_universityId) ? _universityId : null;
              return InputDecorator(
                decoration: const InputDecoration(labelText: 'University'),
                child: DropdownButton<String>(
                  key: const Key('university-dd'),
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text('Select your university'),
                  items: [
                    for (final u in list) DropdownMenuItem(value: u.id, child: Text(u.name)),
                  ],
                  onChanged: (v) => setState(() => _universityId = v),
                ),
              );
            },
          ),
          const SizedBox(height: AppTokens.space12),
          TextField(
            key: const Key('course'),
            controller: _course,
            decoration: const InputDecoration(
              labelText: 'Course / program name',
              hintText: 'e.g. Computer Science',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Year'),
                  child: DropdownButton<int>(
                    key: const Key('year-dd'),
                    value: _year,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [for (var y = 1; y <= 6; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
                    onChanged: (v) => setState(() => _year = v ?? 1),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Semester'),
                  child: DropdownButton<int>(
                    key: const Key('semester-dd'),
                    value: _semester,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (var s = 1; s <= 3; s++) DropdownMenuItem(value: s, child: Text('Semester $s')),
                    ],
                    onChanged: (v) => setState(() => _semester = v ?? 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space16),
          FilledButton(
            key: const Key('verify-skills'),
            onPressed: (widget.busy || _universityId == null || _course.text.trim().isEmpty)
                ? null
                : () => widget.onSubmit(_universityId!, _course.text.trim(), _year, _semester),
            child: const Text('Verify my skills'),
          ),
        ],
      ),
    );
  }
}

class ConfirmProgramCard extends StatefulWidget {
  const ConfirmProgramCard({super.key, required this.busy, required this.candidates, required this.onDecide});
  final bool busy;
  final List<ProgramCandidate> candidates;
  final void Function(String? programId, bool accept) onDecide;
  @override
  State<ConfirmProgramCard> createState() => _ConfirmProgramCardState();
}

class _ConfirmProgramCardState extends State<ConfirmProgramCard> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return WizardCard(
      title: 'Confirm your program',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hand-rolled selection tiles: Radio*.groupValue is deprecated on
          // Flutter 3.35 and would break the analyze-clean gate.
          for (var i = 0; i < widget.candidates.length; i++)
            ListTile(
              dense: true,
              selected: i == _selected,
              leading: Icon(i == _selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded),
              title: Text(widget.candidates[i].name),
              subtitle: Text(widget.candidates[i].source == 'curated'
                  ? 'Curated curriculum'
                  : 'Found on public course pages'),
              onTap: () => setState(() => _selected = i),
            ),
          const SizedBox(height: AppTokens.space8),
          FilledButton(
            key: const Key('confirm-program'),
            onPressed: widget.busy || widget.candidates.isEmpty
                ? null
                : () => widget.onDecide(widget.candidates[_selected].id, true),
            child: const Text('Confirm'),
          ),
          TextButton(
            key: const Key('reject-program'),
            onPressed: widget.busy ? null : () => widget.onDecide(null, false),
            child: const Text("That's not my program"),
          ),
        ],
      ),
    );
  }
}

class SkillsSplitCard extends StatelessWidget {
  const SkillsSplitCard({
    super.key,
    required this.busy,
    required this.findings,
    required this.certifications,
    required this.onUpload,
    required this.onDone,
  });
  final bool busy;
  final VerificationFindings findings;
  final List<Certification> certifications;
  final VoidCallback? onUpload;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return WizardCard(
      title: 'Your verified skills',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (findings.lookupFailed)
            Container(
              padding: const EdgeInsets.all(AppTokens.space12),
              margin: const EdgeInsets.only(bottom: AppTokens.space12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
              child: Text(
                'We could not derive skills from your curriculum. Verify with '
                'certificates below, or finish now and retry later from "Update profile".',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (findings.taught.isNotEmpty) ...[
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                for (final s in findings.taught)
                  Chip(
                    avatar: Icon(Icons.verified_rounded, size: 16, color: scheme.tertiary),
                    label: Text('${s.skill} · Y${s.year}S${s.semester}'),
                  ),
              ],
            ),
          ] else if (!findings.lookupFailed)
            Text('No skills taught yet by your current semester — your honest profile starts here.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          if (findings.notYet.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            Text('Not taught yet', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            for (final s in findings.notYet)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${s.skill} — comes in Y${s.year}S${s.semester}. Got a certificate? Upload it.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
          ],
          for (final c in certifications) _CertTile(cert: c),
          if (onUpload != null) ...[
            const SizedBox(height: AppTokens.space12),
            OutlinedButton.icon(
              key: const Key('upload-cert'),
              onPressed: busy ? null : onUpload,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text('Upload a certificate'),
            ),
          ],
          const SizedBox(height: AppTokens.space12),
          FilledButton(
            key: const Key('certificates-done'),
            onPressed: busy ? null : onDone,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  const _CertTile({required this.cert});
  final Certification cert;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color, label) = switch (cert.status) {
      CertificationStatus.approved => (Icons.check_circle_rounded, scheme.tertiary, cert.reason ?? 'Approved'),
      CertificationStatus.rejected => (Icons.cancel_rounded, scheme.error, cert.reason ?? 'Rejected'),
      CertificationStatus.pending => (
          Icons.hourglass_top_rounded,
          AppTokens.warning,
          'Pending — will be re-checked automatically on your next run',
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cert.originalFilename != null)
                  Text(cert.originalFilename!,
                      style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PreferencesCard extends StatefulWidget {
  const PreferencesCard({super.key, required this.busy, this.initial, required this.onSave});
  final bool busy;
  final StudentProfile? initial;
  final void Function({
    required String growthStatement,
    DateTime? availabilityStart,
    int? durationWeeks,
    String? remotePref,
    int? salaryExpectation,
    required List<String> roleInterests,
    required List<String> industryInterests,
  }) onSave;
  @override
  State<PreferencesCard> createState() => _PreferencesCardState();
}

class _PreferencesCardState extends State<PreferencesCard> {
  static const _roles = ['Data', 'Design', 'Engineering', 'Marketing'];
  static const _industries = ['Tech', 'Analytics', 'Creative', 'Finance'];
  late final TextEditingController _growth =
      TextEditingController(text: widget.initial?.growthStatement ?? '');
  late final TextEditingController _salary = TextEditingController(
      text: widget.initial?.salaryExpectation?.toString() ?? '');
  late String _remote = widget.initial?.remotePref ?? 'any';
  late int _duration = widget.initial?.durationWeeks ?? 12;
  late DateTime? _availability = widget.initial?.availabilityStart;
  late final Set<String> _roleSel = {...widget.initial?.roleInterests ?? const []};
  late final Set<String> _industrySel = {...widget.initial?.industryInterests ?? const []};

  @override
  void dispose() {
    _growth.dispose();
    _salary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return WizardCard(
      title: 'Your preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('growth'),
            controller: _growth,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Where do you want to grow?',
              alignLabelWithHint: true,
              hintText: 'e.g. ship real backend features with senior engineers',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Remote preference'),
                  child: DropdownButton<String>(
                    value: _remote,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'any', child: Text('Any')),
                      DropdownMenuItem(value: 'remote', child: Text('Remote')),
                      DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                      DropdownMenuItem(value: 'onsite', child: Text('Onsite')),
                    ],
                    onChanged: (v) => setState(() => _remote = v ?? 'any'),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Duration'),
                  child: DropdownButton<int>(
                    value: _duration,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 8, child: Text('8 weeks')),
                      DropdownMenuItem(value: 10, child: Text('10 weeks')),
                      DropdownMenuItem(value: 12, child: Text('12 weeks')),
                      DropdownMenuItem(value: 16, child: Text('16 weeks')),
                    ],
                    onChanged: (v) => setState(() => _duration = v ?? 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('salary'),
                  controller: _salary,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Salary expectation (RM/month)'),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _availability ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) setState(() => _availability = picked);
                  },
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(_availability == null
                      ? 'Available from…'
                      : _availability!.toIso8601String().substring(0, 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          Text('Interests (optional)', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTokens.space8),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              for (final r in _roles)
                FilterChip(
                  label: Text(r),
                  selected: _roleSel.contains(r),
                  onSelected: (v) => setState(() => v ? _roleSel.add(r) : _roleSel.remove(r)),
                ),
              for (final i in _industries)
                FilterChip(
                  label: Text(i),
                  selected: _industrySel.contains(i),
                  onSelected: (v) => setState(() => v ? _industrySel.add(i) : _industrySel.remove(i)),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space16),
          FilledButton(
            key: const Key('save-preferences'),
            onPressed: (widget.busy || _growth.text.trim().isEmpty)
                ? null
                : () => widget.onSave(
                      growthStatement: _growth.text.trim(),
                      availabilityStart: _availability,
                      durationWeeks: _duration,
                      remotePref: _remote,
                      salaryExpectation: int.tryParse(_salary.text.trim()),
                      roleInterests: _roleSel.toList(),
                      industryInterests: _industrySel.toList(),
                    ),
            child: const Text('Save preferences'),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.busy,
    required this.findings,
    required this.certifications,
    required this.onFinish,
  });
  final bool busy;
  final VerificationFindings findings;
  final List<Certification> certifications;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final approved = certifications.where((c) => c.status == CertificationStatus.approved).toList();
    final total = findings.taught.length + approved.length;
    return WizardCard(
      title: 'What employers will see',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$total verified skill${total == 1 ? '' : 's'} — every one proven by your '
            'curriculum or a checked certificate. You stay anonymous until you match.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space12),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            children: [
              for (final s in findings.taught)
                Chip(
                  avatar: Icon(Icons.school_rounded, size: 16, color: scheme.tertiary),
                  label: Text(s.skill),
                ),
              for (final c in approved)
                Chip(
                  avatar: Icon(Icons.workspace_premium_rounded, size: 16, color: scheme.tertiary),
                  label: Text(c.skillName ?? (c.originalFilename ?? 'Certificate')),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space16),
          FilledButton(
            key: const Key('finish'),
            onPressed: busy ? null : onFinish,
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}
