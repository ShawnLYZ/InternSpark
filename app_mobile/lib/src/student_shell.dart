import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'deck_screen.dart';
import 'leaderboard_screen.dart';
import 'matches_screen.dart';
import 'profile_screen.dart';

final studentProfileProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(studentRepositoryProvider).fetchMyStudentProfile());
final availableJobsProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(studentRepositoryProvider).countAvailableJobs());

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});
  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _tab = 0;
  static const _labels = ['Home', 'Discover', 'Matches', 'Leaderboard', 'Profile'];

  void _goDiscover() => setState(() => _tab = 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppTokens.space16,
        title: _tab == 0
            ? const BrandMark(size: 30)
            : Text(_labels[_tab]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: AppTokens.space4),
        ],
      ),
      body: switch (_tab) {
        0 => _StudentHome(onStartSwiping: _goDiscover),
        1 => const DeckScreen(),
        2 => const MatchesScreen(),
        3 => const LeaderboardScreen(),
        _ => const ProfileScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style_rounded), label: 'Discover'),
          NavigationDestination(
              icon: Icon(Icons.favorite_outline_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Matches'),
          NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard_rounded), label: 'Leaderboard'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StudentHome extends ConsumerWidget {
  const _StudentHome({required this.onStartSwiping});
  final VoidCallback onStartSwiping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(studentProfileProvider);
    final jobs = ref.watch(availableJobsProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppTokens.space20),
      children: [
        profile.when(
          loading: () => Text('Welcome', style: text.headlineMedium),
          error: (e, _) => Text('Welcome', style: text.headlineMedium),
          data: (p) => Text('Welcome, ${p?.fullName ?? 'student'}',
              style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        Text("Ready to find where you'll grow?",
            style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppTokens.space20),

        // Hero: available internships + CTA into the deck.
        Container(
          padding: const EdgeInsets.all(AppTokens.space20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            boxShadow: AppTokens.shadowMd(scheme.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.style_rounded, color: Colors.white, size: 30),
                  const SizedBox(width: AppTokens.space12),
                  Expanded(
                    child: jobs.when(
                      loading: () => Text('Finding internships…',
                          style: text.titleMedium?.copyWith(color: Colors.white)),
                      error: (e, _) => Text('Internships await',
                          style: text.titleMedium?.copyWith(color: Colors.white)),
                      data: (n) => Text('$n internships available',
                          style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Swipe right to apply, left to pass. Watch a day-in-the-life before you commit.',
                  style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
              const SizedBox(height: AppTokens.space16),
              FilledButton.icon(
                onPressed: onStartSwiping,
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('Start swiping'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space24),

        const SectionHeader('How InternSpark works', icon: Icons.auto_awesome_rounded),
        const _TipTile(
          icon: Icons.swipe_rounded,
          title: 'Swipe with intent',
          body: 'Cards are ranked by how well the role grows your skills — not just keywords.',
        ),
        const _TipTile(
          icon: Icons.lock_outline_rounded,
          title: "You're anonymous until it's mutual",
          body: 'Employers only see your name after you both match.',
        ),
        const _TipTile(
          icon: Icons.verified_outlined,
          title: 'Ghost-busting transparency',
          body: 'Every company shows its real response rate before you apply.',
        ),
      ],
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
