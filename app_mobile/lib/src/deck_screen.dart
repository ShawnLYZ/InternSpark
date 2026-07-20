import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internspark_core/internspark_core.dart';
import 'leaderboard_screen.dart';
import 'resume_review_screen.dart';

final deckProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(deckRepositoryProvider).fetchDeck());

final mentorshipScoresProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(reviewRepositoryProvider).mentorshipScores());

class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(deckProvider);
    final statsByCompany = {
      for (final s in (ref.watch(leaderboardProvider).asData?.value ?? const <CompanyGhostStats>[]))
        s.companyName: s,
    };
    final mentorshipByCompany = {
      for (final m in (ref.watch(mentorshipScoresProvider).asData?.value ?? const <CompanyMentorship>[]))
        m.companyName: m,
    };
    return deck.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(
          message: 'Could not load the deck.', onRetry: () => ref.invalidate(deckProvider)),
      data: (cards) {
        if (cards.isEmpty) return const _EmptyDeck();
        return _SwipeDeck(
          cards: cards,
          statsByCompany: statsByCompany,
          mentorshipByCompany: mentorshipByCompany,
        );
      },
    );
  }
}

/// The interactive, draggable deck. The card face is the hero; the round
/// buttons are secondary controls that trigger the same animated swipe.
class _SwipeDeck extends ConsumerStatefulWidget {
  const _SwipeDeck({
    required this.cards,
    required this.statsByCompany,
    required this.mentorshipByCompany,
  });

  final List<DeckCandidate> cards;
  final Map<String, CompanyGhostStats> statsByCompany;
  final Map<String, CompanyMentorship> mentorshipByCompany;

  @override
  ConsumerState<_SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends ConsumerState<_SwipeDeck> {
  final SwipeCardController _controller = SwipeCardController();
  late ShadowGateState _gate = ShadowGateState(hasVideo: widget.cards.first.hasVideo);

  DeckCandidate get _top => widget.cards.first;
  bool get _canApply => shadowGate(_gate);

  @override
  void didUpdateWidget(covariant _SwipeDeck old) {
    super.didUpdateWidget(old);
    if (old.cards.first.jobId != widget.cards.first.jobId) {
      _gate = ShadowGateState(hasVideo: widget.cards.first.hasVideo); // reset for next card
    }
  }

  Future<void> _apply() async {
    final card = _top;
    final appId = await ref.read(deckRepositoryProvider).swipe(jobId: card.jobId, direction: 'right');
    if (mounted && appId != null) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ResumeReviewScreen(applicationId: appId, jobId: card.jobId),
      ));
    }
    ref.invalidate(deckProvider);
  }

  Future<void> _pass() async {
    await ref.read(deckRepositoryProvider).swipe(jobId: _top.jobId, direction: 'left');
    ref.invalidate(deckProvider);
  }

  Future<void> _undo() async {
    await ref.read(deckRepositoryProvider).undoLast();
    ref.invalidate(deckProvider);
  }

  void _onSwiped(SwipeDirection dir) {
    if (dir == SwipeDirection.right) {
      _apply();
    } else {
      _pass();
    }
  }

  void _openVideo() => setState(() => _gate = ShadowGateState(
        hasVideo: _top.hasVideo,
        secondsViewed: _gate.secondsViewed,
        expanded: true,
      ));

  void _hintGate() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Watch the day-in-the-life to apply')));
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTokens.space16, AppTokens.space12, AppTokens.space16, AppTokens.space8),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (cards.length > 2)
                    _PeekCard(card: cards[2], scale: 0.90, dy: 22),
                  if (cards.length > 1)
                    _PeekCard(card: cards[1], scale: 0.95, dy: 11),
                  Positioned.fill(
                    child: SwipeCard(
                      key: ValueKey(_top.jobId),
                      controller: _controller,
                      onSwiped: _onSwiped,
                      canSwipe: (d) => d == SwipeDirection.right ? _canApply : true,
                      onBlocked: (_) => _hintGate(),
                      child: _DeckFace(
                        card: _top,
                        ghost: widget.statsByCompany[_top.companyName],
                        mentorship: widget.mentorshipByCompany[_top.companyName],
                        onWatch: _openVideo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            _ActionBar(
              canApply: _canApply,
              onPass: () => _controller.swipeLeft(),
              onApply: _canApply ? () => _controller.swipeRight() : null,
              onUndo: _undo,
            ),
            SizedBox(
              height: 22,
              child: _canApply
                  ? null
                  : Text('Watch the day-in-the-life to apply',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded card frame shared by the front face and the peeking cards.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child, this.shadow = true});
  final Widget child;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: shadow ? AppTokens.shadowLg(scheme.primary) : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        child: child,
      ),
    );
  }
}

/// A dimmed, non-interactive preview of an upcoming card, behind the front one.
class _PeekCard extends StatelessWidget {
  const _PeekCard({required this.card, required this.scale, required this.dy});
  final DeckCandidate card;
  final double scale;
  final double dy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: 0.6,
              child: _CardFrame(
                shadow: false,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                      ),
                    ),
                    child: Text(
                      card.companyName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
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

/// The full internship card face.
class _DeckFace extends StatelessWidget {
  const _DeckFace({
    required this.card,
    required this.onWatch,
    this.ghost,
    this.mentorship,
  });

  final DeckCandidate card;
  final VoidCallback onWatch;
  final CompanyGhostStats? ghost;
  final CompanyMentorship? mentorship;

  double get _fit =>
      card.requiredSkills > 0 ? card.matchedSkills / card.requiredSkills : card.score.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        children: [
          Expanded(flex: 46, child: _Media(card: card, onWatch: onWatch)),
          Expanded(flex: 54, child: _Body(card: card, fit: _fit, ghost: ghost, mentorship: mentorship)),
        ],
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.card, required this.onWatch});
  final DeckCandidate card;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.primary, scheme.tertiary],
    );

    final poster = card.hasVideo && card.posterPath != null
        ? Image.network(card.posterPath!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(gradient: gradient)))
        : DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
            child: Center(
              child: Icon(Icons.work_outline_rounded, size: 64, color: Colors.white.withValues(alpha: 0.92)),
            ),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        poster,
        // Legibility scrim for overlaid text.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black26, Colors.transparent, Colors.black45],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        // Top overlays: match strength + sandbox.
        Positioned(
          top: AppTokens.space12,
          left: AppTokens.space12,
          right: AppTokens.space12,
          child: Row(
            children: [
              if (card.score >= 0.7) const Pill('Top match', icon: Icons.local_fire_department_rounded, tone: PillTone.brand),
              const Spacer(),
              if (card.hasSandbox) const Pill('48h try-out', icon: Icons.bolt_rounded, tone: PillTone.info),
            ],
          ),
        ),
        // Video affordance / role caption.
        if (card.hasVideo)
          Center(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                key: const Key('watch'),
                customBorder: const CircleBorder(),
                onTap: onWatch,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(Icons.play_arrow_rounded, size: 34, color: scheme.primary),
                ),
              ),
            ),
          ),
        Positioned(
          left: AppTokens.space16,
          bottom: AppTokens.space12,
          child: Text(
            card.hasVideo ? 'Day in the life · tap to watch' : (card.roleFunction ?? card.industry ?? 'Internship'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.card, required this.fit, this.ghost, this.mentorship});
  final DeckCandidate card;
  final double fit;
  final CompanyGhostStats? ghost;
  final CompanyMentorship? mentorship;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = <Widget>[
      if ((card.location ?? '').isNotEmpty) Pill(card.location!, icon: Icons.place_outlined),
      if ((card.remoteMode ?? '').isNotEmpty) Pill(card.remoteMode!, icon: Icons.laptop_mac_rounded),
      if (card.salaryMin != null)
        Pill('\$${card.salaryMin}–${card.salaryMax}/mo', icon: Icons.payments_outlined, tone: PillTone.success),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            card.companyName.isNotEmpty ? card.companyName.characters.first.toUpperCase() : '?',
                            style: text.labelSmall?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(card.companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              FitRing(value: fit, size: 54, caption: 'fit'),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: AppTokens.space12),
            Wrap(spacing: AppTokens.space8, runSpacing: AppTokens.space8, children: meta),
          ],
          const SizedBox(height: AppTokens.space12),
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text('Why this grows you',
                  style: text.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(card.growthText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: scheme.onSurface, height: 1.45)),
          const Spacer(),
          Wrap(
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(label: Text('${card.matchedSkills}/${card.requiredSkills} skills')),
              if (ghost != null) GhostBadge(ghostRate: ghost!.ghostRate, totalMatches: ghost!.totalMatches),
              if (mentorship != null)
                MentorshipBadge(score: mentorship!.mentorshipScore, reviewCount: mentorship!.reviewCount),
            ],
          ),
        ],
      ),
    );
  }
}

/// Secondary controls. These remain [IconButton]s (keys pass/apply/undo) so
/// assistive tech and tests can drive the deck without a drag.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.canApply,
    required this.onPass,
    required this.onApply,
    required this.onUndo,
  });

  final bool canApply;
  final VoidCallback onPass;
  final VoidCallback? onApply;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          key: const Key('undo'),
          onPressed: onUndo,
          tooltip: 'Undo last swipe',
          icon: const Icon(Icons.replay_rounded),
          iconSize: 24,
          style: IconButton.styleFrom(
            backgroundColor: AppTokens.warningContainer,
            foregroundColor: AppTokens.warning,
            fixedSize: const Size(52, 52),
          ),
        ),
        IconButton(
          key: const Key('pass'),
          onPressed: onPass,
          tooltip: 'Pass',
          icon: const Icon(Icons.close_rounded),
          iconSize: 34,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: AppTokens.swipeNope,
            side: BorderSide(color: AppTokens.swipeNope.withValues(alpha: 0.5), width: 1.5),
            fixedSize: const Size(66, 66),
          ),
        ),
        IconButton(
          key: const Key('apply'),
          onPressed: onApply,
          tooltip: 'Apply',
          icon: const Icon(Icons.favorite_rounded),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: AppTokens.swipeLike,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            fixedSize: const Size(66, 66),
          ),
        ),
      ],
    );
  }
}

class _EmptyDeck extends ConsumerWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 56, showWordmark: false),
            const SizedBox(height: AppTokens.space20),
            Text("You're all caught up",
                style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space8),
            Text("You've seen everything for now.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space20),
            FilledButton.icon(
              onPressed: () => ref.invalidate(deckProvider),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Broaden filters'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(deckRepositoryProvider).undoLast();
                ref.invalidate(deckProvider);
              },
              child: const Text('Undo last swipe'),
            ),
          ],
        ),
      ),
    );
  }
}
