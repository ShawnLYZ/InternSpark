import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  group('shadowGate', () {
    test('no video → always swipeable (icon fallback)', () {
      expect(shadowGate(const ShadowGateState(hasVideo: false)), isTrue);
    });
    test('video, not yet viewed or expanded → gated', () {
      expect(shadowGate(const ShadowGateState(hasVideo: true)), isFalse);
    });
    test('video, tapped to expand → unlocked', () {
      expect(shadowGate(const ShadowGateState(hasVideo: true, expanded: true)), isTrue);
    });
    test('video, enough seconds viewed → unlocked', () {
      expect(shadowGate(const ShadowGateState(hasVideo: true, secondsViewed: 3)), isTrue);
    });
    test('a slow clip (few seconds, not expanded) never hard-blocks — explicit unlock via expand', () {
      // The card always offers tap-to-expand, so the gate can always be opened.
      expect(shadowGate(const ShadowGateState(hasVideo: true, secondsViewed: 1, expanded: true)), isTrue);
    });
  });
}
