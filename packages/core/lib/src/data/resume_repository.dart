import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/resume.dart';
import '../domain/resume_builder.dart';
import '../pdf/resume_pdf.dart';

abstract interface class ResumeRepository {
  /// Generates a grounded resume for [jobId] from the student's entered data.
  Future<ResumeJson> generateResume(String jobId);

  /// Renders [resume] to PDF, uploads it, and attaches both to the application.
  Future<void> attachResume({required String applicationId, required ResumeJson resume});

  /// Employer's pre-match view: redacted resume JSON via the SECURITY DEFINER RPC.
  Future<ResumeJson?> applicantResume(String applicationId);
}

class SupabaseResumeRepository implements ResumeRepository {
  SupabaseResumeRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  @override
  Future<ResumeJson> generateResume(String jobId) async {
    final uid = _client.auth.currentUser!.id;
    final sp = await _client.from('student_profiles')
        .select('full_name, major, growth_statement').eq('profile_id', uid).single();
    final skills = await _client.from('student_skills').select('skills(name)').eq('student_id', uid) as List;
    final job = await _client.from('jobs')
        .select('title, description, industry, job_required_skills(skills(name))').eq('id', jobId).single();

    final req = buildResumeRequest(
      fullName: sp['full_name'] as String,
      major: sp['major'] as String?,
      growthStatement: (sp['growth_statement'] as String?) ?? '',
      skills: skills.map((s) => (s['skills'] as Map)['name'] as String).toList(),
      experiences: const [], // P2A: entered experience list is empty in seed; growth_statement carries narrative
      jobTitle: job['title'] as String,
      jobDescription: (job['description'] as String?) ?? '',
      jobRequiredSkills: ((job['job_required_skills'] as List?) ?? const [])
          .map((r) => ((r['skills'] as Map)['name']) as String).toList(),
      jobIndustry: job['industry'] as String?,
    );

    final res = await _ai.generate(task: 'resume', prompt: jsonEncode(req));
    if (res.usedFallback) {
      // Templated fallback: a minimal grounded resume from entered fields only.
      return ResumeJson(
        name: sp['full_name'] as String,
        headline: job['title'] as String,
        summary: (sp['growth_statement'] as String?) ?? '',
        sections: [ResumeSection(title: 'Skills', bullets: req['student']['skills'] as List<String>? ?? const [])],
      );
    }
    return ResumeJson.fromJson(_extractJson(res.text));
  }

  @override
  Future<void> attachResume({required String applicationId, required ResumeJson resume}) async {
    final uid = _client.auth.currentUser!.id;
    final Uint8List bytes = await buildResumePdf(resume);
    final path = '$uid/$applicationId.pdf';
    await _client.storage.from('resumes').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(contentType: 'application/pdf', upsert: true),
        );
    await _client.from('applications')
        .update({'resume_json': resume.toJson(), 'resume_pdf_path': path})
        .eq('id', applicationId);
  }

  @override
  Future<ResumeJson?> applicantResume(String applicationId) async {
    final res = await _client.rpc('applicant_resume', params: {'p_application': applicationId});
    if (res == null) return null;
    return ResumeJson.fromJson((res as Map).cast<String, dynamic>());
  }

  /// Tolerates models that wrap JSON in prose/```json fences.
  static Map<String, dynamic> _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) return {'name': 'Candidate'};
    return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
  }
}
