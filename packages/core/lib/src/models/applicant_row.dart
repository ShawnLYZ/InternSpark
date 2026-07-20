import '../domain/application_status.dart';
import 'application.dart';

/// One row of `employer_applicants(job)` — identity-masked until matched.
class ApplicantRow {
  const ApplicantRow({
    required this.applicationId,
    required this.status,
    required this.matched,
    required this.requiredSkills,
    required this.studentSkills,
    this.fullName,
    this.major,
    this.growthStatement,
  });

  final String applicationId;
  final ApplicationStatus status;
  final bool matched;

  /// Null until [matched] — the anonymity rule.
  final String? fullName;
  final String? major;
  final String? growthStatement;
  final List<String> requiredSkills;
  final List<String> studentSkills;

  factory ApplicantRow.fromJson(Map<String, dynamic> j) => ApplicantRow(
        applicationId: j['application_id'] as String,
        status: Application.statusFromWire(j['status'] as String),
        matched: (j['matched'] as bool?) ?? false,
        fullName: j['full_name'] as String?,
        major: j['major'] as String?,
        growthStatement: j['growth_statement'] as String?,
        requiredSkills: ((j['required_skills'] as List?) ?? const []).map((e) => e as String).toList(),
        studentSkills: ((j['student_skills'] as List?) ?? const []).map((e) => e as String).toList(),
      );
}
