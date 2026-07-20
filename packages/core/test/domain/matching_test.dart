import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('hardFilter', () {
    final base = {
      'studentRemotePref': 'remote',
      'studentAvailabilityStart': DateTime(2026, 7, 1),
      'studentDurationWeeks': 16,
      'jobRemoteMode': 'remote',
      'jobStartDate': DateTime(2026, 7, 1),
      'jobDurationWeeks': 12,
    };

    bool call(Map<String, Object?> o) => hardFilter(
          studentRemotePref: o['studentRemotePref'] as String?,
          studentAvailabilityStart: o['studentAvailabilityStart'] as DateTime?,
          studentDurationWeeks: o['studentDurationWeeks'] as int?,
          jobRemoteMode: o['jobRemoteMode'] as String?,
          jobStartDate: o['jobStartDate'] as DateTime?,
          jobDurationWeeks: o['jobDurationWeeks'] as int?,
        );

    test('passes when remote + availability fit', () => expect(call(base), isTrue));

    test('remote student is excluded from an onsite job', () {
      expect(call({...base, 'jobRemoteMode': 'onsite'}), isFalse);
    });

    test('remote student is allowed into a hybrid job', () {
      expect(call({...base, 'jobRemoteMode': 'hybrid'}), isTrue);
    });

    test('a job starting before the student is available is excluded', () {
      expect(call({...base, 'jobStartDate': DateTime(2026, 6, 1)}), isFalse);
    });

    test('a job longer than the student can commit is excluded', () {
      expect(call({...base, 'studentDurationWeeks': 8}), isFalse);
    });

    test('null fields never exclude (minimal filter)', () {
      expect(
        hardFilter(
          studentRemotePref: null, studentAvailabilityStart: null, studentDurationWeeks: null,
          jobRemoteMode: null, jobStartDate: null, jobDurationWeeks: null,
        ),
        isTrue,
      );
    });
  });

  group('soft-signal helpers', () {
    test('salaryFit is 1.0 when the job ceiling meets the ask, neutral when unknown', () {
      expect(salaryFit(2500, 2000, 2800), 1.0);
      expect(salaryFit(2500, null, null), 0.5);
      expect(salaryFit(3000, 2000, 2400), closeTo(0.8, 1e-9)); // 2400/3000
    });

    test('skillOverlapRatio is matched/required, and 1.0 when nothing is required', () {
      expect(skillOverlapRatio(2, 4), 0.5);
      expect(skillOverlapRatio(0, 0), 1.0);
    });
  });

  group('deckScore + sortDeck', () {
    test('default weights blend the five signals into 0..1', () {
      final s = deckScore(
        cosineSim: 1.0, skillOverlap: 1.0, salaryFit: 1.0, roleMatch: true, industryMatch: true,
      );
      expect(s, closeTo(1.0, 1e-9));
    });

    test('cosine dominates under default weights', () {
      final high = deckScore(cosineSim: 0.9, skillOverlap: 0, salaryFit: 0, roleMatch: false, industryMatch: false);
      final low = deckScore(cosineSim: 0.1, skillOverlap: 1, salaryFit: 1, roleMatch: true, industryMatch: true);
      expect(high, greaterThan(low));
    });

    test('sortDeck orders by score desc, tie-broken by jobId', () {
      final out = sortDeck([
        const DeckCandidate(jobId: 'b', title: '', growthText: '', companyName: '', score: 0.5),
        const DeckCandidate(jobId: 'a', title: '', growthText: '', companyName: '', score: 0.9),
        const DeckCandidate(jobId: 'c', title: '', growthText: '', companyName: '', score: 0.5),
      ]);
      expect(out.map((c) => c.jobId).toList(), ['a', 'b', 'c']);
    });
  });

  group('fitScore', () {
    test('percent = matched / required, chips are the intersection', () {
      final r = fitScore(requiredSkills: ['SQL', 'Python', 'Figma'], studentSkills: ['python', 'sql', 'git']);
      expect(r.percent, closeTo(2 / 3, 1e-9));
      expect(r.matchedChips, containsAll(['Python', 'SQL']));
      expect(r.matchedChips, isNot(contains('Figma')));
    });

    test('no required skills yields 1.0 and no chips', () {
      final r = fitScore(requiredSkills: const [], studentSkills: const ['SQL']);
      expect(r.percent, 1.0);
      expect(r.matchedChips, isEmpty);
    });
  });
}
