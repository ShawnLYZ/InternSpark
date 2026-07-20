import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';

void main() {
  testWidgets('AppLoading shows a spinner', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppLoading())));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppError shows the message and retries', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AppError(message: 'Network down', onRetry: () => retried = true)),
    ));
    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('AppEmpty shows the message + optional action', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AppEmpty(message: 'Nothing here', actionLabel: 'Broaden', onAction: () {})),
    ));
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Broaden'), findsOneWidget);
  });
}
