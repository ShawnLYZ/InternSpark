import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/verification_wizard_screen.dart';
import 'package:app_mobile/src/wizard_cards.dart';

VerificationSession sess(
  VerificationStep step, {
  List<VerificationLogEntry> log = const [],
  VerificationFindings findings = const VerificationFindings(),
}) =>
    VerificationSession(id: 's1', step: step, findings: findings, log: log);

VerificationLogEntry entry(VerificationLogKind kind, String title) =>
    VerificationLogEntry(at: DateTime(2026, 7, 4), kind: kind, title: title);

Widget host(FakeVerificationRepository fake) => ProviderScope(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(fake),
        studentRepositoryProvider.overrideWithValue(FakeStudentRepository()),
        universityRepositoryProvider.overrideWithValue(FakeUniversityRepository(
          universities: const [University(id: 'u-spring', name: 'Springfield University')],
        )),
      ],
      child: const MaterialApp(home: VerificationWizardScreen()),
    );

Widget hostWith(FakeVerificationRepository fake, Future<PickedCert?> Function() pickCert) => ProviderScope(
      overrides: [
        verificationRepositoryProvider.overrideWithValue(fake),
        studentRepositoryProvider.overrideWithValue(FakeStudentRepository()),
        universityRepositoryProvider.overrideWithValue(FakeUniversityRepository()),
      ],
      child: MaterialApp(home: VerificationWizardScreen(pickCert: pickCert)),
    );

void main() {
  testWidgets('full curriculum journey: input → confirm → skills → prefs → summary → finish', (tester) async {
    final fake = FakeVerificationRepository(sessions: [
      sess(VerificationStep.collectInput,
          log: [entry(VerificationLogKind.action, 'Verification session started')]),
      sess(VerificationStep.confirmProgram,
          log: [
            entry(VerificationLogKind.action, 'Verification session started'),
            entry(VerificationLogKind.action, 'Checking the InternSpark curriculum database…'),
            entry(VerificationLogKind.ok, 'Found 1 possible program — please confirm yours'),
          ],
          findings: const VerificationFindings(candidates: [
            ProgramCandidate(id: 'p1', name: 'Computer Science', source: 'curated'),
          ])),
      sess(VerificationStep.certificates,
          log: [entry(VerificationLogKind.ok, 'Verified Python — taught in Y1S2')],
          findings: const VerificationFindings(
            taught: [DerivedSkill(skill: 'Python', skillId: 'k1', year: 1, semester: 2)],
            notYet: [DerivedSkill(skill: 'Java', skillId: 'k2', year: 2, semester: 2)],
          )),
      sess(VerificationStep.preferences,
          log: [entry(VerificationLogKind.ok, 'Certificates step complete')]),
      sess(VerificationStep.summary,
          log: [entry(VerificationLogKind.ok, 'Preferences saved')],
          findings: const VerificationFindings(
            taught: [DerivedSkill(skill: 'Python', skillId: 'k1', year: 1, semester: 2)],
          )),
      sess(VerificationStep.completed,
          log: [entry(VerificationLogKind.ok, 'Verification complete')]),
    ]);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    // Program form: pick the university, type the course, submit.
    await tester.tap(find.byKey(const Key('university-dd')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Springfield University').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('course')), 'Computer Science');
    await tester.pump();
    await tester.tap(find.byKey(const Key('verify-skills')));
    await tester.pumpAndSettle();

    expect(fake.calls[1]['call'], 'submit_input');
    expect(fake.calls[1]['course'], 'Computer Science');
    expect(fake.calls[1]['universityId'], 'u-spring');

    // Confirm card renders the candidate; confirm it.
    expect(find.text('Computer Science'), findsWidgets);
    await tester.tap(find.byKey(const Key('confirm-program')));
    await tester.pumpAndSettle();
    expect(fake.calls[2]['call'], 'confirm_program');
    expect(fake.calls[2]['accept'], true);

    // Skills split: taught chip + not-yet row, then continue.
    expect(find.text('Python · Y1S2'), findsOneWidget);
    expect(find.textContaining('Java'), findsWidgets);
    await tester.tap(find.byKey(const Key('certificates-done')));
    await tester.pumpAndSettle();

    // Preferences → summary → finish.
    await tester.enterText(find.byKey(const Key('growth')), 'Ship real backend features.');
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-preferences')));
    await tester.pumpAndSettle();
    expect(fake.calls[4]['call'], 'save_preferences');
    expect(find.text('What employers will see'), findsOneWidget);

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();
    expect(fake.calls.last['call'], 'complete');
  });

  testWidgets('resume renders the persisted log instantly at the current step', (tester) async {
    final fake = FakeVerificationRepository(sessions: [
      sess(VerificationStep.certificates,
          log: [
            entry(VerificationLogKind.ok, 'Verified Python — taught in Y1S2'),
            entry(VerificationLogKind.warn, 'Budget reached — degraded to fallback'),
          ],
          findings: const VerificationFindings(
            taught: [DerivedSkill(skill: 'Python', skillId: 'k1', year: 1, semester: 2)],
          )),
    ]);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    expect(find.text('Verified Python — taught in Y1S2'), findsOneWidget);
    expect(find.text('Budget reached — degraded to fallback'), findsOneWidget);
    expect(find.byKey(const Key('certificates-done')), findsOneWidget);
  });

  testWidgets('certificate-only mode narrates the failed lookup', (tester) async {
    final fake = FakeVerificationRepository(sessions: [
      sess(VerificationStep.certificates,
          log: [entry(VerificationLogKind.fail, 'Curriculum lookup failed — web search unavailable')],
          findings: const VerificationFindings(mode: 'cert_only', lookupFailed: true)),
    ]);
    await tester.pumpWidget(host(fake));
    await tester.pumpAndSettle();

    expect(find.text('Curriculum lookup failed — web search unavailable'), findsOneWidget);
    expect(find.textContaining('retry later'), findsOneWidget);
  });

  testWidgets('uploading a certificate shows the agent verdict inline', (tester) async {
    final certSession = sess(VerificationStep.certificates,
        log: [entry(VerificationLogKind.action, 'Not taught yet: Java')],
        findings: const VerificationFindings(
          notYet: [DerivedSkill(skill: 'Java', skillId: 'k2', year: 2, semester: 2)],
        ));
    final fake = FakeVerificationRepository(
      sessions: [certSession, certSession],
      certification: const Certification(
        id: 'c1',
        status: CertificationStatus.approved,
        skillName: 'Java',
        reason: 'Verified: Java Certificate from Coursera',
        originalFilename: 'java.pdf',
      ),
    );
    await tester.pumpWidget(hostWith(
      fake,
      () async => (bytes: Uint8List.fromList([1, 2, 3]), name: 'java.pdf'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('upload-cert')));
    await tester.pumpAndSettle();

    expect(fake.calls.last['call'], 'upload_certificate');
    expect(fake.calls.last['filename'], 'java.pdf');
    expect(find.text('Verified: Java Certificate from Coursera'), findsOneWidget);
  });

  testWidgets('a rejected certificate shows the specific reason', (tester) async {
    final certSession = sess(VerificationStep.certificates,
        findings: const VerificationFindings(mode: 'cert_only', lookupFailed: true));
    final fake = FakeVerificationRepository(
      sessions: [certSession, certSession],
      certification: const Certification(
        id: 'c2',
        status: CertificationStatus.rejected,
        reason: 'The certificate names "A. Someone Else", which doesn\'t match your registered name.',
        originalFilename: 'borrowed.pdf',
      ),
    );
    await tester.pumpWidget(hostWith(
      fake,
      () async => (bytes: Uint8List.fromList([9, 9]), name: 'borrowed.pdf'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('upload-cert')));
    await tester.pumpAndSettle();

    expect(find.textContaining("doesn't match your registered name"), findsOneWidget);
  });
}
