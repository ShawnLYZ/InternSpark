/// Mirrors the Postgres `sandbox_submission_status` enum.
enum SandboxStatus {
  draft,
  submitted,
  notSubmitted,
  reviewed;

  static SandboxStatus fromWire(String w) => switch (w) {
        'draft' => SandboxStatus.draft,
        'submitted' => SandboxStatus.submitted,
        'not_submitted' => SandboxStatus.notSubmitted,
        'reviewed' => SandboxStatus.reviewed,
        _ => throw ArgumentError('Unknown sandbox status: $w'),
      };

  String get wire => switch (this) {
        SandboxStatus.draft => 'draft',
        SandboxStatus.submitted => 'submitted',
        SandboxStatus.notSubmitted => 'not_submitted',
        SandboxStatus.reviewed => 'reviewed',
      };
}

enum SandboxEvent { submit, lapse, review }

/// The 48h try-out window from match.
DateTime sandboxDeadline(DateTime matchedAt) => matchedAt.add(const Duration(hours: 48));

/// Pure transition: draft → submitted (on time) / not_submitted (late or lapse);
/// submitted → reviewed; terminal states unchanged. A lapse is no penalty.
SandboxStatus sandboxTransition(
  SandboxStatus state,
  SandboxEvent event, {
  required DateTime now,
  required DateTime deadline,
}) {
  switch (state) {
    case SandboxStatus.draft:
      switch (event) {
        case SandboxEvent.submit:
          return now.isAfter(deadline) ? SandboxStatus.notSubmitted : SandboxStatus.submitted;
        case SandboxEvent.lapse:
          return now.isAfter(deadline) ? SandboxStatus.notSubmitted : SandboxStatus.draft;
        case SandboxEvent.review:
          return SandboxStatus.draft; // cannot review an unsubmitted draft
      }
    case SandboxStatus.submitted:
      return event == SandboxEvent.review ? SandboxStatus.reviewed : SandboxStatus.submitted;
    case SandboxStatus.notSubmitted:
    case SandboxStatus.reviewed:
      return state; // terminal
  }
}
