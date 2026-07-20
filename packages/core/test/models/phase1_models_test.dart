import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('DeckCandidate.fromJson maps the deck RPC row', () {
    final c = DeckCandidate.fromJson({
      'job_id': 'j1', 'title': 'Data Analyst Intern', 'growth_text': 'grow', 'company_name': 'Nimbus',
      'cosine_sim': 0.8, 'matched_skills': 2, 'required_skills': 3, 'has_sandbox': true,
    });
    expect(c.jobId, 'j1');
    expect(c.cosineSim, 0.8);
    expect(c.requiredSkills, 3);
    expect(c.withScore(0.9).score, 0.9);
  });

  test('Application.fromJson maps status wire + matched_at', () {
    final a = Application.fromJson({
      'id': 'a1', 'job_id': 'j1', 'job_title': 'UX', 'company_name': 'Brightway',
      'status': 'matched', 'matched_at': '2026-07-01T12:00:00Z',
    });
    expect(a.status, ApplicationStatus.matched);
    expect(a.matchedAt, DateTime.utc(2026, 7, 1, 12));
  });

  test('ApplicantRow hides identity until matched', () {
    final masked = ApplicantRow.fromJson({
      'application_id': 'a1', 'status': 'applied', 'matched': false,
      'full_name': null, 'required_skills': ['SQL'], 'student_skills': ['SQL', 'Python'],
    });
    expect(masked.matched, isFalse);
    expect(masked.fullName, isNull);
    expect(masked.requiredSkills, ['SQL']);
  });

  test('Job.fromJson parses start_date', () {
    final job = Job.fromJson({'id': 'j1', 'company_id': 'c1', 'title': 'X', 'start_date': '2026-07-01'});
    expect(job.startDate, DateTime(2026, 7, 1));
  });
}
