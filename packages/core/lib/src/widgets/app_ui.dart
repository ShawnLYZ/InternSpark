import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

/// Shared, theme-aware UI primitives used across both apps. Keeping these in
/// core means the student and employer/university surfaces speak one visual
/// language (Reuse Register): one fit ring, one brand mark, one pill, one
/// stat tile, one section header.

// ── Brand mark ─────────────────────────────────────────────────────────────

/// The InternSpark lockup: a gradient spark glyph, optionally with the
/// wordmark. Gradient derives from the active theme so it reads rose on mobile
/// and navy→sky on web.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 40,
    this.showWordmark = true,
    this.wordmark = 'InternSpark',
  });

  final double size;
  final bool showWordmark;
  final String wordmark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glyph = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: AppTokens.shadowSm(scheme.primary),
      ),
      child: Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.62),
    );
    if (!showWordmark) return glyph;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(width: AppTokens.space12),
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
            children: [
              TextSpan(text: 'Intern', style: TextStyle(color: scheme.onSurface)),
              TextSpan(text: 'Spark', style: TextStyle(color: scheme.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Fit ring ─────────────────────────────────────────────────────────────────

/// A compact circular gauge for a 0–1 score (skills matched / fit). Colour
/// bands read intuitively: green = strong, blue = good, amber = partial,
/// rose = weak. Not colour-only — always shows the number.
class FitRing extends StatelessWidget {
  const FitRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.caption,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final String? caption;

  static Color bandColor(double v) {
    if (v >= 0.75) return AppTokens.success;
    if (v >= 0.5) return AppTokens.info;
    if (v >= 0.25) return AppTokens.warning;
    return AppTokens.danger;
  }

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final color = bandColor(v);
    final pct = (v * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.16),
                ),
              ),
              Text(
                '$pct%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppTokens.space4),
          Text(
            caption!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

// ── Pill ─────────────────────────────────────────────────────────────────────

enum PillTone { neutral, brand, success, warning, danger, info }

/// A lightweight tinted label (icon + text) for inline metadata — location,
/// remote mode, salary, status. Lighter than a [Chip]; use [Chip] where the
/// element is interactive/selectable.
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.icon, this.tone = PillTone.neutral});

  final String label;
  final IconData? icon;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      PillTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      PillTone.brand => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PillTone.success => (AppTokens.successContainer, AppTokens.onSuccessContainer),
      PillTone.warning => (AppTokens.warningContainer, AppTokens.onWarningContainer),
      PillTone.danger => (AppTokens.dangerContainer, AppTokens.onDangerContainer),
      PillTone.info => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

/// A titled section divider with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.icon, this.trailing});

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: AppTokens.space8),
          ],
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Stat tile ────────────────────────────────────────────────────────────────

/// A metric tile (value + label + icon) for dashboards and headers.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = PillTone.brand,
  });

  final String value;
  final String label;
  final IconData? icon;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (accentBg, accentFg) = switch (tone) {
      PillTone.success => (AppTokens.successContainer, AppTokens.success),
      PillTone.warning => (AppTokens.warningContainer, AppTokens.warning),
      PillTone.danger => (AppTokens.dangerContainer, AppTokens.danger),
      PillTone.info || PillTone.brand => (scheme.tertiaryContainer, scheme.tertiary),
      PillTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusSm),
              ),
              child: Icon(icon, size: 18, color: accentFg),
            ),
            const SizedBox(height: AppTokens.space12),
          ],
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
