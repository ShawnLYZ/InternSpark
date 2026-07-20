import '../domain/sandbox.dart';

/// A per-job sandbox task config.
class SandboxTask {
  const SandboxTask({required this.jobId, required this.source, this.prompt = '', this.approved = false});
  final String jobId;
  final String source; // 'author' | 'ai'
  final String prompt;
  final bool approved;

  factory SandboxTask.fromJson(Map<String, dynamic> j) => SandboxTask(
        jobId: j['job_id'] as String,
        source: (j['source'] as String?) ?? 'author',
        prompt: (j['prompt'] as String?) ?? '',
        approved: (j['approved'] as bool?) ?? false,
      );
}

/// A 48h try-out submission (student + employer views).
class SandboxSubmission {
  const SandboxSubmission({
    required this.id,
    required this.status,
    this.applicationId = '',
    this.text,
    this.fileRef,
    this.deadlineAt,
    this.prompt = '',
    this.jobTitle = '',
    this.studentName = '',
    this.employerVerdict,
    this.employerNotes,
    this.aiAssessment,
  });

  final String id;
  final SandboxStatus status;
  final String applicationId;
  final String? text;
  final String? fileRef;
  final DateTime? deadlineAt;
  final String prompt;
  final String jobTitle;
  final String studentName;
  final String? employerVerdict;
  final String? employerNotes;
  final String? aiAssessment;

  factory SandboxSubmission.fromJson(Map<String, dynamic> j) => SandboxSubmission(
        id: j['id'] as String,
        status: SandboxStatus.fromWire(j['status'] as String),
        applicationId: (j['application_id'] as String?) ?? '',
        text: j['text'] as String?,
        fileRef: j['file_ref'] as String?,
        deadlineAt: j['deadline_at'] == null ? null : DateTime.parse(j['deadline_at'] as String).toUtc(),
        prompt: (j['prompt'] as String?) ?? '',
        jobTitle: (j['job_title'] as String?) ?? '',
        studentName: (j['student_name'] as String?) ?? '',
        employerVerdict: j['employer_verdict'] as String?,
        employerNotes: j['employer_notes'] as String?,
        aiAssessment: j['ai_assessment'] as String?,
      );
}
