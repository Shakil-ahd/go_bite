import 'package:flutter_test/flutter_test.dart';

import 'package:go_bite/main.dart';
import 'package:go_bite/core/network/web_socket_service.dart';

class FakeWebSocketService extends WebSocketService {
  FakeWebSocketService() : super(url: 'ws://mock');

  @override
  void connect() {}

  @override
  void send(String eventName, Map<String, dynamic> data) {}

  @override
  void dispose() {}
}

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final fakeWs = FakeWebSocketService();

    await tester.pumpWidget(GoBiteApp(webSocketService: fakeWs));

    expect(find.text('GoBite'), findsOneWidget);
    expect(find.text('Join Session'), findsOneWidget);
  });
}
