/// The wizard's step machine. Mirrors the Postgres `verification_step` enum;
/// the SERVER is authoritative (it rejects out-of-order actions) — this pure
/// mirror exists for wizard navigation and tests. The semester-split logic is
/// deliberately NOT mirrored here: it lives only in the Edge Function's
/// gates module (single source of truth).
enum VerificationStep {
  collectInput,
  confirmProgram,
  certificates,
  preferences,
  summary,
  completed;

  static VerificationStep fromWire(String value) => switch (value) {
        'collect_input' => VerificationStep.collectInput,
        'confirm_program' => VerificationStep.confirmProgram,
        'certificates' => VerificationStep.certificates,
        'preferences' => VerificationStep.preferences,
        'summary' => VerificationStep.summary,
        'completed' => VerificationStep.completed,
        _ => throw ArgumentError('Unknown verification_step: $value'),
      };

  String get wire => switch (this) {
        VerificationStep.collectInput => 'collect_input',
        VerificationStep.confirmProgram => 'confirm_program',
        VerificationStep.certificates => 'certificates',
        VerificationStep.preferences => 'preferences',
        VerificationStep.summary => 'summary',
        VerificationStep.completed => 'completed',
      };
}

/// What just happened, as observed by the client.
enum VerificationEvent {
  lookupAmbiguous,
  lookupResolved,
  lookupFailed,
  programConfirmed,
  programRejected,
  certificatesDone,
  preferencesSaved,
  finish,
}

/// Pure transition table; null means the event is illegal at [current].
VerificationStep? verificationTransition(VerificationStep current, VerificationEvent event) {
  return switch ((current, event)) {
    (VerificationStep.collectInput, VerificationEvent.lookupAmbiguous) => VerificationStep.confirmProgram,
    (VerificationStep.collectInput, VerificationEvent.lookupResolved) => VerificationStep.certificates,
    (VerificationStep.collectInput, VerificationEvent.lookupFailed) => VerificationStep.certificates,
    (VerificationStep.confirmProgram, VerificationEvent.programConfirmed) => VerificationStep.certificates,
    (VerificationStep.confirmProgram, VerificationEvent.programRejected) => VerificationStep.collectInput,
    (VerificationStep.certificates, VerificationEvent.certificatesDone) => VerificationStep.preferences,
    (VerificationStep.preferences, VerificationEvent.preferencesSaved) => VerificationStep.summary,
    (VerificationStep.summary, VerificationEvent.finish) => VerificationStep.completed,
    _ => null,
  };
}
