import '../domain/application_status.dart';

/// A student-side `applications` row joined with its job title, for Matches/Status.
class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    this.companyId = '',
    this.matchedAt,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String companyId;
  final ApplicationStatus status;
  final DateTime? matchedAt;

  static ApplicationStatus statusFromWire(String w) => switch (w) {
        'passed' => ApplicationStatus.passed,
        'applied' => ApplicationStatus.applied,
        'rejected' => ApplicationStatus.rejected,
        'matched' => ApplicationStatus.matched,
        'interview' => ApplicationStatus.interview,
        'offer' => ApplicationStatus.offer,
        'employer_passed' => ApplicationStatus.employerPassed,
        'accepted' => ApplicationStatus.accepted,
        'declined' => ApplicationStatus.declined,
        _ => throw ArgumentError('Unknown application_status: $w'),
      };

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'] as String,
        jobId: j['job_id'] as String,
        jobTitle: (j['job_title'] as String?) ?? '',
        companyName: (j['company_name'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        status: statusFromWire(j['status'] as String),
        matchedAt: j['matched_at'] == null ? null : DateTime.parse(j['matched_at'] as String).toUtc(),
      );
}
