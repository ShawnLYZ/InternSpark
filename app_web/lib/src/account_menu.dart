import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

/// The single account action for both web shells (Reuse Register: one
/// implementation, two call sites). Sign-out lands on the login screen via
/// the auth gate's existing auth-state listener — no navigation here.
class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out of InternSpark?'),
        content: const Text('Your workspace will be secured until you sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('confirm-sign-out'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(authRepositoryProvider).signOut();
      if (!context.mounted) return;
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      key: const Key('account-menu'),
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (v) {
        if (v == 'signout') _confirmSignOut(context, ref);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18),
              SizedBox(width: AppTokens.space8),
              Text('Sign out'),
            ],
          ),
        ),
      ],
    );
  }
}
