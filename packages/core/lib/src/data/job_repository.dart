import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/job.dart';

abstract interface class JobRepository {
  Future<List<Job>> myJobs();
  Future<Job?> fetchJob(String id);
  /// Creates/updates a job and refreshes its embedding from title + growth_text.
  Future<String> upsertJob(Map<String, dynamic> values);
  /// Optional AI-assist draft for the growth_text field.
  Future<String> draftGrowthText(String title, String description);
  /// Uploads a ≤60s clip to the shadow-videos bucket and records the job_media row.
  Future<void> setJobVideo({required String jobId, required Uint8List bytes, required String fileName});
}

class SupabaseJobRepository implements JobRepository {
  SupabaseJobRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  Future<String?> _companyId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final link = await _client.from('employer_profiles').select('company_id').eq('profile_id', uid).maybeSingle();
    return link?['company_id'] as String?;
  }

  @override
  Future<List<Job>> myJobs() async {
    final cid = await _companyId();
    if (cid == null) return [];
    final rows = await _client.from('jobs').select().eq('company_id', cid).order('created_at') as List;
    return rows.map((r) => Job.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<Job?> fetchJob(String id) async {
    final row = await _client.from('jobs').select().eq('id', id).maybeSingle();
    return row == null ? null : Job.fromJson(row);
  }

  @override
  Future<String> upsertJob(Map<String, dynamic> values) async {
    final cid = await _companyId();
    final embedding = await _ai.embed('${values['title']}. ${values['growth_text'] ?? ''}');
    final row = await _client.from('jobs').upsert({
      ...values,
      'company_id': cid,
      'embedding': embedding,
    }).select('id').single();
    return row['id'] as String;
  }

  @override
  Future<String> draftGrowthText(String title, String description) async {
    final res = await _ai.generate(
      task: 'growth_draft',
      prompt: 'Write a 2-sentence "where you will grow" blurb for an internship titled '
          '"$title". Context: $description. Focus on growth, mentorship, ownership.',
    );
    return res.text;
  }

  @override
  Future<void> setJobVideo({required String jobId, required Uint8List bytes, required String fileName}) async {
    final path = 'jobs/$jobId/$fileName';
    await _client.storage.from('shadow-videos').uploadBinary(
          path, bytes, fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true));
    await _client.from('job_media').delete().eq('job_id', jobId).eq('type', 'video');
    await _client.from('job_media').insert({'job_id': jobId, 'type': 'video', 'storage_path': path});
  }
}
