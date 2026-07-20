import '../models/deck_candidate.dart';

/// Stage-1 hard filter. Mirrors `deck_candidates` SQL: remote-mode compatibility
/// and the availability window. Minimal by design — null inputs never exclude.
bool hardFilter({
  required String? studentRemotePref,
  required DateTime? studentAvailabilityStart,
  required int? studentDurationWeeks,
  required String? jobRemoteMode,
  required DateTime? jobStartDate,
  required int? jobDurationWeeks,
}) {
  // Availability: the job must start on/after the student is free…
  if (studentAvailabilityStart != null &&
      jobStartDate != null &&
      jobStartDate.isBefore(studentAvailabilityStart)) {
    return false;
  }
  // …and fit inside what the student can commit.
  if (studentDurationWeeks != null &&
      jobDurationWeeks != null &&
      studentDurationWeeks < jobDurationWeeks) {
    return false;
  }
  // Remote compatibility.
  if (studentRemotePref != null && jobRemoteMode != null && studentRemotePref != 'any') {
    final ok = jobRemoteMode == studentRemotePref ||
        (studentRemotePref == 'remote' && jobRemoteMode == 'hybrid');
    if (!ok) return false;
  }
  return true;
}

/// 0..1 — how well the job's pay ceiling meets the student's ask. Neutral (0.5)
/// when either side is unknown.
double salaryFit(int? expectation, int? min, int? max) {
  if (expectation == null || expectation <= 0 || max == null) return 0.5;
  if (max >= expectation) return 1.0;
  return max / expectation;
}

/// 0..1 — matched ÷ required required-skills. 1.0 when the job lists none.
double skillOverlapRatio(int matched, int required) =>
    required == 0 ? 1.0 : matched / required;

/// Soft-signal weights for [deckScore]; defaults sum to 1.0 (cosine-led).
class DeckWeights {
  const DeckWeights({
    this.cosine = 0.6,
    this.skill = 0.2,
    this.salary = 0.1,
    this.role = 0.05,
    this.industry = 0.05,
  });
  final double cosine, skill, salary, role, industry;
}

/// Blends the five surfaced signals into a single 0..1 deck score.
double deckScore({
  required double cosineSim,
  required double skillOverlap,
  required double salaryFit,
  required bool roleMatch,
  required bool industryMatch,
  DeckWeights weights = const DeckWeights(),
}) {
  return cosineSim * weights.cosine +
      skillOverlap * weights.skill +
      salaryFit * weights.salary +
      (roleMatch ? 1.0 : 0.0) * weights.role +
      (industryMatch ? 1.0 : 0.0) * weights.industry;
}

/// Orders the blended deck: score descending, ties broken by jobId for stability.
List<DeckCandidate> sortDeck(List<DeckCandidate> candidates) {
  final out = [...candidates];
  out.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    return byScore != 0 ? byScore : a.jobId.compareTo(b.jobId);
  });
  return out;
}

/// Deterministic employer-side fit: percent matched + the matched-skill chips
/// (case-insensitive match; chips rendered in the job's required-skill casing).
class FitResult {
  const FitResult({required this.percent, required this.matchedChips});
  final double percent;
  final List<String> matchedChips;
}

FitResult fitScore({required List<String> requiredSkills, required List<String> studentSkills}) {
  if (requiredSkills.isEmpty) return const FitResult(percent: 1.0, matchedChips: []);
  final have = studentSkills.map((s) => s.toLowerCase()).toSet();
  final chips = [for (final r in requiredSkills) if (have.contains(r.toLowerCase())) r];
  return FitResult(percent: chips.length / requiredSkills.length, matchedChips: chips);
}
