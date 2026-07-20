import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company.dart';

abstract interface class EmployerRepository {
  Future<Company?> fetchMyCompany();
  Future<int> countMyJobs();
}

class SupabaseEmployerRepository implements EmployerRepository {
  SupabaseEmployerRepository(this._client);
  final SupabaseClient _client;

  Future<String?> _companyId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('employer_profiles').select('company_id').eq('profile_id', uid).maybeSingle();
    return link?['company_id'] as String?;
  }

  @override
  Future<Company?> fetchMyCompany() async {
    final cid = await _companyId();
    if (cid == null) return null;
    final row = await _client.from('companies').select().eq('id', cid).maybeSingle();
    return row == null ? null : Company.fromJson(row);
  }

  @override
  Future<int> countMyJobs() async {
    final cid = await _companyId();
    if (cid == null) return 0;
    final rows = await _client.from('jobs').select('id').eq('company_id', cid);
    return (rows as List).length;
  }
}
