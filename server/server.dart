import 'dart:io';

void main() async {
  // Bind to port 8080 on all local interfaces
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('🚀 GoBite WebSocket Server running on ws://localhost:8080');

  // Keep track of connected clients
  final Set<WebSocket> clients = {};

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket ws = await WebSocketTransformer.upgrade(request);
      clients.add(ws);
      print('🟢 Client connected! Total connections: ${clients.length}');

      ws.listen(
        (data) {
          print('📨 Received message: $data');
          
          // Broadcast to all other connected clients
          for (var client in clients) {
            if (client != ws && client.readyState == WebSocket.open) {
              client.add(data);
            }
          }
        },
        onDone: () {
          clients.remove(ws);
          print('🔴 Client disconnected. Total connections: ${clients.length}');
        },
        onError: (error) {
          clients.remove(ws);
          print('⚠️ Client error: $error. Total connections: ${clients.length}');
        },
      );
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('GoBite WebSocket Server is running. Upgrade to WebSocket to connect.')
        ..close();
    }
  }
}
