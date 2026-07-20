import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internspark_core/internspark_core.dart';
import 'package:internspark_core/testing.dart';
import 'package:app_web/src/chat_screen.dart';

void main() {
  testWidgets('streams live messages and sends', (tester) async {
    final fake = FakeChatRepository(threads: const []);
    const thread = ChatThread(threadId: 't1', studentName: 'Sam Rivera', companyName: 'Nimbus', universityName: 'Springfield');

    await tester.pumpWidget(ProviderScope(
      overrides: [chatRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: ChatThreadView(thread: thread)),
    ));
    await tester.pumpAndSettle();

    // A live message arrives over the (faked) Realtime stream.
    fake.emit(const ChatMessage(id: 'm1', threadId: 't1', senderProfileId: 'u1', body: 'Welcome aboard'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome aboard'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Thanks!');
    await tester.tap(find.byKey(const Key('send')));
    await tester.pumpAndSettle();
    expect(fake.sent, ['Thanks!']);
  });
}
