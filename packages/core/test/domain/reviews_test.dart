import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('canReview', () {
    Application app(String companyId, ApplicationStatus status) =>
        Application(id: 'a', jobId: 'j', jobTitle: 't', companyName: 'C', companyId: companyId, status: status);

    test('a matched/interned student may review that company', () {
      expect(canReview(companyId: 'c1', applications: [app('c1', ApplicationStatus.matched)]), isTrue);
      expect(canReview(companyId: 'c1', applications: [app('c1', ApplicationStatus.accepted)]), isTrue);
    });

    test('a merely applied (not matched) student may not', () {
      expect(canReview(companyId: 'c1', applications: [app('c1', ApplicationStatus.applied)]), isFalse);
    });

    test('eligibility is per company', () {
      expect(canReview(companyId: 'c2', applications: [app('c1', ApplicationStatus.matched)]), isFalse);
    });
  });

  group('mentorshipScore', () {
    test('is the mean mentorship rating; 0 when empty', () {
      expect(mentorshipScore(const [
        Review(mentorship: 4, workload: 3, psychSafety: 5),
        Review(mentorship: 2, workload: 2, psychSafety: 2),
      ]), 3.0);
      expect(mentorshipScore(const []), 0);
    });
  });

  group('containsProfanity', () {
    test('flags whole-word profanity', () {
      expect(containsProfanity('This was a damn waste of time'), isTrue);
    });
    test('does not flag substrings inside clean words', () {
      expect(containsProfanity('We assessed the classwork'), isFalse); // "ass" inside "assessed"
    });
    test('clean text passes', () {
      expect(containsProfanity('Great mentorship and fair workload'), isFalse);
    });
  });
}
