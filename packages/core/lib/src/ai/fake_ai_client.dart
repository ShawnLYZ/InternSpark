import 'ai_client.dart';

/// Deterministic [AiClient] for tests and local development.
///
/// - [embed] returns a fixed 384-length vector derived from the input, so
///   equal inputs yield equal vectors (cache-friendly) with no network call.
/// - [generate] echoes a canned response, or a templated fallback when
///   [forceFallback] is set — exercising the budget-tripped path.
class FakeAiClient implements AiClient {
  const FakeAiClient({this.forceFallback = false});

  /// When true, [generate] returns a templated fallback (usedFallback=true).
  final bool forceFallback;

  static const int embeddingDimension = 384;

  @override
  Future<List<double>> embed(String text) async {
    final seed = text.length % 7;
    return List<double>.generate(
      embeddingDimension,
      (i) => ((i + seed) % 10) / 10.0,
    );
  }

  @override
  Future<AiGenerateResult> generate({required String task, required String prompt}) async {
    if (forceFallback) {
      return AiGenerateResult(
        text: '[$task unavailable — please try again later]',
        usedFallback: true,
      );
    }
    return AiGenerateResult(text: 'FAKE($task): ${prompt.trim()}', usedFallback: false);
  }
}
