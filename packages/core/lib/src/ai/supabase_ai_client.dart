import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_client.dart';

/// Production [AiClient]: calls the `ai` Edge Function (which holds the Gemini
/// key server-side). Verified end-to-end via curl in Plan 2.
class SupabaseAiClient implements AiClient {
  SupabaseAiClient(this._client);
  final SupabaseClient _client;

  @override
  Future<List<double>> embed(String text) async {
    final res = await _client.functions.invoke('ai', body: {'task': 'embed', 'input': text});
    final data = res.data as Map<String, dynamic>;
    return (data['embedding'] as List).map((e) => (e as num).toDouble()).toList();
  }

  @override
  Future<AiGenerateResult> generate({required String task, required String prompt}) async {
    final res = await _client.functions.invoke('ai', body: {'task': task, 'prompt': prompt});
    final data = res.data as Map<String, dynamic>;
    return AiGenerateResult(
      text: (data['text'] as String?) ?? '',
      usedFallback: (data['usedFallback'] as bool?) ?? false,
    );
  }
}
