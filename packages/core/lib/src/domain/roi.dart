/// One job's skill footprint for demand weighting.
class JobDemandInput {
  const JobDemandInput({required this.skills, this.matchCount = 0});
  final List<String> skills;
  final int matchCount;
}

/// A skill with its computed demand weight.
class SkillDemand {
  const SkillDemand({required this.skill, required this.weight, this.skillId = ''});
  final String skill;
  final double weight;
  final String skillId;
}

/// Market demand = Σ over jobs listing the skill of (1 + matchCount); ranked desc.
/// Mirrors the `market_demand` SQL view.
List<SkillDemand> marketDemand(List<JobDemandInput> jobs) {
  final weights = <String, double>{};
  for (final j in jobs) {
    final w = 1 + j.matchCount;
    for (final s in j.skills) {
      weights[s] = (weights[s] ?? 0) + w;
    }
  }
  final out = [for (final e in weights.entries) SkillDemand(skill: e.key, weight: e.value)]
    ..sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      return byWeight != 0 ? byWeight : a.skill.compareTo(b.skill);
    });
  return out;
}

/// Curriculum gap = in-demand skills not in [curriculum], preserving demand order.
List<String> curriculumGap(List<SkillDemand> demand, Set<String> curriculum) {
  final taught = curriculum.map((s) => s.toLowerCase()).toSet();
  return [for (final d in demand) if (!taught.contains(d.skill.toLowerCase())) d.skill];
}

/// Placement rate = students with an accepted offer ÷ the university's students.
double placementRate(int placedStudents, int totalStudents) =>
    totalStudents == 0 ? 0 : placedStudents / totalStudents;
