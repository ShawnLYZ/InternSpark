import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final myThreadsProvider = FutureProvider.autoDispose((ref) => ref.watch(chatRepositoryProvider).myThreads());

final threadMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
    (ref, threadId) => ref.watch(chatRepositoryProvider).messages(threadId));

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(myThreadsProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Coordination chat')),
      body: threads.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(message: 'Error: $e'),
        data: (rows) => rows.isEmpty
            ? const AppEmpty(icon: Icons.forum_outlined, message: 'No placed students to coordinate on yet.')
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    children: [
                      for (final t in rows)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppTokens.space12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(Icons.person_rounded, color: scheme.onPrimaryContainer),
                            ),
                            title: Text(t.studentName,
                                style: Theme.of(context).textTheme.titleMedium),
                            subtitle: Text('${t.companyName} ↔ ${t.universityName}'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => ChatThreadView(thread: t))),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class ChatThreadView extends ConsumerStatefulWidget {
  const ChatThreadView({super.key, required this.thread});
  final ChatThread thread;
  @override
  ConsumerState<ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends ConsumerState<ChatThreadView> {
  final _input = TextEditingController();

  Future<void> _send() async {
    final body = _input.text.trim();
    if (body.isEmpty) return;
    _input.clear();
    await ref.read(chatRepositoryProvider).sendMessage(threadId: widget.thread.threadId, body: body);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(threadMessagesProvider(widget.thread.threadId));
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.thread.studentName)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: messages.when(
                  loading: () => const AppLoading(),
                  error: (e, _) => AppError(message: 'Error: $e'),
                  data: (rows) => ListView(
                    padding: const EdgeInsets.all(AppTokens.space16),
                    children: [for (final m in rows) _Bubble(body: m.body)],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(hintText: 'Message'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    IconButton.filled(
                      key: const Key('send'),
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.space8),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: AppTokens.space12),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(AppTokens.radiusMd),
            bottomLeft: Radius.circular(AppTokens.radiusMd),
            bottomRight: Radius.circular(AppTokens.radiusMd),
          ),
        ),
        child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
