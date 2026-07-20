import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('marketDemand', () {
    test('weights each skill by 1 + matchCount across the jobs that list it, ranked desc', () {
      final demand = marketDemand(const [
        JobDemandInput(skills: ['SQL', 'Python'], matchCount: 3), // each +4
        JobDemandInput(skills: ['SQL'], matchCount: 0),           // SQL +1
        JobDemandInput(skills: ['Figma'], matchCount: 1),         // Figma +2
      ]);
      expect(demand.first.skill, 'SQL');       // 4 + 1 = 5, highest
      expect(demand.first.weight, 5);
      expect(demand.map((d) => d.skill), containsAllInOrder(['SQL', 'Python']));
    });
  });

  group('curriculumGap', () {
    test('returns in-demand skills not in the curriculum, in demand order', () {
      final demand = const [
        SkillDemand(skill: 'SQL', weight: 5),
        SkillDemand(skill: 'Python', weight: 4),
        SkillDemand(skill: 'Figma', weight: 2),
      ];
      final gap = curriculumGap(demand, {'SQL'});
      expect(gap, ['Python', 'Figma']); // SQL taught → excluded
    });
  });

  group('placementRate', () {
    test('placed ÷ total students; zero when there are no students', () {
      expect(placementRate(3, 12), closeTo(0.25, 1e-9));
      expect(placementRate(0, 0), 0);
    });
  });
}
