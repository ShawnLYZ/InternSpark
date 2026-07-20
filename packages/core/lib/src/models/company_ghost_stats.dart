/// Per-company ghost/response aggregate from the `leaderboard()` RPC.
class CompanyGhostStats {
  const CompanyGhostStats({
    required this.companyId,
    required this.companyName,
    required this.totalMatches,
    this.ghostRate,
    this.avgResponseSecs,
  });

  final String companyId;
  final String companyName;
  final int totalMatches;

  /// Null when no matches in the window.
  final double? ghostRate;
  final double? avgResponseSecs;

  factory CompanyGhostStats.fromJson(Map<String, dynamic> j) => CompanyGhostStats(
        companyId: j['company_id'] as String,
        companyName: (j['company_name'] as String?) ?? '',
        totalMatches: (j['total_matches'] as int?) ?? 0,
        ghostRate: (j['ghost_rate'] as num?)?.toDouble(),
        avgResponseSecs: (j['avg_response_secs'] as num?)?.toDouble(),
      );
}
