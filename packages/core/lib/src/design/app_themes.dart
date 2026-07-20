import 'package:flutter/material.dart';
import 'app_tokens.dart';

/// Builds the two Material 3 skins from shared [AppTokens].
///
/// Both skins run through one [_skin] builder so the component language
/// (buttons, inputs, chips, cards, nav) stays consistent while the palette,
/// type and density diverge:
///   • [playfulMobile]    — warm rose + engagement blue, Space Grotesk, pill
///     buttons, comfortable density. For the student app.
///   • [professionalWeb]  — navy + sky blue, Plus Jakarta Sans, crisp corners,
///     compact density. For the employer/university app.
abstract final class AppThemes {
  static const _mobileFont = 'packages/internspark_core/SpaceGrotesk';
  static const _webFont = 'packages/internspark_core/PlusJakartaSans';

  // ── Public skins ────────────────────────────────────────────────────────────

  /// Playful skin for the student mobile app.
  static ThemeData get playfulMobile => _skin(
        scheme: _playfulScheme,
        text: _spaceGroteskText,
        fontFamily: _mobileFont,
        playful: true,
      );

  /// Professional skin for the employer/university web app.
  static ThemeData get professionalWeb => _skin(
        scheme: _professionalScheme,
        text: _jakartaText,
        fontFamily: _webFont,
        playful: false,
      );

  // ── Color schemes ────────────────────────────────────────────────────────────

  static final ColorScheme _playfulScheme = ColorScheme.fromSeed(
    seedColor: AppTokens.playfulPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppTokens.playfulPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppTokens.playfulPrimaryContainer,
    onPrimaryContainer: AppTokens.playfulOnPrimaryContainer,
    secondary: const Color(0xFFB03651),
    onSecondary: Colors.white,
    secondaryContainer: AppTokens.playfulPrimaryContainer,
    onSecondaryContainer: AppTokens.playfulOnPrimaryContainer,
    tertiary: AppTokens.playfulAccent,
    onTertiary: Colors.white,
    tertiaryContainer: AppTokens.playfulAccentContainer,
    onTertiaryContainer: AppTokens.playfulOnAccentContainer,
    error: AppTokens.danger,
    onError: AppTokens.onDanger,
    errorContainer: AppTokens.dangerContainer,
    onErrorContainer: AppTokens.onDangerContainer,
    surface: AppTokens.playfulSurface,
    onSurface: AppTokens.playfulInk,
    onSurfaceVariant: AppTokens.playfulInkMuted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppTokens.playfulSurfaceContainer,
    surfaceContainer: AppTokens.playfulSurfaceContainer,
    surfaceContainerHigh: const Color(0xFFFFEAEE),
    surfaceContainerHighest: const Color(0xFFFCE2E7),
    outline: AppTokens.playfulOutline,
    outlineVariant: AppTokens.playfulOutlineVariant,
  );

  static final ColorScheme _professionalScheme = ColorScheme.fromSeed(
    seedColor: AppTokens.proAccent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppTokens.proPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppTokens.proPrimaryContainer,
    onPrimaryContainer: AppTokens.proOnPrimaryContainer,
    secondary: const Color(0xFF475569),
    onSecondary: Colors.white,
    secondaryContainer: AppTokens.proSurfaceContainer,
    onSecondaryContainer: AppTokens.proInk,
    tertiary: AppTokens.proAccent,
    onTertiary: Colors.white,
    tertiaryContainer: AppTokens.proAccentContainer,
    onTertiaryContainer: AppTokens.proOnAccentContainer,
    error: AppTokens.danger,
    onError: AppTokens.onDanger,
    errorContainer: AppTokens.dangerContainer,
    onErrorContainer: AppTokens.onDangerContainer,
    surface: AppTokens.proSurface,
    onSurface: AppTokens.proInk,
    onSurfaceVariant: AppTokens.proInkMuted,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppTokens.proSurfaceMuted,
    surfaceContainer: AppTokens.proSurfaceContainer,
    surfaceContainerHigh: const Color(0xFFEAEFF5),
    surfaceContainerHighest: const Color(0xFFE2E8F0),
    outline: AppTokens.proOutline,
    outlineVariant: const Color(0xFFEEF2F6),
  );

  // ── Type scales (family + colour applied by [_skin]) ─────────────────────────

  static TextStyle _t(double size, FontWeight weight, double height, double spacing) =>
      TextStyle(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing);

  /// Space Grotesk — geometric, bold, high-personality. Big, punchy headings.
  static final TextTheme _spaceGroteskText = TextTheme(
    displayLarge: _t(40, FontWeight.w700, 1.04, -0.5),
    displayMedium: _t(32, FontWeight.w700, 1.08, -0.4),
    displaySmall: _t(28, FontWeight.w700, 1.12, -0.3),
    headlineLarge: _t(26, FontWeight.w700, 1.15, -0.3),
    headlineMedium: _t(22, FontWeight.w700, 1.2, -0.2),
    headlineSmall: _t(20, FontWeight.w600, 1.25, -0.1),
    titleLarge: _t(18, FontWeight.w600, 1.3, 0),
    titleMedium: _t(16, FontWeight.w600, 1.35, 0.1),
    titleSmall: _t(14, FontWeight.w600, 1.4, 0.1),
    bodyLarge: _t(16, FontWeight.w400, 1.5, 0.1),
    bodyMedium: _t(14, FontWeight.w400, 1.5, 0.1),
    bodySmall: _t(12.5, FontWeight.w400, 1.45, 0.2),
    labelLarge: _t(15, FontWeight.w600, 1.2, 0.2),
    labelMedium: _t(13, FontWeight.w600, 1.2, 0.3),
    labelSmall: _t(11.5, FontWeight.w600, 1.2, 0.4),
  );

  /// Plus Jakarta Sans — legible, approachable, enterprise-clean. Tighter scale.
  static final TextTheme _jakartaText = TextTheme(
    displayLarge: _t(36, FontWeight.w800, 1.1, -0.5),
    displayMedium: _t(30, FontWeight.w700, 1.12, -0.4),
    displaySmall: _t(26, FontWeight.w700, 1.15, -0.3),
    headlineLarge: _t(24, FontWeight.w700, 1.2, -0.2),
    headlineMedium: _t(20, FontWeight.w700, 1.25, -0.1),
    headlineSmall: _t(18, FontWeight.w700, 1.3, 0),
    titleLarge: _t(17, FontWeight.w600, 1.3, 0),
    titleMedium: _t(15, FontWeight.w600, 1.35, 0.05),
    titleSmall: _t(13.5, FontWeight.w600, 1.4, 0.1),
    bodyLarge: _t(15.5, FontWeight.w400, 1.55, 0.1),
    bodyMedium: _t(14, FontWeight.w400, 1.5, 0.1),
    bodySmall: _t(12.5, FontWeight.w400, 1.45, 0.15),
    labelLarge: _t(14, FontWeight.w600, 1.2, 0.2),
    labelMedium: _t(12.5, FontWeight.w600, 1.2, 0.3),
    labelSmall: _t(11, FontWeight.w600, 1.2, 0.4),
  );

  // ── The shared skin builder ──────────────────────────────────────────────────

  static ThemeData _skin({
    required ColorScheme scheme,
    required TextTheme text,
    required String fontFamily,
    required bool playful,
  }) {
    final density = playful ? VisualDensity.comfortable : VisualDensity.compact;
    final scaffoldBg = playful ? AppTokens.playfulSurfaceMuted : AppTokens.proSurfaceMuted;
    final outline = scheme.outlineVariant;
    final controlRadius = BorderRadius.circular(playful ? AppTokens.radiusMd : AppTokens.radiusSm);
    final OutlinedBorder buttonShape = playful
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm + 2));
    final buttonPad = EdgeInsets.symmetric(
      horizontal: playful ? 22 : 18,
      vertical: playful ? 15 : 12,
    );
    final minButton = Size(64, playful ? 52 : 44);
    final controlFill = playful ? AppTokens.playfulSurfaceContainer : AppTokens.proSurfaceContainer;

    OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: density,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scheme.surface,
      splashFactory: playful ? InkSparkle.splashFactory : InkRipple.splashFactory,
      textTheme: text.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: playful ? scaffoldBg : scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: playful ? 0 : 0.6,
        shadowColor: scheme.shadow.withValues(alpha: 0.10),
        centerTitle: false,
        toolbarHeight: 60,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: 0.12),
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(playful ? AppTokens.radiusLg : AppTokens.radiusMd),
          side: BorderSide(color: outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.10),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shape: buttonShape,
          padding: buttonPad,
          minimumSize: minButton,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.primary,
          elevation: 0,
          shape: buttonShape.copyWith(side: BorderSide(color: scheme.outline)),
          padding: buttonPad,
          minimumSize: minButton,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          shape: buttonShape,
          padding: buttonPad,
          minimumSize: minButton,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: playful ? scheme.primary : scheme.tertiary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(48, 44),
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: playful ? scheme.primary : scheme.tertiary,
        foregroundColor: playful ? scheme.onPrimary : scheme.onTertiary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(playful ? AppTokens.radiusLg : AppTokens.radiusMd),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: controlFill,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: playful ? 16 : 14),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: inputBorder(Colors.transparent, 0),
        enabledBorder: inputBorder(outline, 1),
        focusedBorder: inputBorder(scheme.primary, 2),
        errorBorder: inputBorder(scheme.error, 1),
        focusedErrorBorder: inputBorder(scheme.error, 2),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: controlFill,
        selectedColor: playful ? scheme.tertiaryContainer : scheme.tertiaryContainer,
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        labelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        iconTheme: IconThemeData(size: 16, color: scheme.onSurfaceVariant),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: playful ? scheme.primaryContainer : scheme.tertiaryContainer,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? (playful ? scheme.onPrimaryContainer : scheme.onTertiaryContainer)
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.tertiaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onTertiaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        elevation: 0,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTokens.space16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(playful ? AppTokens.radiusLg : AppTokens.radiusMd),
        ),
        titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
        insetPadding: const EdgeInsets.all(AppTokens.space16),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        textStyle: text.labelSmall?.copyWith(color: scheme.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        thumbColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
