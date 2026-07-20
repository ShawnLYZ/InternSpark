import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:printing/printing.dart';

/// Shown after swipe-right: edit the grounded resume, optionally preview the PDF,
/// then attach it to the application.
class ResumeReviewScreen extends ConsumerStatefulWidget {
  const ResumeReviewScreen({super.key, required this.applicationId, required this.jobId});
  final String applicationId;
  final String jobId;
  @override
  ConsumerState<ResumeReviewScreen> createState() => _ResumeReviewScreenState();
}

class _ResumeReviewScreenState extends ConsumerState<ResumeReviewScreen> {
  ResumeJson? _resume;
  final _headline = TextEditingController();
  final _summary = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  void dispose() {
    _headline.dispose();
    _summary.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    final r = await ref.read(resumeRepositoryProvider).generateResume(widget.jobId);
    setState(() {
      _resume = r;
      _headline.text = r.headline;
      _summary.text = r.summary;
      _busy = false;
    });
  }

  ResumeJson get _edited => _resume!.copyWith(headline: _headline.text, summary: _summary.text);

  Future<void> _attach() async {
    setState(() => _busy = true);
    await ref
        .read(resumeRepositoryProvider)
        .attachResume(applicationId: widget.applicationId, resume: _edited);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final r = _resume;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Review your resume')),
      body: (r == null || _busy)
          ? const AppLoading()
          : ListView(
              padding: const EdgeInsets.all(AppTokens.space20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.name,
                          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    const Pill('AI-drafted', icon: Icons.auto_awesome_rounded, tone: PillTone.info),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Grounded in your profile and this role. Edit anything before you send.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: AppTokens.space20),
                TextField(
                  controller: _headline,
                  decoration: const InputDecoration(labelText: 'Headline'),
                ),
                const SizedBox(height: AppTokens.space12),
                TextField(
                  controller: _summary,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Summary', alignLabelWithHint: true),
                ),
                const SizedBox(height: AppTokens.space24),
                for (final s in r.sections) ...[
                  SectionHeader(s.title, icon: Icons.check_circle_outline_rounded),
                  Container(
                    margin: const EdgeInsets.only(bottom: AppTokens.space16),
                    padding: const EdgeInsets.all(AppTokens.space16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final b in s.bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, right: 8),
                                  child: Icon(Icons.circle, size: 6, color: scheme.primary),
                                ),
                                Expanded(child: Text(b, style: text.bodyMedium)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space8),
                OutlinedButton.icon(
                  key: const Key('preview'),
                  onPressed: () => Printing.layoutPdf(onLayout: (_) => buildResumePdf(_edited)),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Preview PDF'),
                ),
                const SizedBox(height: AppTokens.space12),
                FilledButton(
                  key: const Key('attach'),
                  onPressed: _attach,
                  child: const Text('Attach & apply'),
                ),
              ],
            ),
    );
  }
}
