import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_profile.dart';
import '../models/verification.dart';

abstract interface class StudentRepository {
  Future<StudentProfile?> fetchMyStudentProfile();
  Future<int> countAvailableJobs();

  /// The student's own skills with provenance (owner SELECT under RLS).
  Future<List<VerifiedSkill>> fetchMyVerifiedSkills();
}

class SupabaseStudentRepository implements StudentRepository {
  SupabaseStudentRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<StudentProfile?> fetchMyStudentProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('student_profiles')
        .select('*, universities(name)')
        .eq('profile_id', uid)
        .maybeSingle();
    return row == null ? null : StudentProfile.fromJson(row);
  }

  @override
  Future<int> countAvailableJobs() async {
    final rows = await _client.from('jobs').select('id').eq('published', true);
    return (rows as List).length;
  }

  @override
  Future<List<VerifiedSkill>> fetchMyVerifiedSkills() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await _client
        .from('student_skills')
        .select('skill_id, source, verified_at, evidence_json, skills(name, category)')
        .eq('student_id', uid) as List;
    final skills = [
      for (final r in rows) VerifiedSkill.fromJson((r as Map).cast<String, dynamic>()),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return skills;
  }
}
