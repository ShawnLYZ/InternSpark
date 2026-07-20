/// An anonymous review row (author id intentionally absent — never surfaced).
class Review {
  const Review({
    required this.mentorship,
    required this.workload,
    required this.psychSafety,
    this.comment,
    this.createdAt,
  });

  final int mentorship;
  final int workload;
  final int psychSafety;
  final String? comment;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        mentorship: (j['mentorship'] as num).toInt(),
        workload: (j['workload'] as num).toInt(),
        psychSafety: (j['psych_safety'] as num).toInt(),
        comment: j['comment'] as String?,
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String),
      );
}

/// The `company_mentorship_score` aggregate for a company.
class CompanyMentorship {
  const CompanyMentorship({
    required this.companyId,
    required this.companyName,
    required this.reviewCount,
    required this.mentorshipScore,
    this.workloadScore = 0,
    this.psychSafetyScore = 0,
  });

  final String companyId;
  final String companyName;
  final int reviewCount;
  final double mentorshipScore;
  final double workloadScore;
  final double psychSafetyScore;

  factory CompanyMentorship.fromJson(Map<String, dynamic> j) => CompanyMentorship(
        companyId: j['company_id'] as String,
        companyName: (j['company_name'] as String?) ?? '',
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
        mentorshipScore: (j['mentorship_score'] as num?)?.toDouble() ?? 0,
        workloadScore: (j['workload_score'] as num?)?.toDouble() ?? 0,
        psychSafetyScore: (j['psych_safety_score'] as num?)?.toDouble() ?? 0,
      );
}
