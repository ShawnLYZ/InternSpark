import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/applicant_row.dart';

abstract interface class ApplicantsRepository {
  Future<List<ApplicantRow>> applicants(String jobId);
  Future<void> employerSwipe({required String applicationId, required String direction});
  Future<void> requestInterview({
    required String applicationId, required String email, required String link, required DateTime date,
  });
  Future<void> makeOffer(String applicationId);
  Future<void> pass(String applicationId);
}

class SupabaseApplicantsRepository implements ApplicantsRepository {
  SupabaseApplicantsRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<ApplicantRow>> applicants(String jobId) async {
    final rows = await _client.rpc('employer_applicants', params: {'p_job_id': jobId}) as List;
    return rows.map((r) => ApplicantRow.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<void> employerSwipe({required String applicationId, required String direction}) async =>
      _client.rpc('employer_swipe', params: {'p_application': applicationId, 'p_direction': direction});

  @override
  Future<void> requestInterview({
    required String applicationId, required String email, required String link, required DateTime date,
  }) async =>
      _client.rpc('request_interview', params: {
        'p_application': applicationId, 'p_email': email, 'p_link': link,
        'p_date': date.toIso8601String(),
      });

  @override
  Future<void> makeOffer(String id) async => _client.rpc('make_offer', params: {'p_application': id});

  @override
  Future<void> pass(String id) async => _client.rpc('employer_pass', params: {'p_application': id});
}
