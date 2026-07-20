import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('shows the score with a review count', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MentorshipBadge(score: 4.3, reviewCount: 7)),
    ));
    expect(find.text('4.3 mentorship (7)'), findsOneWidget);
  });

  testWidgets('falls back to "No reviews" at zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: MentorshipBadge(score: 0, reviewCount: 0)),
    ));
    expect(find.text('No reviews'), findsOneWidget);
  });
}
