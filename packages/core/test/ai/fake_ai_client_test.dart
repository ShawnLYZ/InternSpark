import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  test('embed returns a deterministic 384-length vector', () async {
    const client = FakeAiClient();
    final a = await client.embed('hello world');
    final b = await client.embed('hello world');
    expect(a.length, 384);
    expect(a, b);
  });

  test('generate echoes task + prompt by default', () async {
    const client = FakeAiClient();
    final result = await client.generate(task: 'rationale', prompt: 'grow here');
    expect(result.usedFallback, isFalse);
    expect(result.text, contains('rationale'));
    expect(result.text, contains('grow here'));
  });

  test('generate returns a templated fallback when the budget trips', () async {
    const client = FakeAiClient(forceFallback: true);
    final result = await client.generate(task: 'resume', prompt: 'anything');
    expect(result.usedFallback, isTrue);
    expect(result.text, contains('resume'));
  });
}
