/// The deck card's shadow-video viewing state.
class ShadowGateState {
  const ShadowGateState({this.hasVideo = false, this.secondsViewed = 0, this.expanded = false});
  final bool hasVideo;
  final int secondsViewed;
  final bool expanded;
}

/// Soft gate: a swipe-right is allowed when there is no video, OR the viewer
/// expanded the clip, OR they watched at least [thresholdSeconds]. Tap-to-expand
/// is always available, so a slow/missing clip never hard-blocks.
bool shadowGate(ShadowGateState s, {int thresholdSeconds = 3}) =>
    !s.hasVideo || s.expanded || s.secondsViewed >= thresholdSeconds;
