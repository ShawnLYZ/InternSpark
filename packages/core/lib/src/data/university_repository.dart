import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/university.dart';

abstract interface class UniversityRepository {
  Future<University?> fetchMyUniversity();
  Future<int> countMyStudents();

  /// Catalog for the wizard's university picker (post-auth readable under RLS).
  Future<List<University>> listUniversities();
}

class SupabaseUniversityRepository implements UniversityRepository {
  SupabaseUniversityRepository(this._client);
  final SupabaseClient _client;

  Future<String?> _universityId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('university_profiles').select('university_id').eq('profile_id', uid).maybeSingle();
    return link?['university_id'] as String?;
  }

  @override
  Future<University?> fetchMyUniversity() async {
    final vid = await _universityId();
    if (vid == null) return null;
    final row = await _client.from('universities').select().eq('id', vid).maybeSingle();
    return row == null ? null : University.fromJson(row);
  }

  @override
  Future<int> countMyStudents() async {
    final vid = await _universityId();
    if (vid == null) return 0;
    final rows = await _client.from('student_profiles').select('profile_id').eq('university_id', vid);
    return (rows as List).length;
  }

  @override
  Future<List<University>> listUniversities() async {
    final rows = await _client.from('universities').select('id, name').order('name') as List;
    return [for (final r in rows) University.fromJson((r as Map).cast<String, dynamic>())];
  }
}
