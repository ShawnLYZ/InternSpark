import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design/app_tokens.dart';

/// The direction a [SwipeCard] was committed in.
enum SwipeDirection { left, right, up }

/// Imperative handle for a [SwipeCard] so secondary buttons (and assistive
/// tech) can trigger the *same* animated swipe a drag would — keeping the
/// gesture the hero interaction while still offering an accessible fallback
/// (`gesture-alternative`).
class SwipeCardController {
  _SwipeCardState? _state;

  void _bind(_SwipeCardState s) => _state = s;
  void _unbind(_SwipeCardState s) {
    if (identical(_state, s)) _state = null;
  }

  bool get isAttached => _state != null;

  void swipeLeft() => _state?.fling(SwipeDirection.left);
  void swipeRight() => _state?.fling(SwipeDirection.right);
  void swipeUp() => _state?.fling(SwipeDirection.up);
  void swipe(SwipeDirection direction) => _state?.fling(direction);
}

/// The one swipe/queue card (Reuse Register): a draggable card that follows the
/// finger with rotation, reveals directional stamps, and commits on a distance
/// **or** velocity threshold — otherwise springs back. Both the student deck
/// (swipe internships) and the employer queue (swipe applicants) build on it.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.child,
    required this.onSwiped,
    this.controller,
    this.likeLabel = 'APPLY',
    this.nopeLabel = 'PASS',
    this.superLabel,
    this.likeColor = AppTokens.swipeLike,
    this.nopeColor = AppTokens.swipeNope,
    this.superColor = AppTokens.swipeSuper,
    this.allowUp = false,
    this.threshold = 0.28,
    this.onProgress,
    this.canSwipe,
    this.onBlocked,
  });

  /// The card face.
  final Widget child;

  /// Fired once the card has animated off-screen in [SwipeDirection].
  final ValueChanged<SwipeDirection> onSwiped;

  /// Optional guard: if it returns false for the intended [SwipeDirection] the
  /// card springs back instead of committing (e.g. apply is gated behind the
  /// day-in-the-life video). [onBlocked] fires so the screen can hint why.
  final bool Function(SwipeDirection direction)? canSwipe;
  final ValueChanged<SwipeDirection>? onBlocked;

  /// Optional imperative handle (buttons / a11y).
  final SwipeCardController? controller;

  final String likeLabel;
  final String nopeLabel;
  final String? superLabel;
  final Color likeColor;
  final Color nopeColor;
  final Color superColor;

  /// Whether an upward swipe is a committable third action.
  final bool allowUp;

  /// Commit distance as a fraction of the card's width/height.
  final double threshold;

  /// Live drag progress in [-1, 1] (right positive) — lets a parent react
  /// (e.g. scale the card peeking behind). Optional.
  final ValueChanged<double>? onProgress;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  // Created eagerly in initState (not a lazy `late final`) so that disposing a
  // card that was never dragged doesn't build a ticker on a deactivated element.
  late final AnimationController _anim;

  Offset _drag = Offset.zero;
  Offset _animOffset = Offset.zero;
  bool _animating = false;
  SwipeDirection? _pending;
  Animation<Offset>? _flight;
  Size _size = Size.zero;

  Offset get _offset => _animating ? _animOffset : _drag;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: AppTokens.durBase)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    widget.controller?._bind(this);
  }

  @override
  void didUpdateWidget(covariant SwipeCard old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller?._unbind(this);
      widget.controller?._bind(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._unbind(this);
    _anim.dispose();
    super.dispose();
  }

  // ── Gesture ────────────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails _) => _flight = null;

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _drag += d.delta);
    _reportProgress();
  }

  void _onPanEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond;
    final w = _size.width <= 0 ? 360.0 : _size.width;
    final h = _size.height <= 0 ? 560.0 : _size.height;
    final overX = _drag.dx.abs() > w * widget.threshold || v.dx.abs() > 820;
    final overUp = widget.allowUp && (-_drag.dy > h * widget.threshold || -v.dy > 950);
    final verticalDominant = _drag.dy.abs() > _drag.dx.abs();

    if (overUp && verticalDominant) {
      fling(SwipeDirection.up);
    } else if (overX) {
      fling(_drag.dx > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      _springBack();
    }
  }

  void _reportProgress() {
    if (widget.onProgress == null) return;
    final w = _size.width <= 0 ? 360.0 : _size.width;
    widget.onProgress!((_offset.dx / (w * widget.threshold)).clamp(-1.0, 1.0));
  }

  // ── Commit / return ──────────────────────────────────────────────────────────

  /// Programmatically commit a swipe (used by [SwipeCardController]).
  void fling(SwipeDirection direction) {
    if (widget.canSwipe != null && !widget.canSwipe!(direction)) {
      HapticFeedback.lightImpact();
      widget.onBlocked?.call(direction);
      _springBack();
      return;
    }
    final w = _size.width <= 0 ? 360.0 : _size.width;
    final h = _size.height <= 0 ? 560.0 : _size.height;
    final end = switch (direction) {
      SwipeDirection.left => Offset(-1.8 * w, _drag.dy + 0.12 * h),
      SwipeDirection.right => Offset(1.8 * w, _drag.dy + 0.12 * h),
      SwipeDirection.up => Offset(_drag.dx, -1.6 * h),
    };
    HapticFeedback.mediumImpact();
    _animateTo(end, AppTokens.curveExit, commit: direction);
  }

  void _springBack() => _animateTo(Offset.zero, Curves.easeOutBack, commit: null);

  void _animateTo(Offset end, Curve curve, {required SwipeDirection? commit}) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _pending = commit;
    _flight = Tween<Offset>(begin: _drag, end: end)
        .animate(CurvedAnimation(parent: _anim, curve: curve));
    _animating = true;
    _anim
      ..duration = reduce ? Duration.zero : (commit != null ? AppTokens.durBase : AppTokens.durFast)
      ..reset()
      ..forward();
  }

  void _onTick() {
    setState(() => _animOffset = _flight?.value ?? Offset.zero);
    _reportProgress();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final committed = _pending;
    // Reset internal state either way.
    _drag = Offset.zero;
    _animOffset = Offset.zero;
    _flight = null;
    _pending = null;
    if (committed != null) {
      // Leave the last (off-screen) frame painted; the parent swaps this card
      // out on rebuild, avoiding a recenter flash. Just notify.
      widget.onSwiped(committed);
    } else {
      setState(() => _animating = false);
    }
  }

  // ── Paint ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final o = _offset;
        final w = _size.width <= 0 ? 360.0 : _size.width;
        final h = _size.height <= 0 ? 560.0 : _size.height;
        final like = (o.dx / (w * widget.threshold)).clamp(0.0, 1.0);
        final nope = (-o.dx / (w * widget.threshold)).clamp(0.0, 1.0);
        final supered =
            widget.allowUp ? (-o.dy / (h * widget.threshold)).clamp(0.0, 1.0) : 0.0;
        final angle = reduce ? 0.0 : (o.dx / w) * 0.20;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _animating ? null : _onPanStart,
          onPanUpdate: _animating ? null : _onPanUpdate,
          onPanEnd: _animating ? null : _onPanEnd,
          child: Transform.translate(
            offset: o,
            child: Transform.rotate(
              angle: angle,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  widget.child,
                  if (like > 0.01)
                    _Stamp(label: widget.likeLabel, color: widget.likeColor, opacity: like, align: Alignment.topLeft, angle: -0.32),
                  if (nope > 0.01)
                    _Stamp(label: widget.nopeLabel, color: widget.nopeColor, opacity: nope, align: Alignment.topRight, angle: 0.32),
                  if (supered > 0.01 && widget.superLabel != null)
                    _Stamp(label: widget.superLabel!, color: widget.superColor, opacity: supered, align: Alignment.bottomCenter, angle: 0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The tilted "APPLY / PASS" ink stamp that fades in as you drag.
class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.opacity,
    required this.align,
    required this.angle,
  });

  final String label;
  final Color color;
  final double opacity;
  final Alignment align;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Align(
          alignment: align,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: angle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  color: color.withValues(alpha: 0.08),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
