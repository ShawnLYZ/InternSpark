import 'application_status.dart';

/// Result of attempting an application state transition.
sealed class TransitionResult {
  const TransitionResult();
}

/// A legal transition producing [next].
final class TransitionOk extends TransitionResult {
  const TransitionOk(this.next);
  final ApplicationStatus next;

  @override
  bool operator ==(Object other) => other is TransitionOk && other.next == next;
  @override
  int get hashCode => next.hashCode;
  @override
  String toString() => 'TransitionOk($next)';
}

/// An illegal transition; [reason] explains why.
final class TransitionInvalid extends TransitionResult {
  const TransitionInvalid(this.reason);
  final String reason;

  @override
  bool operator ==(Object other) => other is TransitionInvalid && other.reason == reason;
  @override
  int get hashCode => reason.hashCode;
  @override
  String toString() => 'TransitionInvalid($reason)';
}

/// Pure validator for InternSpark's application state machine.
///
/// `current == null` represents "no application yet" (the deck). Returns a
/// [TransitionOk] with the next status for a legal pair, else a
/// [TransitionInvalid]. No side effects.
abstract final class ApplicationTransition {
  static TransitionResult next(ApplicationStatus? current, ApplicationEvent event) {
    switch ((current, event)) {
      case (null, ApplicationEvent.studentSwipeLeft):
        return const TransitionOk(ApplicationStatus.passed);
      case (null, ApplicationEvent.studentSwipeRight):
        return const TransitionOk(ApplicationStatus.applied);

      case (ApplicationStatus.applied, ApplicationEvent.employerSwipeLeft):
        return const TransitionOk(ApplicationStatus.rejected);
      case (ApplicationStatus.applied, ApplicationEvent.employerSwipeRight):
        return const TransitionOk(ApplicationStatus.matched);

      case (ApplicationStatus.matched, ApplicationEvent.requestInterview):
        return const TransitionOk(ApplicationStatus.interview);
      case (ApplicationStatus.matched, ApplicationEvent.makeOffer):
        return const TransitionOk(ApplicationStatus.offer);
      case (ApplicationStatus.matched, ApplicationEvent.employerPass):
        return const TransitionOk(ApplicationStatus.employerPassed);

      case (ApplicationStatus.interview, ApplicationEvent.makeOffer):
        return const TransitionOk(ApplicationStatus.offer);
      case (ApplicationStatus.interview, ApplicationEvent.employerPass):
        return const TransitionOk(ApplicationStatus.employerPassed);

      case (ApplicationStatus.offer, ApplicationEvent.studentAccept):
        return const TransitionOk(ApplicationStatus.accepted);
      case (ApplicationStatus.offer, ApplicationEvent.studentDecline):
        return const TransitionOk(ApplicationStatus.declined);

      default:
        return TransitionInvalid('No transition from ${current ?? "deck"} on $event');
    }
  }

  /// Terminal states accept no further events.
  static bool isTerminal(ApplicationStatus status) => switch (status) {
        ApplicationStatus.passed ||
        ApplicationStatus.rejected ||
        ApplicationStatus.employerPassed ||
        ApplicationStatus.accepted ||
        ApplicationStatus.declined =>
          true,
        ApplicationStatus.applied ||
        ApplicationStatus.matched ||
        ApplicationStatus.interview ||
        ApplicationStatus.offer =>
          false,
      };
}
