import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'student_shell.dart' show studentProfileProvider;
import 'verification_wizard_screen.dart';

final verifiedSkillsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(studentRepositoryProvider).fetchMyVerifiedSkills());

/// The student's real Profile tab: identity, verified skills (added with the
/// verification feature), and sign-out. Replaces the Phase-0 placeholder.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out of InternSpark?'),
        content: const Text('You will need to sign in again to keep swiping.'),
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
    final profile = ref.watch(studentProfileProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppTokens.space20),
      children: [
        profile.when(
          loading: () => const AppLoading(),
          error: (e, _) => AppError(message: 'Could not load your profile: $e'),
          data: (p) => Container(
            padding: const EdgeInsets.all(AppTokens.space20),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(Icons.person_rounded, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppTokens.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p?.fullName ?? 'Student',
                          style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      if (p?.major != null)
                        Text(p!.major!,
                            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      if (p?.universityName != null)
                        Text(p!.universityName!,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space24),
        const SectionHeader('Verified skills', icon: Icons.verified_outlined),
        Consumer(builder: (context, ref, _) {
          final skills = ref.watch(verifiedSkillsProvider);
          return skills.when(
            loading: () => const AppLoading(),
            error: (e, _) => AppError(message: 'Could not load skills: $e'),
            data: (list) => list.isEmpty
                ? Text('No verified skills yet — run "Update profile" to verify.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))
                : Column(
                    children: [
                      for (final s in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppTokens.space8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(s.name,
                                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                                ),
                                child: Text(s.provenanceLabel,
                                    style: text.labelSmall?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          );
        }),
        const SizedBox(height: AppTokens.space16),
        FilledButton.icon(
          key: const Key('update-profile'),
          onPressed: () async {
            await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VerificationWizardScreen()));
            ref.invalidate(verifiedSkillsProvider);
            ref.invalidate(studentProfileProvider);
            ref.invalidate(needsVerificationProvider);
          },
          icon: const Icon(Icons.autorenew_rounded, size: 20),
          label: const Text('Update profile'),
        ),
        const SizedBox(height: AppTokens.space24),
        OutlinedButton.icon(
          key: const Key('sign-out'),
          onPressed: () => _confirmSignOut(context, ref),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
        ),
      ],
    );
  }
}
