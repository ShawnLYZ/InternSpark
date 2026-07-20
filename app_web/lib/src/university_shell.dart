import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

import 'account_menu.dart';
import 'chat_screen.dart';
import 'credit_queue_screen.dart';
import 'roi_dashboard_screen.dart';
import 'university_reports_screen.dart';

final myUniversityProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(universityRepositoryProvider).fetchMyUniversity());

class UniversityShell extends ConsumerWidget {
  const UniversityShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final university = ref.watch(myUniversityProvider);
    final name = university.asData?.value?.name;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.space24,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 28, showWordmark: false),
            const SizedBox(width: AppTokens.space12),
            Flexible(child: Text(name ?? 'University')),
          ],
        ),
        actions: [
          _NavAction(
            icon: Icons.folder_shared_outlined,
            label: 'Reports',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const UniversityReportsScreen())),
          ),
          _NavAction(
            icon: Icons.forum_outlined,
            label: 'Chat',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
          ),
          _NavAction(
            icon: Icons.verified_outlined,
            label: 'Credits',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CreditQueueScreen())),
          ),
          const AccountMenu(),
          const SizedBox(width: AppTokens.space16),
        ],
      ),
      body: const RoiDashboardScreen(),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
