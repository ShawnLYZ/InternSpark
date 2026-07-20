import '../domain/verification.dart';

/// One entry of a session's append-only activity log — the agent's visible
/// reasoning. Rendered verbatim by the wizard's console.
enum VerificationLogKind {
  user,
  action,
  ok,
  warn,
  fail;

  static VerificationLogKind fromWire(String value) => switch (value) {
        'user' => VerificationLogKind.user,
        'action' => VerificationLogKind.action,
        'ok' => VerificationLogKind.ok,
        'warn' => VerificationLogKind.warn,
        'fail' => VerificationLogKind.fail,
        _ => VerificationLogKind.action,
      };
}

class VerificationLogEntry {
  const VerificationLogEntry({required this.at, required this.kind, required this.title, this.detail});
  final DateTime at;
  final VerificationLogKind kind;
  final String title;
  final String? detail;

  factory VerificationLogEntry.fromJson(Map<String, dynamic> json) => VerificationLogEntry(
        at: DateTime.tryParse((json['at'] as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        kind: VerificationLogKind.fromWire((json['kind'] as String?) ?? 'action'),
        title: (json['title'] as String?) ?? '',
        detail: json['detail'] as String?,
      );
}

class ProgramCandidate {
  const ProgramCandidate({this.id, required this.name, required this.source});
  final String? id; // null = web-derived, not yet persisted
  final String name;
  final String source; // 'curated' | 'ai_web'

  factory ProgramCandidate.fromJson(Map<String, dynamic> json) => ProgramCandidate(
        id: json['id'] as String?,
        name: (json['name'] as String?) ?? '',
        source: (json['source'] as String?) ?? 'ai_web',
      );
}

class DerivedSkill {
  const DerivedSkill({required this.skill, required this.skillId, required this.year, required this.semester});
  final String skill;
  final String skillId;
  final int year;
  final int semester;

  factory DerivedSkill.fromJson(Map<String, dynamic> json) => DerivedSkill(
        skill: (json['skill'] as String?) ?? '',
        skillId: (json['skill_id'] as String?) ?? '',
        year: (json['year'] as num?)?.toInt() ?? 0,
        semester: (json['semester'] as num?)?.toInt() ?? 0,
      );
}

class VerificationFindings {
  const VerificationFindings({
    this.mode = '',
    this.programName,
    this.candidates = const [],
    this.taught = const [],
    this.notYet = const [],
    this.lookupFailed = false,
  });
  final String mode; // 'db' | 'web' | 'cert_only' | ''
  final String? programName;
  final List<ProgramCandidate> candidates;
  final List<DerivedSkill> taught;
  final List<DerivedSkill> notYet;
  final bool lookupFailed;

  factory VerificationFindings.fromJson(Map<String, dynamic> json) => VerificationFindings(
        mode: (json['mode'] as String?) ?? '',
        programName: json['program_name'] as String?,
        candidates: [
          for (final c in (json['candidates'] as List?) ?? const [])
            ProgramCandidate.fromJson((c as Map).cast<String, dynamic>()),
        ],
        taught: [
          for (final t in (json['taught'] as List?) ?? const [])
            DerivedSkill.fromJson((t as Map).cast<String, dynamic>()),
        ],
        notYet: [
          for (final n in (json['not_yet'] as List?) ?? const [])
            DerivedSkill.fromJson((n as Map).cast<String, dynamic>()),
        ],
        lookupFailed: (json['lookup_failed'] as bool?) ?? false,
      );
}

/// A row of `verification_sessions` — the agent's persisted memory.
class VerificationSession {
  const VerificationSession({
    required this.id,
    required this.step,
    this.input = const {},
    this.findings = const VerificationFindings(),
    this.log = const [],
    this.completedAt,
  });
  final String id;
  final VerificationStep step;
  final Map<String, dynamic> input;
  final VerificationFindings findings;
  final List<VerificationLogEntry> log;
  final DateTime? completedAt;

  factory VerificationSession.fromJson(Map<String, dynamic> json) => VerificationSession(
        id: json['id'] as String,
        step: VerificationStep.fromWire((json['step'] as String?) ?? 'collect_input'),
        input: ((json['input_json'] as Map?) ?? const {}).cast<String, dynamic>(),
        findings: VerificationFindings.fromJson(
            ((json['findings_json'] as Map?) ?? const {}).cast<String, dynamic>()),
        log: [
          for (final e in (json['log_json'] as List?) ?? const [])
            VerificationLogEntry.fromJson((e as Map).cast<String, dynamic>()),
        ],
        completedAt: json['completed_at'] == null ? null : DateTime.tryParse(json['completed_at'] as String),
      );
}

enum CertificationStatus {
  pending,
  approved,
  rejected;

  static CertificationStatus fromWire(String value) => switch (value) {
        'pending' => CertificationStatus.pending,
        'approved' => CertificationStatus.approved,
        'rejected' => CertificationStatus.rejected,
        _ => throw ArgumentError('Unknown certification_status: $value'),
      };
}

/// A row of `certifications` (the fields the wizard renders).
class Certification {
  const Certification({
    required this.id,
    required this.status,
    this.skillName,
    this.reason,
    this.originalFilename,
  });
  final String id;
  final CertificationStatus status;
  final String? skillName;
  final String? reason;
  final String? originalFilename;

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
        id: json['id'] as String,
        status: CertificationStatus.fromWire((json['status'] as String?) ?? 'pending'),
        skillName: ((json['extracted_json'] as Map?)?['skill']) as String?,
        reason: json['reason'] as String?,
        originalFilename: json['original_filename'] as String?,
      );
}

enum SkillSource {
  curriculum,
  certification;

  static SkillSource? fromWire(String? value) => switch (value) {
        'curriculum' => SkillSource.curriculum,
        'certification' => SkillSource.certification,
        _ => null, // null/unknown = legacy pre-verification row
      };
}

/// A `student_skills` row joined with its `skills` taxonomy entry —
/// what the Profile tab renders with a provenance badge.
class VerifiedSkill {
  const VerifiedSkill({
    required this.skillId,
    required this.name,
    this.category = '',
    this.source,
    this.verifiedAt,
    this.evidence = const {},
  });
  final String skillId;
  final String name;
  final String category;
  final SkillSource? source;
  final DateTime? verifiedAt;
  final Map<String, dynamic> evidence;

  factory VerifiedSkill.fromJson(Map<String, dynamic> json) {
    final skill = ((json['skills'] as Map?) ?? const {}).cast<String, dynamic>();
    return VerifiedSkill(
      skillId: json['skill_id'] as String,
      name: (skill['name'] as String?) ?? '',
      category: (skill['category'] as String?) ?? '',
      source: SkillSource.fromWire(json['source'] as String?),
      verifiedAt: json['verified_at'] == null ? null : DateTime.tryParse(json['verified_at'] as String),
      evidence: ((json['evidence_json'] as Map?) ?? const {}).cast<String, dynamic>(),
    );
  }

  /// e.g. "Curriculum · Y1S2", "Certificate · Coursera · 2026", "Unverified".
  String get provenanceLabel => switch (source) {
        SkillSource.curriculum => (evidence['year'] != null && evidence['semester'] != null)
            ? 'Curriculum · Y${evidence['year']}S${evidence['semester']}'
            : 'Curriculum',
        SkillSource.certification => [
            'Certificate',
            if (((evidence['issuer'] as String?) ?? '').isNotEmpty) evidence['issuer'] as String,
            if (((evidence['issue_date'] as String?) ?? '').length >= 4)
              (evidence['issue_date'] as String).substring(0, 4),
          ].join(' · '),
        null => 'Unverified',
      };
}
