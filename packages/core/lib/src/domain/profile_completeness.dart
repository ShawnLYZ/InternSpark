/// The onboarding fields the completeness meter inspects. Pure value object.
class ProfileFields {
  const ProfileFields({
    this.growthStatement,
    this.skillCount = 0,
    this.major,
    this.studyYear,
    this.location,
    this.remotePref,
    this.availabilityStart,
    this.durationWeeks,
    this.salaryExpectation,
    this.roleInterests = const [],
    this.industryInterests = const [],
  });

  final String? growthStatement;
  final int skillCount;
  final String? major;
  final int? studyYear;
  final String? location;
  final String? remotePref;
  final DateTime? availabilityStart;
  final int? durationWeeks;
  final int? salaryExpectation;
  final List<String> roleInterests;
  final List<String> industryInterests;

  ProfileFields copyWith({
    Object? growthStatement = _sentinel,
    int? skillCount,
    Object? major = _sentinel,
    Object? studyYear = _sentinel,
    Object? location = _sentinel,
    Object? remotePref = _sentinel,
    Object? availabilityStart = _sentinel,
    Object? durationWeeks = _sentinel,
    Object? salaryExpectation = _sentinel,
    Object? roleInterests = _sentinel,
    Object? industryInterests = _sentinel,
  }) {
    return ProfileFields(
      growthStatement: growthStatement == _sentinel ? this.growthStatement : growthStatement as String?,
      skillCount: skillCount ?? this.skillCount,
      major: major == _sentinel ? this.major : major as String?,
      studyYear: studyYear == _sentinel ? this.studyYear : studyYear as int?,
      location: location == _sentinel ? this.location : location as String?,
      remotePref: remotePref == _sentinel ? this.remotePref : remotePref as String?,
      availabilityStart:
          availabilityStart == _sentinel ? this.availabilityStart : availabilityStart as DateTime?,
      durationWeeks: durationWeeks == _sentinel ? this.durationWeeks : durationWeeks as int?,
      salaryExpectation:
          salaryExpectation == _sentinel ? this.salaryExpectation : salaryExpectation as int?,
      roleInterests: roleInterests == _sentinel ? this.roleInterests : (roleInterests as List<dynamic>).cast<String>(),
      industryInterests: industryInterests == _sentinel ? this.industryInterests : (industryInterests as List<dynamic>).cast<String>(),
    );
  }

  static const Object _sentinel = Object();
}

/// Result of [profileCompleteness].
class ProfileCompletenessResult {
  const ProfileCompletenessResult({
    required this.percent,
    required this.missingCritical,
    required this.deckUnlocked,
  });

  /// 0.0–1.0 over all tracked fields (critical + optional).
  final double percent;

  /// Human-readable labels of the matching-critical fields still missing.
  final List<String> missingCritical;

  /// True only when every matching-critical field is present.
  final bool deckUnlocked;
}

bool _hasText(String? s) => s != null && s.trim().isNotEmpty;

/// Pure completeness meter. The deck unlocks only when all matching-critical
/// fields (growth statement, ≥1 skill, eligibility, location/remote, availability)
/// are present. Salary + interests are optional: they raise the percent but never gate.
ProfileCompletenessResult profileCompleteness(ProfileFields f) {
  final critical = <String, bool>{
    'growth statement': _hasText(f.growthStatement),
    'at least one skill': f.skillCount > 0,
    'eligibility (major + study year)': _hasText(f.major) && f.studyYear != null,
    'location/remote': _hasText(f.location) || _hasText(f.remotePref),
    'availability': f.availabilityStart != null && f.durationWeeks != null,
  };
  final optional = <bool>[
    f.salaryExpectation != null,
    f.roleInterests.isNotEmpty,
    f.industryInterests.isNotEmpty,
  ];

  final missing = [for (final e in critical.entries) if (!e.value) e.key];
  final filled = critical.values.where((v) => v).length + optional.where((v) => v).length;
  final total = critical.length + optional.length;

  return ProfileCompletenessResult(
    percent: filled / total,
    missingCritical: missing,
    deckUnlocked: missing.isEmpty,
  );
}
