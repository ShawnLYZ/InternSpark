/// A "company filed a report about this student" reference (no report contents).
class ReportRef {
  const ReportRef({required this.studentId, required this.companyId});
  final String studentId;
  final String companyId;
}

/// Result of the soft comment-gate check.
class CommentGateResult {
  const CommentGateResult({required this.warn});

  /// True when the company has not filed a report about the student — show a
  /// non-blocking nudge. Never a hard block.
  final bool warn;
}

/// Soft, per-student gate: warn iff no report exists for (studentId, companyId).
CommentGateResult commentGate({
  required String studentId,
  required String companyId,
  required List<ReportRef> reports,
}) {
  final filed = reports.any((r) => r.studentId == studentId && r.companyId == companyId);
  return CommentGateResult(warn: !filed);
}
