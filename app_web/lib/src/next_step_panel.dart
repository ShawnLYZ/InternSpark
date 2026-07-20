import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'applicants_screen.dart';

/// Post-match actions (matched/interview): request interview / make offer / pass.
class NextStepPanel extends ConsumerWidget {
  const NextStepPanel({super.key, required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(applicantsRepositoryProvider);
    void refresh() => ref.invalidate(applicantsProvider);
    return Wrap(
      spacing: AppTokens.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          key: const Key('pass'),
          onPressed: () async {
            await repo.pass(applicationId);
            refresh();
          },
          child: const Text('Pass'),
        ),
        OutlinedButton.icon(
          key: const Key('interview'),
          onPressed: () async {
            await repo.requestInterview(
              applicationId: applicationId,
              email: 'hiring@nimbus.demo',
              link: 'https://meet.demo/abc',
              date: DateTime.now().add(const Duration(days: 3)),
            );
            refresh();
          },
          icon: const Icon(Icons.event_outlined, size: 18),
          label: const Text('Interview'),
        ),
        FilledButton.icon(
          key: const Key('offer'),
          onPressed: () async {
            await repo.makeOffer(applicationId);
            refresh();
          },
          icon: const Icon(Icons.workspace_premium_outlined, size: 18),
          label: const Text('Make offer'),
        ),
      ],
    );
  }
}
