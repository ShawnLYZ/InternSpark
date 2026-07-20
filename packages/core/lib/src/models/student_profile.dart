/// A row of `student_profiles` (+ the joined university name when selected
/// with `*, universities(name)`). All post-Phase-0 fields are optional so
/// minimal test fixtures keep constructing `StudentProfile(profileId: …)`.
class StudentProfile {
  const StudentProfile({
    required this.profileId,
    required this.universityId,
    required this.fullName,
    this.major,
    this.studyYear,
    this.semester,
    this.location,
    this.remotePref,
    this.availabilityStart,
    this.durationWeeks,
    this.salaryExpectation,
    this.growthStatement,
    this.roleInterests = const [],
    this.industryInterests = const [],
    this.universityName,
  });
  final String profileId;
  final String universityId;
  final String fullName;
  final String? major;
  final int? studyYear;
  final int? semester;
  final String? location;
  final String? remotePref;
  final DateTime? availabilityStart;
  final int? durationWeeks;
  final int? salaryExpectation;
  final String? growthStatement;
  final List<String> roleInterests;
  final List<String> industryInterests;
  final String? universityName;

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        profileId: json['profile_id'] as String,
        universityId: json['university_id'] as String,
        fullName: json['full_name'] as String,
        major: json['major'] as String?,
        studyYear: (json['study_year'] as num?)?.toInt(),
        semester: (json['semester'] as num?)?.toInt(),
        location: json['location'] as String?,
        remotePref: json['remote_pref'] as String?,
        availabilityStart: json['availability_start'] == null
            ? null
            : DateTime.tryParse(json['availability_start'] as String),
        durationWeeks: (json['duration_weeks'] as num?)?.toInt(),
        salaryExpectation: (json['salary_expectation'] as num?)?.toInt(),
        growthStatement: json['growth_statement'] as String?,
        roleInterests: [...((json['role_interests'] as List?) ?? const []).cast<String>()],
        industryInterests: [...((json['industry_interests'] as List?) ?? const []).cast<String>()],
        universityName: ((json['universities'] as Map?)?['name']) as String?,
      );
}
