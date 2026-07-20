import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  AssetImage badgeOf(WidgetTester tester) =>
      tester.widget<Image>(find.byType(Image)).image as AssetImage;

  testWidgets('draws the shipped brand artwork, not an icon glyph', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandMark(showWordmark: false)),
    ));

    final badge = badgeOf(tester);
    expect(badge.assetName, 'assets/branding/internspark_icon.png');
    // Must be package-qualified, or consuming apps resolve nothing.
    expect(badge.package, 'internspark_core');
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('badge fills the requested size in both skins', (tester) async {
    for (final theme in [AppThemes.playfulMobile, AppThemes.professionalWeb]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: BrandMark(size: 44, showWordmark: false)),
      ));
      expect(tester.getSize(find.byType(Image)), const Size(44, 44));
      expect(badgeOf(tester).assetName, 'assets/branding/internspark_icon.png');
    }
  });

  testWidgets('badge is decorative only when the wordmark speaks for it', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandMark(showWordmark: false)),
    ));
    expect(find.bySemanticsLabel('InternSpark'), findsOneWidget);

    // Wordmark shown: the badge must not announce the name a second time.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandMark()),
    ));
    expect(tester.widget<Image>(find.byType(Image)).excludeFromSemantics, isTrue);
  });

  testWidgets('wordmark is opt-out', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandMark()),
    ));
    expect(find.byType(RichText), findsWidgets);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandMark(showWordmark: false)),
    ));
    expect(find.byType(Image), findsOneWidget);
  });
}
