/// A row of `jobs` for the employer CRUD form + card display.
class Job {
  const Job({
    required this.id,
    required this.companyId,
    required this.title,
    this.description = '',
    this.growthText = '',
    this.salaryMin,
    this.salaryMax,
    this.location,
    this.remoteMode,
    this.roleFunction,
    this.industry,
    this.durationWeeks,
    this.startDate,
    this.hasSandbox = false,
    this.published = true,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String growthText;
  final int? salaryMin;
  final int? salaryMax;
  final String? location;
  final String? remoteMode;
  final String? roleFunction;
  final String? industry;
  final int? durationWeeks;
  final DateTime? startDate;
  final bool hasSandbox;
  final bool published;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as String,
        companyId: j['company_id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        growthText: (j['growth_text'] as String?) ?? '',
        salaryMin: j['salary_min'] as int?,
        salaryMax: j['salary_max'] as int?,
        location: j['location'] as String?,
        remoteMode: j['remote_mode'] as String?,
        roleFunction: j['role_function'] as String?,
        industry: j['industry'] as String?,
        durationWeeks: j['duration_weeks'] as int?,
        startDate: j['start_date'] == null ? null : DateTime.parse(j['start_date'] as String),
        hasSandbox: (j['has_sandbox'] as bool?) ?? false,
        published: (j['published'] as bool?) ?? true,
      );
}
