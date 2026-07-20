import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('VerificationSession parses a wire row (snake_case, jsonb columns)', () {
    final s = VerificationSession.fromJson({
      'id': 's1',
      'step': 'confirm_program',
      'input_json': {'course': 'Computer Science', 'year': 2, 'semester': 1},
      'findings_json': {
        'mode': 'web',
        'lookup_failed': false,
        'candidates': [
          {'id': null, 'name': 'Computer Science (BSc)', 'source': 'ai_web'},
        ],
        'taught': [
          {'skill': 'Python', 'skill_id': 'k1', 'year': 1, 'semester': 2},
        ],
        'not_yet': [
          {'skill': 'Java', 'skill_id': 'k2', 'year': 2, 'semester': 2},
        ],
      },
      'log_json': [
        {'at': '2026-07-04T10:00:00Z', 'kind': 'action', 'title': 'Checking…'},
        {'at': '2026-07-04T10:00:02Z', 'kind': 'warn', 'title': 'Degraded', 'detail': 'budget'},
      ],
      'completed_at': null,
    });

    expect(s.step, VerificationStep.confirmProgram);
    expect(s.input['year'], 2);
    expect(s.findings.candidates.single.name, 'Computer Science (BSc)');
    expect(s.findings.candidates.single.id, isNull);
    expect(s.findings.taught.single.skill, 'Python');
    expect(s.findings.notYet.single.year, 2);
    expect(s.findings.lookupFailed, isFalse);
    expect(s.log, hasLength(2));
    expect(s.log.last.kind, VerificationLogKind.warn);
    expect(s.log.last.detail, 'budget');
    expect(s.completedAt, isNull);
  });

  test('empty jsonb defaults are tolerated', () {
    final s = VerificationSession.fromJson({'id': 's2', 'step': 'collect_input'});
    expect(s.findings.candidates, isEmpty);
    expect(s.findings.taught, isEmpty);
    expect(s.log, isEmpty);
    expect(s.input, isEmpty);
  });

  test('Certification parses status and reason', () {
    final c = Certification.fromJson({
      'id': 'c1', 'status': 'rejected', 'reason': 'Name mismatch.', 'original_filename': 'cert.pdf',
    });
    expect(c.status, CertificationStatus.rejected);
    expect(c.reason, 'Name mismatch.');
  });

  test('VerifiedSkill provenance labels', () {
    final curriculum = VerifiedSkill.fromJson({
      'skill_id': 'k1',
      'source': 'curriculum',
      'verified_at': '2026-07-04T10:00:00Z',
      'evidence_json': {'program_id': 'p1', 'year': 1, 'semester': 2},
      'skills': {'name': 'Python', 'category': 'Software & Data'},
    });
    expect(curriculum.name, 'Python');
    expect(curriculum.provenanceLabel, 'Curriculum · Y1S2');

    final cert = VerifiedSkill.fromJson({
      'skill_id': 'k2',
      'source': 'certification',
      'evidence_json': {'issuer': 'Coursera', 'issue_date': '2026-03-01'},
      'skills': {'name': 'Java', 'category': 'Software & Data'},
    });
    expect(cert.provenanceLabel, 'Certificate · Coursera · 2026');

    final legacy = VerifiedSkill.fromJson({
      'skill_id': 'k3',
      'skills': {'name': 'SQL', 'category': 'Software & Data'},
    });
    expect(legacy.source, isNull);
    expect(legacy.provenanceLabel, 'Unverified');
  });
}
