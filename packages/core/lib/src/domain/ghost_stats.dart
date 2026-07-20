import '../models/company_ghost_stats.dart';

const Duration ghostWindow = Duration(days: 7);
const Duration rollingWindow = Duration(days: 90);

/// One post-match record for the pure stat functions.
class MatchRecord {
  const MatchRecord({required this.matchedAt, this.firstResponseAt});
  final DateTime matchedAt;
  final DateTime? firstResponseAt;
}

bool _respondedInWindow(MatchRecord m) =>
    m.firstResponseAt != null && m.firstResponseAt!.difference(m.matchedAt) <= ghostWindow;

/// Ghosted = no employer next-step within 7 calendar days, and the window has elapsed.
bool isGhosted(MatchRecord m, DateTime now) =>
    !_respondedInWindow(m) && now.difference(m.matchedAt) > ghostWindow;

List<MatchRecord> _inRolling(List<MatchRecord> matches, DateTime now) =>
    [for (final m in matches) if (now.difference(m.matchedAt) <= rollingWindow) m];

/// Ghost rate = ghosted ÷ total matches over the rolling 90 days (0 when none).
double ghostRate(List<MatchRecord> matches, DateTime now) {
  final window = _inRolling(matches, now);
  if (window.isEmpty) return 0;
  final ghosted = window.where((m) => isGhosted(m, now)).length;
  return ghosted / window.length;
}

/// Mean(match → first next-step) over resolved matches; ghosted count as the full
/// 7 days; still-pending (in-window, no response) are excluded.
Duration avgResponseTime(List<MatchRecord> matches, DateTime now) {
  final secs = <int>[];
  for (final m in _inRolling(matches, now)) {
    if (_respondedInWindow(m)) {
      secs.add(m.firstResponseAt!.difference(m.matchedAt).inSeconds);
    } else if (isGhosted(m, now)) {
      secs.add(ghostWindow.inSeconds);
    } // else pending → skip
  }
  if (secs.isEmpty) return Duration.zero;
  final mean = secs.reduce((a, b) => a + b) / secs.length;
  return Duration(seconds: mean.round());
}

/// Companies with fewer than 5 matches are not ranked ("Not enough data").
bool minSampleGate(int matchCount) => matchCount >= 5;

/// Enough-data companies first, ascending ghost rate (best = lowest); gated last.
List<CompanyGhostStats> rankLeaderboard(List<CompanyGhostStats> stats) {
  final ranked = [for (final s in stats) if (minSampleGate(s.totalMatches)) s]
    ..sort((a, b) => (a.ghostRate ?? 1).compareTo(b.ghostRate ?? 1));
  final gated = [for (final s in stats) if (!minSampleGate(s.totalMatches)) s];
  return [...ranked, ...gated];
}
