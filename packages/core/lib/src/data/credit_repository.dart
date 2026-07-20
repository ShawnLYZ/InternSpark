import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/credit.dart';
import '../pdf/credit_pdf.dart';

abstract interface class CreditRepository {
  Future<List<CreditRequest>> queue();
  /// Gemini JD→curriculum mapping (university-side: it holds curriculum_skills).
  Future<CreditMapping> generateMapping(String jobId);
  /// Render the pre-filled PDF, upload it, and store the mapping on the request.
  Future<void> attachMapping({
    required String requestId, required String jobTitle, required String studentName, required CreditMapping mapping,
  });
  Future<void> approve({required String requestId, required String signerName});
}

class SupabaseCreditRepository implements CreditRepository {
  SupabaseCreditRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  Future<String?> _universityId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('university_profiles').select('university_id').eq('profile_id', uid).maybeSingle();
    return link?['university_id'] as String?;
  }

  @override
  Future<List<CreditRequest>> queue() async {
    final rows = await _client.rpc('university_credit_requests') as List;
    return rows.map((r) => CreditRequest.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<CreditMapping> generateMapping(String jobId) async {
    final vid = await _universityId();
    final job = await _client.from('jobs')
        .select('title, description, job_required_skills(skills(name)), job_skills_gained(skills(name))')
        .eq('id', jobId).single();
    final curric = vid == null
        ? <dynamic>[]
        : await _client.from('curriculum_skills').select('skills(name)').eq('university_id', vid) as List;

    final reqSkills = ((job['job_required_skills'] as List?) ?? const []).map((r) => (r['skills'] as Map)['name']).toList();
    final gainSkills = ((job['job_skills_gained'] as List?) ?? const []).map((r) => (r['skills'] as Map)['name']).toList();
    final curriculum = curric.map((r) => (r['skills'] as Map)['name']).toList();

    final res = await _ai.generate(task: 'credit_map', prompt: jsonEncode({
      'instruction': 'Map this internship to the university curriculum. Output JSON '
          '{summary, satisfied:[{skill, evidence}]}. Only list curriculum skills the role plausibly develops.',
      'job': {'title': job['title'], 'description': job['description'],
              'required_skills': reqSkills, 'skills_gained': gainSkills},
      'curriculum_skills': curriculum,
    }));
    if (res.usedFallback) {
      return const CreditMapping(summary: 'Mapping unavailable — please review manually.', satisfied: []);
    }
    return CreditMapping.fromJson(_extractJson(res.text));
  }

  @override
  Future<void> attachMapping({
    required String requestId, required String jobTitle, required String studentName, required CreditMapping mapping,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final Uint8List bytes = await buildCreditPdf(jobTitle: jobTitle, studentName: studentName, mapping: mapping);
    final path = '$uid/credit-$requestId.pdf';
    await _client.storage.from('documents').uploadBinary(
          path, bytes, fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true));
    await _client.from('credit_requests')
        .update({'mapping_json': mapping.toJson(), 'pdf_path': path}).eq('id', requestId);
  }

  @override
  Future<void> approve({required String requestId, required String signerName}) async =>
      _client.rpc('approve_credit', params: {'p_request': requestId, 'p_signer': signerName});

  static Map<String, dynamic> _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return {'summary': '', 'satisfied': []};
    try {
      return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      return {'summary': '', 'satisfied': []};
    }
  }
}
