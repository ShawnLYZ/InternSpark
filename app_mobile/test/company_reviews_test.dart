import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_mobile/src/company_reviews_screen.dart';
import 'package:app_mobile/src/matches_screen.dart' show myApplicationsProvider;

void main() {
  testWidgets('reviews render as anonymous "Verified intern" with the mentorship score', (tester) async {
    final fake = FakeReviewRepository(reviews: const [
      Review(mentorship: 5, workload: 4, psychSafety: 5, comment: 'Real ownership and great mentors.'),
      Review(mentorship: 3, workload: 3, psychSafety: 4),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        reviewRepositoryProvider.overrideWithValue(fake),
        myApplicationsProvider.overrideWith((ref) async => const <Application>[]),
      ],
      child: const MaterialApp(home: CompanyReviewsScreen(companyId: 'c1', companyName: 'Nimbus')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Verified intern'), findsNWidgets(2));
    expect(find.text('4.0 mentorship (2)'), findsOneWidget); // mean(5,3)=4.0
  });
}
