import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/report.dart';
import '../pdf/report_pdf.dart';

abstract interface class ReportRepository {
  Future<List<ReportableStudent>> reportableStudents();
  Future<String> draftNarrative({required String studentName, required int reliability, required int skill, required int communication});
  Future<void> fileReport({
    required String studentId, required String studentName, required String companyName,
    required int reliability, required int skill, required int communication, String? narrative,
  });
  Future<List<Report>> universityReports();
}

class SupabaseReportRepository implements ReportRepository {
  SupabaseReportRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  @override
  Future<List<ReportableStudent>> reportableStudents() async {
    final rows = await _client.rpc('reportable_students') as List;
    return rows.map((r) => ReportableStudent.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<String> draftNarrative({
    required String studentName, required int reliability, required int skill, required int communication,
  }) async {
    final res = await _ai.generate(
      task: 'report_draft',
      prompt: 'Write a 3-sentence performance narrative for intern $studentName. '
          'Reliability $reliability/5, skill $skill/5, communication $communication/5. '
          'Professional, specific, no invented facts.',
    );
    return res.text;
  }

  @override
  Future<void> fileReport({
    required String studentId, required String studentName, required String companyName,
    required int reliability, required int skill, required int communication, String? narrative,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final Uint8List bytes = await buildReportPdf(
      studentName: studentName, companyName: companyName,
      reliability: reliability, skill: skill, communication: communication, narrative: narrative,
    );
    final path = '$uid/report-$studentId.pdf';
    await _client.storage.from('documents').uploadBinary(
          path, bytes, fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true));
    await _client.rpc('file_report', params: {
      'p_student': studentId, 'p_reliability': reliability, 'p_skill': skill,
      'p_communication': communication, 'p_narrative': narrative, 'p_pdf_path': path,
    });
  }

  @override
  Future<List<Report>> universityReports() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final link = await _client.from('university_profiles').select('university_id').eq('profile_id', uid).maybeSingle();
    final vid = link?['university_id'] as String?;
    if (vid == null) return [];
    final rows = await _client.from('reports')
        .select('reliability, skill, communication, narrative, created_at, '
            'student_profiles(full_name), companies(name)')
        .eq('university_id', vid).order('created_at', ascending: false) as List;
    return rows.map((r) {
      final m = (r as Map).cast<String, dynamic>();
      return Report.fromJson({
        ...m,
        'student_name': (m['student_profiles'] as Map?)?['full_name'],
        'company_name': (m['companies'] as Map?)?['name'],
      });
    }).toList();
  }
}
