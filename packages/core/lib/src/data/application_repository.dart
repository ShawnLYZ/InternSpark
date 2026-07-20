import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application.dart';

abstract interface class ApplicationRepository {
  Future<List<Application>> myApplications();
  Future<void> acceptOffer(String applicationId);
  Future<void> declineOffer(String applicationId);
}

class SupabaseApplicationRepository implements ApplicationRepository {
  SupabaseApplicationRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Application>> myApplications() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client
        .from('applications')
        .select('id, job_id, status, matched_at, jobs(title, companies(id, name))')
        .eq('student_id', uid)
        .order('created_at', ascending: false) as List;
    return rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      final job = (m['jobs'] as Map?)?.cast<String, dynamic>();
      final company = (job?['companies'] as Map?)?.cast<String, dynamic>();
      return Application.fromJson({
        ...m,
        'job_title': job?['title'],
        'company_id': company?['id'],
        'company_name': company?['name'],
      });
    }).toList();
  }

  @override
  Future<void> acceptOffer(String id) async =>
      _client.rpc('accept_offer', params: {'p_application': id});

  @override
  Future<void> declineOffer(String id) async =>
      _client.rpc('decline_offer', params: {'p_application': id});
}
