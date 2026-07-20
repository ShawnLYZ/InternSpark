import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

class JobFormScreen extends ConsumerStatefulWidget {
  const JobFormScreen({super.key, this.existing, this.onSaved});
  final Job? existing;
  final VoidCallback? onSaved;
  @override
  ConsumerState<JobFormScreen> createState() => _JobFormScreenState();
}

class _JobFormScreenState extends ConsumerState<JobFormScreen> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late final _growth = TextEditingController(text: widget.existing?.growthText ?? '');
  String _remoteMode = 'remote';
  bool _busy = false;
  String? _savedJobId;
  String _sandboxSource = 'none';
  final _sandboxPrompt = TextEditingController();

  Future<void> _draft() async {
    setState(() => _busy = true);
    final text = await ref.read(jobRepositoryProvider).draftGrowthText(_title.text, _description.text);
    setState(() {
      _growth.text = text;
      _busy = false;
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final id = await ref.read(jobRepositoryProvider).upsertJob({
      if (widget.existing != null) 'id': widget.existing!.id,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'growth_text': _growth.text.trim(),
      'remote_mode': _remoteMode,
      'published': true,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _savedJobId = id;
    });
    if (mounted && widget.onSaved != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved. You can now add a video.')));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _growth.dispose();
    _sandboxPrompt.dispose();
    super.dispose();
  }

  Widget _aiDraftButton(VoidCallback? onPressed) => Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('AI draft')],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New job' : 'Edit job')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.space24),
            children: [
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: AppTokens.space12),
              TextField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: AppTokens.space12),
              TextField(
                controller: _growth,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Where will they grow? (growth_text)', alignLabelWithHint: true),
              ),
              _aiDraftButton(_busy ? null : _draft),
              const SizedBox(height: AppTokens.space4),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Remote mode'),
                child: DropdownButton<String>(
                  value: _remoteMode,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'remote', child: Text('Remote')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                    DropdownMenuItem(value: 'onsite', child: Text('Onsite')),
                  ],
                  onChanged: (v) => setState(() => _remoteMode = v ?? 'remote'),
                ),
              ),
              const SizedBox(height: AppTokens.space20),
              FilledButton(onPressed: _busy ? null : _save, child: const Text('Save job')),
              const SizedBox(height: AppTokens.space12),
              OutlinedButton.icon(
                onPressed: _savedJobId == null
                    ? null
                    : () async {
                        final picked = await FilePicker.pickFiles(type: FileType.video, withData: true);
                        final file = picked?.files.single;
                        if (file?.bytes == null) return;
                        await ref
                            .read(jobRepositoryProvider)
                            .setJobVideo(jobId: _savedJobId!, bytes: file!.bytes!, fileName: file.name);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Day-in-the-life video attached.')));
                        }
                      },
                icon: const Icon(Icons.video_call_outlined),
                label: const Text('Add day-in-the-life video (≤60s)'),
              ),
              const Divider(height: AppTokens.space32),
              const SectionHeader('48h try-out (sandbox)', icon: Icons.bolt_rounded),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Source'),
                child: DropdownButton<String>(
                  value: _sandboxSource,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'author', child: Text('Author my own')),
                    DropdownMenuItem(value: 'ai', child: Text('AI-generate')),
                  ],
                  onChanged: (v) => setState(() => _sandboxSource = v ?? 'none'),
                ),
              ),
              if (_sandboxSource != 'none') ...[
                const SizedBox(height: AppTokens.space12),
                TextField(
                  controller: _sandboxPrompt,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Try-out task prompt', alignLabelWithHint: true),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: (_savedJobId == null || _sandboxSource != 'ai')
                        ? null
                        : () async {
                            final p = await ref.read(sandboxRepositoryProvider).generatePrompt(_savedJobId!);
                            setState(() => _sandboxPrompt.text = p);
                          },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Icon(Icons.auto_awesome, size: 18), SizedBox(width: 8), Text('AI draft task')],
                    ),
                  ),
                ),
                FilledButton.tonal(
                  key: const Key('approve-sandbox'),
                  onPressed: _savedJobId == null
                      ? null
                      : () async {
                          await ref.read(sandboxRepositoryProvider).configureSandbox(
                              jobId: _savedJobId!,
                              source: _sandboxSource,
                              prompt: _sandboxPrompt.text.trim(),
                              approved: true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(content: Text('48h try-out enabled.')));
                          }
                        },
                  child: const Text('Approve & enable try-out'),
                ),
              ],
              if (_savedJobId != null) ...[
                const SizedBox(height: AppTokens.space16),
                FilledButton(onPressed: () => widget.onSaved?.call(), child: const Text('Done')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
