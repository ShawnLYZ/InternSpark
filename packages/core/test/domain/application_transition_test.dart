import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('ApplicationTransition.next — legal transitions', () {
    final legal = <(ApplicationStatus?, ApplicationEvent, ApplicationStatus)>[
      (null, ApplicationEvent.studentSwipeLeft, ApplicationStatus.passed),
      (null, ApplicationEvent.studentSwipeRight, ApplicationStatus.applied),
      (ApplicationStatus.applied, ApplicationEvent.employerSwipeLeft, ApplicationStatus.rejected),
      (ApplicationStatus.applied, ApplicationEvent.employerSwipeRight, ApplicationStatus.matched),
      (ApplicationStatus.matched, ApplicationEvent.requestInterview, ApplicationStatus.interview),
      (ApplicationStatus.matched, ApplicationEvent.makeOffer, ApplicationStatus.offer),
      (ApplicationStatus.matched, ApplicationEvent.employerPass, ApplicationStatus.employerPassed),
      (ApplicationStatus.interview, ApplicationEvent.makeOffer, ApplicationStatus.offer),
      (ApplicationStatus.interview, ApplicationEvent.employerPass, ApplicationStatus.employerPassed),
      (ApplicationStatus.offer, ApplicationEvent.studentAccept, ApplicationStatus.accepted),
      (ApplicationStatus.offer, ApplicationEvent.studentDecline, ApplicationStatus.declined),
    ];

    for (final (current, event, expected) in legal) {
      test('$current + $event -> $expected', () {
        expect(ApplicationTransition.next(current, event), TransitionOk(expected));
      });
    }
  });

  group('ApplicationTransition.next — illegal transitions are rejected', () {
    final illegal = <(ApplicationStatus?, ApplicationEvent)>[
      (null, ApplicationEvent.studentAccept),
      (ApplicationStatus.rejected, ApplicationEvent.employerSwipeRight),
      (ApplicationStatus.applied, ApplicationEvent.makeOffer),
      (ApplicationStatus.matched, ApplicationEvent.studentAccept),
      (ApplicationStatus.accepted, ApplicationEvent.studentDecline),
    ];

    for (final (current, event) in illegal) {
      test('$current + $event -> invalid', () {
        expect(ApplicationTransition.next(current, event), isA<TransitionInvalid>());
      });
    }
  });

  test('terminal states reject every event', () {
    const terminals = [
      ApplicationStatus.passed,
      ApplicationStatus.rejected,
      ApplicationStatus.employerPassed,
      ApplicationStatus.accepted,
      ApplicationStatus.declined,
    ];
    for (final status in terminals) {
      expect(ApplicationTransition.isTerminal(status), isTrue, reason: '$status terminal');
      for (final event in ApplicationEvent.values) {
        expect(ApplicationTransition.next(status, event), isA<TransitionInvalid>(),
            reason: '$status should reject $event');
      }
    }
  });

  test('non-terminal states are not terminal', () {
    const nonTerminals = [
      ApplicationStatus.applied,
      ApplicationStatus.matched,
      ApplicationStatus.interview,
      ApplicationStatus.offer,
    ];
    for (final status in nonTerminals) {
      expect(ApplicationTransition.isTerminal(status), isFalse, reason: '$status not terminal');
    }
  });

  test('every (current, event) cell not in the legal set is rejected', () {
    // Mirror of the 11 legal transitions defined in the legal group above.
    final legalPairs = <(ApplicationStatus?, ApplicationEvent)>{
      (null, ApplicationEvent.studentSwipeLeft),
      (null, ApplicationEvent.studentSwipeRight),
      (ApplicationStatus.applied, ApplicationEvent.employerSwipeLeft),
      (ApplicationStatus.applied, ApplicationEvent.employerSwipeRight),
      (ApplicationStatus.matched, ApplicationEvent.requestInterview),
      (ApplicationStatus.matched, ApplicationEvent.makeOffer),
      (ApplicationStatus.matched, ApplicationEvent.employerPass),
      (ApplicationStatus.interview, ApplicationEvent.makeOffer),
      (ApplicationStatus.interview, ApplicationEvent.employerPass),
      (ApplicationStatus.offer, ApplicationEvent.studentAccept),
      (ApplicationStatus.offer, ApplicationEvent.studentDecline),
    };

    final allCurrents = <ApplicationStatus?>[null, ...ApplicationStatus.values];

    for (final current in allCurrents) {
      for (final event in ApplicationEvent.values) {
        if (!legalPairs.contains((current, event))) {
          expect(
            ApplicationTransition.next(current, event),
            isA<TransitionInvalid>(),
            reason: 'expected TransitionInvalid for ($current, $event)',
          );
        }
      }
    }
  });
}
