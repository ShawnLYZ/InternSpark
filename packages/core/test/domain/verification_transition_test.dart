import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('legal transitions', () {
    test('collect_input branches on the lookup outcome', () {
      expect(verificationTransition(VerificationStep.collectInput, VerificationEvent.lookupAmbiguous),
          VerificationStep.confirmProgram);
      expect(verificationTransition(VerificationStep.collectInput, VerificationEvent.lookupResolved),
          VerificationStep.certificates);
      expect(verificationTransition(VerificationStep.collectInput, VerificationEvent.lookupFailed),
          VerificationStep.certificates);
    });

    test('confirm accepts forward or rejects back to input', () {
      expect(verificationTransition(VerificationStep.confirmProgram, VerificationEvent.programConfirmed),
          VerificationStep.certificates);
      expect(verificationTransition(VerificationStep.confirmProgram, VerificationEvent.programRejected),
          VerificationStep.collectInput);
    });

    test('the tail of the flow is linear', () {
      expect(verificationTransition(VerificationStep.certificates, VerificationEvent.certificatesDone),
          VerificationStep.preferences);
      expect(verificationTransition(VerificationStep.preferences, VerificationEvent.preferencesSaved),
          VerificationStep.summary);
      expect(verificationTransition(VerificationStep.summary, VerificationEvent.finish),
          VerificationStep.completed);
    });
  });

  group('illegal transitions return null', () {
    test('cannot finish early or re-enter after completion', () {
      expect(verificationTransition(VerificationStep.collectInput, VerificationEvent.finish), isNull);
      expect(verificationTransition(VerificationStep.certificates, VerificationEvent.preferencesSaved), isNull);
      expect(verificationTransition(VerificationStep.completed, VerificationEvent.finish), isNull);
      expect(verificationTransition(VerificationStep.completed, VerificationEvent.lookupResolved), isNull);
    });
  });

  group('wire mapping mirrors the Postgres enum', () {
    test('round-trips every step', () {
      for (final s in VerificationStep.values) {
        expect(VerificationStep.fromWire(s.wire), s);
      }
      expect(VerificationStep.fromWire('collect_input'), VerificationStep.collectInput);
      expect(VerificationStep.fromWire('confirm_program'), VerificationStep.confirmProgram);
      expect(() => VerificationStep.fromWire('nope'), throwsArgumentError);
    });
  });
}
