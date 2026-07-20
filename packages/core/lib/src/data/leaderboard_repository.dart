import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_ghost_stats.dart';

abstract interface class LeaderboardRepository {
  /// All companies' non-PII ghost/response aggregates (public).
  Future<List<CompanyGhostStats>> leaderboard();

  /// The signed-in employer's own company stat (or null if not found).
  Future<CompanyGhostStats?> myCompanyStat();
}

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  SupabaseLeaderboardRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<CompanyGhostStats>> leaderboard() async {
    final rows = await _client.rpc('leaderboard') as List;
    return rows.map((r) => CompanyGhostStats.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<CompanyGhostStats?> myCompanyStat() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('employer_profiles').select('company_id').eq('profile_id', uid).maybeSingle();
    final cid = link?['company_id'] as String?;
    if (cid == null) return null;
    final all = await leaderboard();
    return all.where((s) => s.companyId == cid).firstOrNull;
  }
}
