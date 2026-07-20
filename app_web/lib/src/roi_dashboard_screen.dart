import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';

final roiProvider = FutureProvider.autoDispose((ref) => ref.watch(roiRepositoryProvider).fetchRoi());

class RoiDashboardScreen extends ConsumerWidget {
  const RoiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roi = ref.watch(roiProvider);
    final text = Theme.of(context).textTheme;

    return roi.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: 'Error: $e'),
      data: (s) {
        final gapSet = s.gap.toSet();
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTokens.contentMaxWidth),
            child: ListView(
              // Build the whole dashboard (chart + gap chips) even below the
              // fold so it's reachable without partial-render surprises.
              cacheExtent: 2000,
              padding: const EdgeInsets.all(AppTokens.space24),
              children: [
                Text('Program outcomes',
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('How your students fare in the market — and where the curriculum can close gaps.',
                    style: text.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: AppTokens.space24),

                // Metric tiles.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 560;
                    final tiles = [
                      StatTile(
                        value: '${(s.placementRate * 100).round()}%',
                        label: 'Placement rate',
                        icon: Icons.school_outlined,
                        tone: PillTone.success,
                      ),
                      StatTile(
                        value: '${s.demand.length}',
                        label: 'In-demand skills tracked',
                        icon: Icons.insights_outlined,
                        tone: PillTone.info,
                      ),
                      StatTile(
                        value: '${s.gap.length}',
                        label: 'Curriculum gaps',
                        icon: Icons.report_gmailerrorred_outlined,
                        tone: s.gap.isEmpty ? PillTone.success : PillTone.warning,
                      ),
                    ];
                    return Wrap(
                      spacing: AppTokens.space16,
                      runSpacing: AppTokens.space16,
                      children: [
                        for (final t in tiles)
                          SizedBox(
                            width: twoCol ? (constraints.maxWidth - 2 * AppTokens.space16) / 3 : constraints.maxWidth,
                            child: t,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTokens.space32),

                const SectionHeader('Curriculum gap', icon: Icons.rule_folder_outlined),
                _Panel(
                  child: s.gap.isEmpty
                      ? Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: AppTokens.success, size: 20),
                            const SizedBox(width: AppTokens.space8),
                            Expanded(
                              child: Text('No gap — your curriculum covers the in-demand skills.',
                                  style: text.bodyMedium),
                            ),
                          ],
                        )
                      : Wrap(
                          spacing: AppTokens.space8,
                          runSpacing: AppTokens.space8,
                          children: [
                            for (final skill in s.gap)
                              Chip(
                                avatar: const Icon(Icons.priority_high_rounded, size: 16),
                                label: Text(skill),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: AppTokens.space24),

                const SectionHeader('Market demand', icon: Icons.trending_up_rounded),
                _Panel(child: DemandBarChart(demand: s.demand, gap: gapSet)),
                const SizedBox(height: AppTokens.space24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _editCurriculum(context, ref),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Manage curriculum'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCurriculum(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(roiRepositoryProvider);
    final all = await repo.allSkills();
    final current = (await repo.curriculumSkills()).map((s) => s.id).toSet();
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Curriculum skills'),
          content: SizedBox(
            width: 360,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final skill in all)
                  CheckboxListTile(
                    title: Text(skill.name),
                    value: current.contains(skill.id),
                    onChanged: (v) async {
                      if (v == true) {
                        await repo.addCurriculumSkill(skill.id);
                        current.add(skill.id);
                      } else {
                        await repo.removeCurriculumSkill(skill.id);
                        current.remove(skill.id);
                      }
                      setState(() {});
                    },
                  ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
        ),
      ),
    );
    ref.invalidate(roiProvider);
  }
}

/// A bordered surface panel used to frame dashboard content.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTokens.space20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}
