import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:app_mobile/src/login_screen.dart';
import 'package:app_mobile/src/signup_screen.dart';

void main() {
  Widget host(FakeAuthRepository auth, {Widget home = const SignupScreen()}) => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: MaterialApp(home: home),
      );

  Future<void> fill(WidgetTester tester,
      {String name = 'Aisyah Tan',
      String email = 'aisyah@uni.edu',
      String password = 'Sup3r!secret',
      String? confirm}) async {
    await tester.enterText(find.byKey(const Key('full-name')), name);
    await tester.enterText(find.byKey(const Key('email')), email);
    await tester.enterText(find.byKey(const Key('password')), password);
    await tester.enterText(find.byKey(const Key('confirm-password')), confirm ?? password);
  }

  testWidgets('mismatched passwords block the submit with an inline error', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(host(auth));
    await fill(tester, confirm: 'different');
    await tester.tap(find.byKey(const Key('create-account')));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.signUps, isEmpty);
  });

  testWidgets('a valid form signs up with student role metadata inputs', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(host(auth));
    await fill(tester);
    await tester.tap(find.byKey(const Key('create-account')));
    await tester.pumpAndSettle();

    expect(auth.signUps, [('aisyah@uni.edu', 'Sup3r!secret', 'Aisyah Tan')]);
  });

  testWidgets('a duplicate email surfaces the server message', (tester) async {
    final auth = FakeAuthRepository()..signUpError = const AuthException('User already registered');
    await tester.pumpWidget(host(auth));
    await fill(tester);
    await tester.tap(find.byKey(const Key('create-account')));
    await tester.pumpAndSettle();

    expect(find.text('User already registered'), findsOneWidget);
  });

  testWidgets('the login screen links to Create account', (tester) async {
    final auth = FakeAuthRepository();
    addTearDown(tester.view.resetPhysicalSize);
    tester.view.physicalSize = const Size(1200, 2400);
    await tester.pumpWidget(host(auth, home: const LoginScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is TextButton &&
        widget.child is Text &&
        (widget.child as Text).data == 'Create account'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
  });
}
