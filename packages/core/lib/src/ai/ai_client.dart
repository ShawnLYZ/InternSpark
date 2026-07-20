/// Result of an [AiClient.generate] call.
class AiGenerateResult {
  const AiGenerateResult({required this.text, required this.usedFallback});

  /// The generated text (or the templated fallback when [usedFallback]).
  final String text;

  /// True when the per-day budget tripped and a templated fallback was
  /// returned instead of a live model call.
  final bool usedFallback;
}

/// The single seam through which the apps reach Gemini + embeddings.
///
/// Implementations MUST NOT hold provider API keys: the production
/// implementation (Plan 3) calls a Supabase Edge Function that holds the
/// key server-side. Tests inject [FakeAiClient] for deterministic behavior.
abstract interface class AiClient {
  /// Returns a gte-small embedding (length 384) for [text].
  Future<List<double>> embed(String text);

  /// Generates text for a named [task] from [prompt].
  Future<AiGenerateResult> generate({required String task, required String prompt});
}
