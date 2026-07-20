import 'package:flutter/material.dart';

/// Shared primitive design tokens for both InternSpark skins.
///
/// The two apps share **one** system for spacing, radii and motion, but carry
/// deliberately different palettes and type: a warm, high-energy *playful* skin
/// for the student mobile app (rose + engagement-blue) and a cool, restrained
/// *professional* skin for the employer/university web app (navy + sky-blue).
///
/// Palettes are sourced from the product's design intelligence pass:
///   • mobile  → "Vibrant & block-based", rose #E11D48 + blue #2563EB
///   • web     → "Trust & authority",     navy #0F172A + blue #0369A1
abstract final class AppTokens {
  // ── Brand seeds (kept for backward-compat with existing callers) ───────────
  /// Playful student-mobile seed (vibrant rose).
  static const Color playfulSeed = Color(0xFFE11D48);

  /// Professional web seed (restrained navy).
  static const Color professionalSeed = Color(0xFF0F172A);

  // ── Playful (mobile) palette ───────────────────────────────────────────────
  static const Color playfulPrimary = Color(0xFFE11D48); // rose 600
  static const Color playfulPrimaryPressed = Color(0xFFBE123C); // rose 700
  static const Color playfulPrimaryContainer = Color(0xFFFFE4E9); // rose 100
  static const Color playfulOnPrimaryContainer = Color(0xFF881337); // rose 900
  static const Color playfulAccent = Color(0xFF2563EB); // engagement blue
  static const Color playfulAccentContainer = Color(0xFFDBE7FF);
  static const Color playfulOnAccentContainer = Color(0xFF162B63);
  static const Color playfulSurface = Color(0xFFFFFFFF);
  static const Color playfulSurfaceMuted = Color(0xFFFFF1F2); // rose-tinted page bg
  static const Color playfulSurfaceContainer = Color(0xFFFFF5F6);
  static const Color playfulOutline = Color(0xFFF6CCD5);
  static const Color playfulOutlineVariant = Color(0xFFFBDDE3);
  static const Color playfulInk = Color(0xFF3B0D19); // warm near-black text
  static const Color playfulInkMuted = Color(0xFF8F5A68);

  // ── Professional (web) palette ─────────────────────────────────────────────
  static const Color proPrimary = Color(0xFF0F172A); // slate 900 (navy)
  static const Color proPrimaryHover = Color(0xFF1E293B); // slate 800
  static const Color proPrimaryContainer = Color(0xFFE2E8F0);
  static const Color proOnPrimaryContainer = Color(0xFF0F172A);
  static const Color proAccent = Color(0xFF0369A1); // sky 700 (CTA)
  static const Color proAccentHover = Color(0xFF075985); // sky 800
  static const Color proAccentContainer = Color(0xFFE0F2FE);
  static const Color proOnAccentContainer = Color(0xFF0C4A6E);
  static const Color proSurface = Color(0xFFFFFFFF);
  static const Color proSurfaceMuted = Color(0xFFF8FAFC); // slate 50 page bg
  static const Color proSurfaceContainer = Color(0xFFF1F5F9); // slate 100
  static const Color proOutline = Color(0xFFE2E8F0); // slate 200
  static const Color proOutlineStrong = Color(0xFFCBD5E1); // slate 300
  static const Color proInk = Color(0xFF0F172A); // slate 900
  static const Color proInkMuted = Color(0xFF64748B); // slate 500

  // ── Semantic (shared across skins) ─────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF14532D);
  static const Color warning = Color(0xFFD97706);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);
  static const Color danger = Color(0xFFDC2626);
  static const Color onDanger = Color(0xFFFFFFFF);
  static const Color dangerContainer = Color(0xFFFEE2E2);
  static const Color onDangerContainer = Color(0xFF7F1D1D);
  static const Color info = Color(0xFF2563EB);

  /// Swipe affordance accents (shared by the one SwipeCard).
  static const Color swipeLike = Color(0xFF16A34A); // right = apply / match
  static const Color swipeNope = Color(0xFFE11D48); // left = pass / reject
  static const Color swipeSuper = Color(0xFF2563EB); // up = super / details

  // ── Spacing scale (4-pt base) ──────────────────────────────────────────────
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;
  static const double space64 = 64;

  /// Legacy aliases — existing screens use these names widely; keep them.
  static const double spaceSm = space8;
  static const double spaceMd = space16;
  static const double spaceLg = space24;

  // ── Radii ──────────────────────────────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusFull = 999;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(radiusXl));

  // ── Elevation (soft, optionally brand-tinted shadows) ──────────────────────
  static List<BoxShadow> shadowSm([Color tint = const Color(0xFF0F172A)]) => [
        BoxShadow(color: tint.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
      ];

  static List<BoxShadow> shadowMd([Color tint = const Color(0xFF0F172A)]) => [
        BoxShadow(color: tint.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
        BoxShadow(color: tint.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> shadowLg([Color tint = const Color(0xFF0F172A)]) => [
        BoxShadow(color: tint.withValues(alpha: 0.16), blurRadius: 40, offset: const Offset(0, 18)),
        BoxShadow(color: tint.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
      ];

  // ── Motion ─────────────────────────────────────────────────────────────────
  static const Duration durInstant = Duration(milliseconds: 100);
  static const Duration durFast = Duration(milliseconds: 160);
  static const Duration durBase = Duration(milliseconds: 240);
  static const Duration durSlow = Duration(milliseconds: 360);

  static const Curve curveEnter = Curves.easeOutCubic; // entering
  static const Curve curveExit = Curves.easeInCubic; // leaving (shorter)
  static const Curve curveEmphasis = Cubic(0.2, 0.0, 0.0, 1.0); // M3 emphasized
  static const Curve curveSpring = Curves.easeOutBack; // playful pop

  // ── Layout ─────────────────────────────────────────────────────────────────
  /// Comfortable reading/column width for the web app's content regions.
  static const double contentMaxWidth = 1120;
  static const double formMaxWidth = 460;
  static const double railWidth = 264;
}
