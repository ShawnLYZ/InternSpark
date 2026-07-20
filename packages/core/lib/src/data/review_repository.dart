import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';
import '../domain/comment_gate.dart';

abstract interface class ReviewRepository {
  Future<List<Review>> companyReviews(String companyId);
  Future<Review?> myReview(String companyId);
  Future<void> postReview({
    required String companyId, required int mentorship, required int workload,
    required int psychSafety, String? comment,
  });
  Future<void> deleteReview(String companyId);
  Future<List<CompanyMentorship>> mentorshipScores();

  /// Companies that have filed a report about the signed-in student (gate input).
  Future<List<ReportRef>> myReportRefs();
}

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client);
  final SupabaseClient _client;

  @override
  Future<List<Review>> companyReviews(String companyId) async {
    final rows = await _client.rpc('company_reviews', params: {'p_company': companyId}) as List;
    return rows.map((r) => Review.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<Review?> myReview(String companyId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client.from('reviews').select()
        .eq('student_id', uid).eq('company_id', companyId).maybeSingle();
    return row == null ? null : Review.fromJson(row);
  }

  @override
  Future<void> postReview({
    required String companyId, required int mentorship, required int workload,
    required int psychSafety, String? comment,
  }) async =>
      _client.rpc('post_review', params: {
        'p_company': companyId, 'p_mentorship': mentorship, 'p_workload': workload,
        'p_psych_safety': psychSafety, 'p_comment': comment,
      });

  @override
  Future<void> deleteReview(String companyId) async =>
      _client.rpc('delete_review', params: {'p_company': companyId});

  @override
  Future<List<CompanyMentorship>> mentorshipScores() async {
    final rows = await _client.from('company_mentorship_score').select() as List;
    return rows.map((r) => CompanyMentorship.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<List<ReportRef>> myReportRefs() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await _client.rpc('my_report_companies') as List;
    return rows
        .map((r) => ReportRef(studentId: uid, companyId: (r as Map)['company_id'] as String))
        .toList();
  }
}
