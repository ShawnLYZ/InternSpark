/// One satisfied curriculum requirement in the AI mapping.
class CreditSatisfied {
  const CreditSatisfied({required this.skill, this.evidence = ''});
  final String skill;
  final String evidence;

  factory CreditSatisfied.fromJson(Map<String, dynamic> j) =>
      CreditSatisfied(skill: (j['skill'] as String?) ?? '', evidence: (j['evidence'] as String?) ?? '');
  Map<String, dynamic> toJson() => {'skill': skill, 'evidence': evidence};
}

/// The JD→curriculum mapping the Gemini `credit_map` task returns.
class CreditMapping {
  const CreditMapping({this.summary = '', this.satisfied = const []});
  final String summary;
  final List<CreditSatisfied> satisfied;

  factory CreditMapping.fromJson(Map<String, dynamic> j) => CreditMapping(
        summary: (j['summary'] as String?) ?? '',
        satisfied: ((j['satisfied'] as List?) ?? const [])
            .map((s) => CreditSatisfied.fromJson((s as Map).cast<String, dynamic>()))
            .toList(),
      );
  Map<String, dynamic> toJson() => {'summary': summary, 'satisfied': [for (final s in satisfied) s.toJson()]};
}

/// A row of `university_credit_requests()`.
class CreditRequest {
  const CreditRequest({
    required this.id,
    required this.status,
    required this.jobId,
    this.jobTitle = '',
    this.studentName = '',
    this.signerName,
    this.signedAt,
    this.mapping,
  });

  final String id;
  final String status; // 'pending' | 'approved'
  final String jobId;
  final String jobTitle;
  final String studentName;
  final String? signerName;
  final DateTime? signedAt;
  final CreditMapping? mapping;

  bool get isApproved => status == 'approved';

  factory CreditRequest.fromJson(Map<String, dynamic> j) => CreditRequest(
        id: j['id'] as String,
        status: (j['status'] as String?) ?? 'pending',
        jobId: (j['job_id'] as String?) ?? '',
        jobTitle: (j['job_title'] as String?) ?? '',
        studentName: (j['student_name'] as String?) ?? '',
        signerName: j['signer_name'] as String?,
        signedAt: j['signed_at'] == null ? null : DateTime.parse(j['signed_at'] as String),
        mapping: j['mapping_json'] == null
            ? null
            : CreditMapping.fromJson((j['mapping_json'] as Map).cast<String, dynamic>()),
      );
}
