/// One row of the `deck_candidates()` RPC plus the `core`-computed [score].
class DeckCandidate {
  const DeckCandidate({
    required this.jobId,
    required this.title,
    required this.growthText,
    required this.companyName,
    this.description = '',
    this.salaryMin,
    this.salaryMax,
    this.location,
    this.remoteMode,
    this.roleFunction,
    this.industry,
    this.hasSandbox = false,
    this.cosineSim = 0,
    this.matchedSkills = 0,
    this.requiredSkills = 0,
    this.score = 0,
    this.videoPath,
    this.posterPath,
  });

  final String jobId;
  final String title;
  final String growthText;
  final String companyName;
  final String description;
  final int? salaryMin;
  final int? salaryMax;
  final String? location;
  final String? remoteMode;
  final String? roleFunction;
  final String? industry;
  final bool hasSandbox;
  final double cosineSim;
  final int matchedSkills;
  final int requiredSkills;
  final double score;
  final String? videoPath;
  final String? posterPath;

  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;

  DeckCandidate withScore(double s) => DeckCandidate(
        jobId: jobId, title: title, growthText: growthText, companyName: companyName,
        description: description, salaryMin: salaryMin, salaryMax: salaryMax, location: location,
        remoteMode: remoteMode, roleFunction: roleFunction, industry: industry, hasSandbox: hasSandbox,
        cosineSim: cosineSim, matchedSkills: matchedSkills, requiredSkills: requiredSkills, score: s,
        videoPath: videoPath, posterPath: posterPath,
      );

  factory DeckCandidate.fromJson(Map<String, dynamic> j) => DeckCandidate(
        jobId: j['job_id'] as String,
        title: j['title'] as String,
        growthText: (j['growth_text'] as String?) ?? '',
        companyName: (j['company_name'] as String?) ?? '',
        description: (j['description'] as String?) ?? '',
        salaryMin: j['salary_min'] as int?,
        salaryMax: j['salary_max'] as int?,
        location: j['location'] as String?,
        remoteMode: j['remote_mode'] as String?,
        roleFunction: j['role_function'] as String?,
        industry: j['industry'] as String?,
        hasSandbox: (j['has_sandbox'] as bool?) ?? false,
        cosineSim: ((j['cosine_sim'] as num?) ?? 0).toDouble(),
        matchedSkills: (j['matched_skills'] as int?) ?? 0,
        requiredSkills: (j['required_skills'] as int?) ?? 0,
        videoPath: j['video_path'] as String?,
        posterPath: j['poster_path'] as String?,
      );
}
