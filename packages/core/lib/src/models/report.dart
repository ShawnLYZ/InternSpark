/// A `reports` row as the university reads it (joined names).
class Report {
  const Report({
    required this.reliability,
    required this.skill,
    required this.communication,
    this.studentName,
    this.companyName,
    this.narrative,
    this.createdAt,
  });

  final int reliability;
  final int skill;
  final int communication;
  final String? studentName;
  final String? companyName;
  final String? narrative;
  final DateTime? createdAt;

  factory Report.fromJson(Map<String, dynamic> j) => Report(
        reliability: (j['reliability'] as num?)?.toInt() ?? 0,
        skill: (j['skill'] as num?)?.toInt() ?? 0,
        communication: (j['communication'] as num?)?.toInt() ?? 0,
        studentName: j['student_name'] as String?,
        companyName: j['company_name'] as String?,
        narrative: j['narrative'] as String?,
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}

/// A student the employer may report on.
class ReportableStudent {
  const ReportableStudent({required this.studentId, required this.fullName});
  final String studentId;
  final String fullName;

  factory ReportableStudent.fromJson(Map<String, dynamic> j) => ReportableStudent(
        studentId: j['student_id'] as String,
        fullName: (j['full_name'] as String?) ?? 'Student',
      );
}
