/// The status of an application in InternSpark's central state machine.
///
/// `ghosted` is intentionally absent: it is a *derived* condition
/// (matched + 7 days elapsed + no employer next-step), never stored.
/// Mirrors the Postgres `application_status` enum.
enum ApplicationStatus {
  passed,
  applied,
  rejected,
  matched,
  interview,
  offer,
  employerPassed,
  accepted,
  declined,
}

/// Events that drive transitions in the application state machine.
enum ApplicationEvent {
  studentSwipeLeft,
  studentSwipeRight,
  employerSwipeLeft,
  employerSwipeRight,
  requestInterview,
  makeOffer,
  employerPass,
  studentAccept,
  studentDecline,
}
