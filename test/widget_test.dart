// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:go_bite/main.dart';
import 'package:go_bite/core/network/web_socket_service.dart';

class FakeWebSocketService extends WebSocketService {
  FakeWebSocketService() : super(url: 'ws://mock');

  @override
  void connect() {
    // No-op for tests to prevent hanging network timers
  }

  @override
  void send(String eventName, Map<String, dynamic> data) {
    // No-op
  }

  @override
  void dispose() {
    // No-op
  }
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final fakeWs = FakeWebSocketService();
    // Build our app and trigger a frame.
    await tester.pumpWidget(GoBiteApp(webSocketService: fakeWs));

    // Verify that our entry screen loads with the brand title.
    expect(find.text('GoBite'), findsOneWidget);
    expect(find.text('Join Session'), findsOneWidget);
  });
}
