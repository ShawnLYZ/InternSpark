import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('buildResumeRequest — grounding', () {
    test('sends only entered student fields + the job framing', () {
      final req = buildResumeRequest(
        fullName: 'Sam Rivera',
        major: 'Computer Science',
        growthStatement: 'Grow into data products.',
        skills: const ['SQL', 'Python'],
        experiences: const ['Built a class dashboard', 'TA for CS101'],
        jobTitle: 'Data Analyst Intern',
        jobDescription: 'Build dashboards.',
        jobRequiredSkills: const ['SQL', 'Python', 'Figma'],
        jobIndustry: 'Analytics',
      );
      expect(req['student'].keys, containsAll(['full_name', 'skills', 'experiences']));
      // Grounding: nothing beyond entered student data is present.
      expect(req['student'].containsKey('fabricated'), isFalse);
      expect((req['student']['experiences'] as List), ['Built a class dashboard', 'TA for CS101']);
      expect(req['job']['title'], 'Data Analyst Intern');
    });

    test('omits empty/null entered fields (never sends placeholders)', () {
      final req = buildResumeRequest(
        fullName: 'Sam Rivera',
        major: null,
        growthStatement: '',
        skills: const [],
        experiences: const [],
        jobTitle: 'X',
        jobDescription: '',
        jobRequiredSkills: const [],
        jobIndustry: null,
      );
      expect(req['student'].containsKey('major'), isFalse);
      expect(req['student'].containsKey('growth_statement'), isFalse);
      expect(req['student'].containsKey('skills'), isFalse);
    });
  });

  group('redactName', () {
    test('replaces only the name; body is untouched', () {
      const r = ResumeJson(
        name: 'Sam Rivera', headline: 'Aspiring analyst', summary: 'Builds dashboards.',
        sections: [ResumeSection(title: 'Experience', bullets: ['TA for CS101'])],
      );
      final red = redactName(r);
      expect(red.name, 'Candidate');
      expect(red.headline, 'Aspiring analyst');
      expect(red.sections.first.bullets, ['TA for CS101']);
    });
  });
}
