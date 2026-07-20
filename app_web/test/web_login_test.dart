import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:app_web/main.dart';

void main() {
  testWidgets('signed-out shows the Employer/University toggle on login', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [currentProfileProvider.overrideWith((ref) async => null)],
      child: const InternSparkWebApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Employer'), findsOneWidget);
    expect(find.text('University'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
