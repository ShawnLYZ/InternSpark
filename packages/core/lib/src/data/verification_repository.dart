import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/ai_client.dart';
import '../models/verification.dart';

/// The one new seam: wraps the whole verification workflow. The Supabase
/// implementation privately calls the `ai` Edge Function and Storage — UI
/// code never touches either, so client tests never mock Gemini.
abstract interface class VerificationRepository {
  /// True when the caller has an in-flight (resumable) session — part of the
  /// mobile gate's routing condition.
  Future<bool> hasActiveSession();

  Future<VerificationSession> startOrResume();

  Future<VerificationSession> submitInput({
    required String sessionId,
    required String universityId,
    required String course,
    required int year,
    required int semester,
  });

  Future<VerificationSession> confirmProgram({
    required String sessionId,
    String? programId,
    required bool accept,
  });

  /// Uploads to the owner-scoped `documents` bucket, inserts the pending
  /// `certifications` row (the ONLY insert students may make), then asks the
  /// agent to verify it. Returns the updated session AND the decided row.
  Future<({VerificationSession session, Certification certification})> uploadCertificate({
    required String sessionId,
    required Uint8List bytes,
    required String filename,
  });

  Future<VerificationSession> certificatesDone(String sessionId);

  /// Preferences are student-writable by design (not verified claims). The
  /// growth-statement embedding write is preserved exactly as before — deck
  /// ranking depends on it.
  Future<VerificationSession> savePreferences({
    required String sessionId,
    required String growthStatement,
    DateTime? availabilityStart,
    int? durationWeeks,
    String? remotePref,
    int? salaryExpectation,
    List<String> roleInterests,
    List<String> industryInterests,
  });

  Future<VerificationSession> complete(String sessionId);
}

class SupabaseVerificationRepository implements VerificationRepository {
  SupabaseVerificationRepository(this._client, this._ai);
  final SupabaseClient _client;
  final AiClient _ai;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final res = await _client.functions.invoke('ai', body: body);
    return (res.data as Map).cast<String, dynamic>();
  }

  VerificationSession _session(Map<String, dynamic> data) =>
      VerificationSession.fromJson((data['session'] as Map).cast<String, dynamic>());

  @override
  Future<bool> hasActiveSession() async {
    final rows = await _client
        .from('verification_sessions')
        .select('id')
        .isFilter('completed_at', null)
        .limit(1) as List;
    return rows.isNotEmpty;
  }

  @override
  Future<VerificationSession> startOrResume() async =>
      _session(await _invoke({'task': 'verification_start'}));

  @override
  Future<VerificationSession> submitInput({
    required String sessionId,
    required String universityId,
    required String course,
    required int year,
    required int semester,
  }) async =>
      _session(await _invoke({
        'task': 'verification_advance',
        'session_id': sessionId,
        'action': 'submit_input',
        'university_id': universityId,
        'course': course,
        'year': year,
        'semester': semester,
      }));

  @override
  Future<VerificationSession> confirmProgram({
    required String sessionId,
    String? programId,
    required bool accept,
  }) async =>
      _session(await _invoke({
        'task': 'verification_advance',
        'session_id': sessionId,
        'action': 'confirm_program',
        if (programId != null) 'program_id': programId,
        'accept': accept,
      }));

  @override
  Future<({VerificationSession session, Certification certification})> uploadCertificate({
    required String sessionId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/certs/${DateTime.now().millisecondsSinceEpoch}_$filename';
    await _client.storage.from('documents').uploadBinary(
          path, bytes,
          fileOptions: FileOptions(contentType: _mime(filename)),
        );
    final row = await _client.from('certifications').insert({
      'student_id': uid,
      'session_id': sessionId,
      'storage_path': path,
      'original_filename': filename,
      'status': 'pending',
    }).select().single();
    final data = await _invoke({
      'task': 'verification_advance',
      'session_id': sessionId,
      'action': 'submit_certificate',
      'certification_id': row['id'],
    });
    return (
      session: _session(data),
      certification: Certification.fromJson((data['certification'] as Map).cast<String, dynamic>()),
    );
  }

  static String _mime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  @override
  Future<VerificationSession> certificatesDone(String sessionId) async =>
      _session(await _invoke({
        'task': 'verification_advance',
        'session_id': sessionId,
        'action': 'certificates_done',
      }));

  @override
  Future<VerificationSession> savePreferences({
    required String sessionId,
    required String growthStatement,
    DateTime? availabilityStart,
    int? durationWeeks,
    String? remotePref,
    int? salaryExpectation,
    List<String> roleInterests = const [],
    List<String> industryInterests = const [],
  }) async {
    final uid = _client.auth.currentUser!.id;
    final embedding = await _ai.embed(growthStatement);
    await _client.from('student_profiles').update({
      'growth_statement': growthStatement,
      'availability_start': availabilityStart?.toIso8601String().substring(0, 10),
      'duration_weeks': durationWeeks,
      'remote_pref': remotePref,
      'salary_expectation': salaryExpectation,
      'role_interests': roleInterests,
      'industry_interests': industryInterests,
      'growth_embedding': embedding,
    }).eq('profile_id', uid);
    return _session(await _invoke({
      'task': 'verification_advance',
      'session_id': sessionId,
      'action': 'preferences_saved',
    }));
  }

  @override
  Future<VerificationSession> complete(String sessionId) async =>
      _session(await _invoke({
        'task': 'verification_advance',
        'session_id': sessionId,
        'action': 'complete',
      }));
}
