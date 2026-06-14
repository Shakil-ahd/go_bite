import 'dart:io';
import 'dart:convert';

// ─── Client Types ───
enum ClientType { customer, restaurant, rider, unknown }

class ConnectedClient {
  final WebSocket ws;
  ClientType type;
  String? orderId; // For rider: which order they are handling

  ConnectedClient(this.ws, {this.type = ClientType.unknown, this.orderId});
}

void main() async {
  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('🚀 GoBite Smart Server running on port $port');
  print('   ├── Customer App:    ws://localhost:8080');
  print('   ├── Restaurant App:  ws://localhost:8080');
  print('   └── Rider App:       ws://localhost:8080');

  final List<ConnectedClient> clients = [];

  // In-memory order store
  final Map<String, Map<String, dynamic>> orders = {};

  // In-memory rider ratings store
  // Format: { 'riderName': { 'totalRatings': 0, 'totalScore': 0.0, 'totalDeliveries': 0 } }
  final Map<String, Map<String, dynamic>> riderRatings = {};

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final ws = await WebSocketTransformer.upgrade(request);
      final client = ConnectedClient(ws);
      clients.add(client);

      print('🟢 New connection. Total: ${clients.length}');

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as Map<String, dynamic>;
            final event = message['event'] as String?;
            final msgData = message['data'] as Map<String, dynamic>?;
            final timestamp = message['timestamp'] as String?;

            if (event == null || msgData == null) return;

            print('📨 [$event] from ${client.type.name}');

            switch (event) {

              // ─── Client registration ───
              case 'register':
                final type = msgData['type'] as String?;
                client.type = _parseType(type);
                print('   ✅ Registered as: ${client.type.name}');

                // Send pending orders to restaurant when it connects
                if (client.type == ClientType.restaurant) {
                  for (final order in orders.values) {
                    final status = order['status'] as String?;
                    if (status == 'pending') {
                      _sendToClient(ws, 'new_order', order);
                    }
                  }
                }

                // Send ready-for-pickup orders to rider when it connects
                if (client.type == ClientType.rider) {
                  for (final order in orders.values) {
                    final status = order['status'] as String?;
                    if (status == 'readyForPickup') {
                      _sendToClient(ws, 'order_ready_for_pickup', order);
                    }
                  }
                }
                break;

              // ─── Customer places new order ───
              case 'new_order':
                final orderId = msgData['id'] as String?;
                if (orderId != null) {
                  orders[orderId] = msgData;
                  print('   📋 Order stored: $orderId');

                  // Broadcast to all restaurant apps
                  _broadcastToType(clients, ClientType.restaurant, 'new_order', msgData, exclude: ws);
                }
                break;

              // ─── Restaurant or Rider updates order status ───
              case 'order_status_updated':
                final orderId = msgData['id'] as String?;
                final newStatus = msgData['status'] as String?;
                if (orderId != null) {
                  orders[orderId] = msgData; // Update stored order
                  print('   🔄 Order $orderId → $newStatus');

                  // Broadcast to everyone (excluding sender) so all apps stay in sync
                  _broadcastAll(clients, 'order_status_updated', msgData, exclude: ws);

                  // If ready for pickup, also notify riders with a specific event
                  if (newStatus == 'readyForPickup') {
                    _broadcastToType(clients, ClientType.rider, 'order_ready_for_pickup', msgData);
                  }

                  // If delivered/rejected, clean up after delay
                  if (newStatus == 'delivered' || newStatus == 'rejected') {
                    if (newStatus == 'delivered') {
                      final riderName = msgData['riderName'] as String?;
                      if (riderName != null) {
                        riderRatings.putIfAbsent(riderName, () => {'totalRatings': 0, 'totalScore': 0.0, 'totalDeliveries': 0});
                        riderRatings[riderName]!['totalDeliveries'] = (riderRatings[riderName]!['totalDeliveries'] as int) + 1;
                        
                        // Broadcast updated stats
                        final statsData = {
                          'riderName': riderName,
                          'totalDeliveries': riderRatings[riderName]!['totalDeliveries'],
                          'averageRating': (riderRatings[riderName]!['totalRatings'] as int) > 0 
                              ? (riderRatings[riderName]!['totalScore'] as double) / (riderRatings[riderName]!['totalRatings'] as int)
                              : 0.0,
                          'totalRatings': riderRatings[riderName]!['totalRatings']
                        };
                        _broadcastAll(clients, 'rider_stats_updated', statsData, exclude: ws);
                      }
                    }

                    Future.delayed(const Duration(seconds: 30), () {
                      orders.remove(orderId);
                    });
                  }
                }
                break;

              // ─── Rider sends location update ───
              case 'rider_location_updated':
                // Only broadcast to customers (not to restaurants or other riders)
                _broadcastToType(clients, ClientType.customer, 'rider_location_updated', msgData, exclude: ws);
                break;

              // ─── Rider accepts a delivery ───
              case 'rider_accepted_order':
                final orderId = msgData['orderId'] as String?;
                if (orderId != null) {
                  client.orderId = orderId;
                  final order = orders[orderId];
                  if (order != null) {
                    final updated = {...order, 'riderName': msgData['riderName']};
                    // Do NOT change status yet. Restaurant must confirm hand-over.
                    orders[orderId] = updated;
                    _broadcastToType(clients, ClientType.customer, 'order_status_updated', updated, exclude: ws);
                    _broadcastToType(clients, ClientType.restaurant, 'order_status_updated', updated, exclude: ws);
                    _broadcastToType(clients, ClientType.rider, 'order_status_updated', updated, exclude: ws);
                  }
                }
                break;

              // ─── Rate Rider ───
              case 'rate_rider':
                final riderName = msgData['riderName'] as String?;
                final rating = msgData['rating'] as num?;
                if (riderName != null && rating != null) {
                  riderRatings.putIfAbsent(riderName, () => {'totalRatings': 0, 'totalScore': 0.0, 'totalDeliveries': 0});
                  
                  riderRatings[riderName]!['totalRatings'] = (riderRatings[riderName]!['totalRatings'] as int) + 1;
                  riderRatings[riderName]!['totalScore'] = (riderRatings[riderName]!['totalScore'] as double) + rating.toDouble();
                  
                  final avg = (riderRatings[riderName]!['totalScore'] as double) / (riderRatings[riderName]!['totalRatings'] as int);
                  
                  final statsData = {
                    'riderName': riderName,
                    'averageRating': avg,
                    'totalRatings': riderRatings[riderName]!['totalRatings'],
                    'totalDeliveries': riderRatings[riderName]!['totalDeliveries']
                  };
                  print('   ⭐ Rider $riderName rated $rating. New avg: $avg');
                  _broadcastAll(clients, 'rider_stats_updated', statsData, exclude: ws);
                }
                break;

              // ─── Ping / heartbeat ───
              case 'ping':
                _sendToClient(ws, 'pong', {'time': DateTime.now().toIso8601String()});
                break;

              default:
                // Generic broadcast (fallback for unknown events)
                _broadcastAll(clients, event, msgData, timestamp: timestamp, exclude: ws);
            }
          } catch (e) {
            print('⚠️ Parse error: $e');
          }
        },
        onDone: () {
          clients.remove(client);
          print('🔴 Client disconnected (${client.type.name}). Total: ${clients.length}');
        },
        onError: (error) {
          clients.remove(client);
          print('⚠️ Client error (${client.type.name}): $error');
        },
      );
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..headers.add('Content-Type', 'text/html; charset=utf-8')
        ..write('''
          <html><body style="font-family:sans-serif;padding:40px;background:#1a1a2e;color:#eee">
          <h1>🍔 GoBite WebSocket Server</h1>
          <p style="color:#4ade80">✅ Server is running on port 8080</p>
          <h3>Connected Clients: ${clients.length}</h3>
          <ul>
            <li>Customers: ${clients.where((c) => c.type == ClientType.customer).length}</li>
            <li>Restaurants: ${clients.where((c) => c.type == ClientType.restaurant).length}</li>
            <li>Riders: ${clients.where((c) => c.type == ClientType.rider).length}</li>
          </ul>
          <h3>Active Orders: ${orders.length}</h3>
          </body></html>
        ''')
        ..close();
    }
  }
}

ClientType _parseType(String? type) {
  switch (type) {
    case 'customer': return ClientType.customer;
    case 'restaurant': return ClientType.restaurant;
    case 'rider': return ClientType.rider;
    default: return ClientType.unknown;
  }
}

void _sendToClient(WebSocket ws, String event, Map<String, dynamic> data) {
  try {
    if (ws.readyState == WebSocket.open) {
      ws.add(jsonEncode({
        'event': event,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }));
    }
  } catch (e) {
    print('⚠️ Send error: $e');
  }
}

void _broadcastToType(
  List<ConnectedClient> clients,
  ClientType type,
  String event,
  Map<String, dynamic> data, {
  WebSocket? exclude,
}) {
  int count = 0;
  for (final client in clients) {
    if (client.type == type && client.ws != exclude) {
      _sendToClient(client.ws, event, data);
      count++;
    }
  }
  print('   📡 Sent [$event] to $count ${type.name}(s)');
}

void _broadcastAll(
  List<ConnectedClient> clients,
  String event,
  Map<String, dynamic> data, {
  String? timestamp,
  WebSocket? exclude,
}) {
  for (final client in clients) {
    if (client.ws != exclude && client.ws.readyState == WebSocket.open) {
      _sendToClient(client.ws, event, data);
    }
  }
}
