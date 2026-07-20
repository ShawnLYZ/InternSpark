import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/matching.dart';
import '../models/deck_candidate.dart';

abstract interface class DeckRepository {
  /// Hard-filtered candidates from the RPC, blended + ordered by `core`.
  Future<List<DeckCandidate>> fetchDeck();

  /// 'left' = pass, 'right' = apply. Returns the application id for right swipes, null for left.
  Future<String?> swipe({required String jobId, required String direction});

  /// Removes the last reversible swipe; returns the re-decked job id (or null).
  Future<String?> undoLast();
}

class SupabaseDeckRepository implements DeckRepository {
  SupabaseDeckRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<DeckCandidate>> fetchDeck() async {
    final rows = await _client.rpc('deck_candidates') as List;
    final scored = rows.map((r) {
      final map = (r as Map).cast<String, dynamic>();
      if (map['video_path'] != null) {
        map['video_path'] = _client.storage.from('shadow-videos').getPublicUrl(map['video_path'] as String);
      }
      if (map['poster_path'] != null) {
        map['poster_path'] = _client.storage.from('shadow-videos').getPublicUrl(map['poster_path'] as String);
      }
      final c = DeckCandidate.fromJson(map);
      final s = deckScore(
        cosineSim: c.cosineSim,
        skillOverlap: skillOverlapRatio(c.matchedSkills, c.requiredSkills),
        salaryFit: salaryFit(map['salary_expectation'] as int?, c.salaryMin, c.salaryMax),
        roleMatch: _contains(map['role_interests'], c.roleFunction),
        industryMatch: _contains(map['industry_interests'], c.industry),
      );
      return c.withScore(s);
    }).toList();
    return sortDeck(scored);
  }

  static bool _contains(Object? list, String? value) {
    if (list is! List || value == null) return false;
    return list.map((e) => '$e'.toLowerCase()).contains(value.toLowerCase());
  }

  @override
  Future<String?> swipe({required String jobId, required String direction}) async {
    final res = await _client.rpc('swipe_job', params: {'p_job': jobId, 'p_direction': direction});
    return (res as Map?)?['id'] as String?;
  }

  @override
  Future<String?> undoLast() async {
    final res = await _client.rpc('undo_last_swipe');
    return res as String?;
  }
}
