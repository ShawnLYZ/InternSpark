import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/roi.dart';
import '../models/skill.dart';

/// Everything the university ROI dashboard needs.
class RoiSummary {
  const RoiSummary({required this.placementRate, required this.demand, required this.gap});
  final double placementRate;
  final List<SkillDemand> demand;
  final List<String> gap;
}

abstract interface class RoiRepository {
  Future<RoiSummary> fetchRoi();
  Future<List<Skill>> allSkills();
  Future<List<Skill>> curriculumSkills();
  Future<void> addCurriculumSkill(String skillId);
  Future<void> removeCurriculumSkill(String skillId);
}

class SupabaseRoiRepository implements RoiRepository {
  SupabaseRoiRepository(this._client);
  final SupabaseClient _client;

  Future<String?> _universityId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('university_profiles').select('university_id').eq('profile_id', uid).maybeSingle();
    return link?['university_id'] as String?;
  }

  @override
  Future<RoiSummary> fetchRoi() async {
    final rate = await _client.rpc('university_placement_rate');
    final demandRows = await _client.from('market_demand').select().order('demand', ascending: false) as List;
    final gapRows = await _client.rpc('curriculum_gap') as List;

    final demand = demandRows
        .map((r) => SkillDemand(
              skill: (r as Map)['skill_name'] as String,
              weight: ((r['demand'] as num?) ?? 0).toDouble(),
              skillId: r['skill_id'] as String,
            ))
        .toList();
    final gap = gapRows.map((r) => (r as Map)['skill_name'] as String).toList();
    return RoiSummary(placementRate: ((rate as num?) ?? 0).toDouble(), demand: demand, gap: gap);
  }

  @override
  Future<List<Skill>> allSkills() async {
    final rows = await _client.from('skills').select().order('name') as List;
    return rows.map((r) => Skill.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<List<Skill>> curriculumSkills() async {
    final vid = await _universityId();
    if (vid == null) return [];
    final rows = await _client.from('curriculum_skills').select('skills(id, name, category)').eq('university_id', vid) as List;
    return rows.map((r) => Skill.fromJson(((r as Map)['skills'] as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<void> addCurriculumSkill(String skillId) async {
    final vid = await _universityId();
    if (vid == null) return;
    await _client.from('curriculum_skills').upsert(
      {'university_id': vid, 'skill_id': skillId},
      onConflict: 'university_id,skill_id',
    );
  }

  @override
  Future<void> removeCurriculumSkill(String skillId) async {
    final vid = await _universityId();
    if (vid == null) return;
    await _client.from('curriculum_skills').delete().eq('university_id', vid).eq('skill_id', skillId);
  }
}
