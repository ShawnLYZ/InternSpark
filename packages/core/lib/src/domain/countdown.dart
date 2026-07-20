/// The 7-day post-match ghost window. Reused for any future fixed window
/// (Phase 3 sandbox passes its own deadline directly to [countdownRemaining]).
DateTime ghostDeadline(DateTime matchedAt) => matchedAt.add(const Duration(days: 7));

/// Time left until [deadline] from [now], clamped to zero (never negative).
Duration countdownRemaining(DateTime deadline, DateTime now) =>
    deadline.isAfter(now) ? deadline.difference(now) : Duration.zero;

/// Compact countdown label: "6d 23h", "0d 5h", or "Expired" at zero.
String formatCountdown(Duration d) {
  if (d <= Duration.zero) return 'Expired';
  final days = d.inDays;
  final hours = d.inHours - days * 24;
  return '${days}d ${hours}h';
}
