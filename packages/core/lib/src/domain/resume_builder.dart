import '../models/resume.dart';

/// Builds the **grounded** resume request payload. Includes *only* entered
/// student fields (empty/null omitted) plus the job framing, so the model can
/// reorder/emphasize but never invent. The `ai` `resume` task consumes this.
Map<String, dynamic> buildResumeRequest({
  required String fullName,
  required String? major,
  required String growthStatement,
  required List<String> skills,
  required List<String> experiences,
  required String jobTitle,
  required String jobDescription,
  required List<String> jobRequiredSkills,
  required String? jobIndustry,
}) {
  final student = <String, dynamic>{'full_name': fullName};
  if (major != null && major.trim().isNotEmpty) student['major'] = major;
  if (growthStatement.trim().isNotEmpty) student['growth_statement'] = growthStatement;
  if (skills.isNotEmpty) student['skills'] = skills;
  if (experiences.isNotEmpty) student['experiences'] = experiences;

  final job = <String, dynamic>{'title': jobTitle};
  if (jobDescription.trim().isNotEmpty) job['description'] = jobDescription;
  if (jobRequiredSkills.isNotEmpty) job['required_skills'] = jobRequiredSkills;
  if (jobIndustry != null && jobIndustry.trim().isNotEmpty) job['industry'] = jobIndustry;

  return {
    'instruction': 'Reorder and emphasize ONLY the provided experience to fit the job. '
        'Do not invent employers, dates, or skills. Output JSON: '
        '{name, headline, summary, sections:[{title, bullets:[...]}]}.',
    'student': student,
    'job': job,
  };
}

/// Deterministic name redaction for the employer's pre-match view. The SQL
/// `applicant_resume` RPC mirrors this server-side.
ResumeJson redactName(ResumeJson r) => r.copyWith(name: 'Candidate');
