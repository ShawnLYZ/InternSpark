import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/sandbox.dart';

abstract interface class SandboxRepository {
  // Student
  Future<List<SandboxSubmission>> mySandboxes();
  Future<void> saveDraft({required String submissionId, required String text, String? fileRef});
  Future<void> submit(String submissionId);
  Future<String> uploadFile({required String submissionId, required Uint8List bytes, required String fileName});
  // Employer
  Future<SandboxTask?> jobSandboxTask(String jobId);
  Future<String> generatePrompt(String jobId);
  Future<void> configureSandbox({required String jobId, required String source, required String prompt, required bool approved});
  Future<List<SandboxSubmission>> jobSubmissions(String jobId);
  Future<String> assess(String submissionText);
  Future<void> recordVerdict({required String submissionId, required String verdict, String? notes, String? aiAssessment});
}

class SupabaseSandboxRepository implements SandboxRepository {
  SupabaseSandboxRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  @override
  Future<List<SandboxSubmission>> mySandboxes() async {
    final rows = await _client.rpc('my_sandboxes') as List;
    return rows.map((r) => SandboxSubmission.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<void> saveDraft({required String submissionId, required String text, String? fileRef}) async =>
      _client.rpc('save_sandbox_draft', params: {'p_submission': submissionId, 'p_text': text, 'p_file_ref': fileRef});

  @override
  Future<void> submit(String submissionId) async =>
      _client.rpc('submit_sandbox', params: {'p_submission': submissionId});

  @override
  Future<String> uploadFile({required String submissionId, required Uint8List bytes, required String fileName}) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/$submissionId/$fileName';
    await _client.storage.from('sandbox-files').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  @override
  Future<SandboxTask?> jobSandboxTask(String jobId) async {
    final row = await _client.from('sandbox_tasks').select().eq('job_id', jobId).maybeSingle();
    return row == null ? null : SandboxTask.fromJson(row);
  }

  @override
  Future<String> generatePrompt(String jobId) async {
    final job = await _client.from('jobs').select('title, growth_text, description').eq('id', jobId).single();
    final res = await _ai.generate(task: 'sandbox_gen', prompt:
        'Write a tiny (~1-3h) try-out task for a "${job['title']}" intern. '
        'Context: ${job['growth_text']} ${job['description']}. '
        'It must need only text + an optional file — no code execution. Output the task prompt only.');
    return res.text;
  }

  @override
  Future<void> configureSandbox({required String jobId, required String source, required String prompt, required bool approved}) async =>
      _client.rpc('configure_sandbox', params: {'p_job': jobId, 'p_source': source, 'p_prompt': prompt, 'p_approved': approved});

  @override
  Future<List<SandboxSubmission>> jobSubmissions(String jobId) async {
    final rows = await _client.rpc('job_sandbox_submissions', params: {'p_job': jobId}) as List;
    return rows.map((r) => SandboxSubmission.fromJson((r as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<String> assess(String submissionText) async {
    final res = await _ai.generate(task: 'sandbox_assess', prompt:
        'Assess this intern try-out submission for clarity, effort, and fit. '
        'Read the text only; do NOT execute code. 3 sentences.\n\n$submissionText');
    return res.text;
  }

  @override
  Future<void> recordVerdict({required String submissionId, required String verdict, String? notes, String? aiAssessment}) async =>
      _client.rpc('record_sandbox_verdict', params: {
        'p_submission': submissionId, 'p_verdict': verdict, 'p_notes': notes, 'p_ai_assessment': aiAssessment,
      });
}
