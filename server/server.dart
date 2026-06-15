import 'dart:io';
import 'dart:convert';
import 'dart:math';

// ─── Client Types ───
enum ClientType { customer, restaurant, rider, unknown }

class ConnectedClient {
  final WebSocket ws;
  ClientType type;
  String? orderId; // For rider: which order they are handling

  ConnectedClient(this.ws, {this.type = ClientType.unknown, this.orderId});
}

// ─── Default Bangladeshi Food Catalog ───
const List<Map<String, dynamic>> _defaultCatalog = [
  {
    'id': 'food_01', 'name': 'Kacchi Biryani',
    'description': 'Authentic Dhaka-style Kacchi with tender goat meat, aromatic rice, potatoes & boiled eggs',
    'price': 350.0,
    'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
  },
  {
    'id': 'food_02', 'name': 'Chicken Biryani',
    'description': 'Fragrant basmati rice with juicy chicken pieces, saffron & special spices',
    'price': 280.0,
    'imageUrl': 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
  },
  {
    'id': 'food_03', 'name': 'Morog Polao',
    'description': 'Classic Bengali chicken polao with ghee-flavored rice & whole spices',
    'price': 300.0,
    'imageUrl': 'https://images.unsplash.com/photo-1596797038530-2c107229654b?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
  },
  {
    'id': 'food_04', 'name': 'Beef Tehari',
    'description': 'Spicy beef tehari with fragrant rice, potatoes & traditional Puran Dhaka spices',
    'price': 220.0,
    'imageUrl': 'https://images.unsplash.com/photo-1574653853027-5382a3d23a15?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
  },
  {
    'id': 'food_05', 'name': 'Khichuri + Dim Bhaji',
    'description': 'Comfort food: Dal khichuri served with egg omelette & mixed vegetable bhaji',
    'price': 150.0,
    'imageUrl': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
  },
  {
    'id': 'drink_01', 'name': 'Borhani',
    'description': 'Traditional Bangladeshi spicy yogurt drink, perfect with biryani',
    'price': 40.0,
    'imageUrl': 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?auto=format&fit=crop&w=400&q=80',
    'category': 'drinks',
  },
  {
    'id': 'drink_02', 'name': 'Mango Lassi',
    'description': 'Creamy mango yogurt smoothie made with fresh seasonal mangoes',
    'price': 60.0,
    'imageUrl': 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=400&q=80',
    'category': 'drinks',
  },
  {
    'id': 'snack_01', 'name': 'Fuchka (8 pcs)',
    'description': 'Crispy hollow shells filled with spicy tamarind water, chickpeas & potatoes',
    'price': 40.0,
    'imageUrl': 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=400&q=80',
    'category': 'snacks',
  },
  {
    'id': 'snack_02', 'name': 'Chotpoti',
    'description': 'Spicy chickpea curry topped with boiled egg, onion & tamarind sauce',
    'price': 50.0,
    'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80',
    'category': 'snacks',
  },
  {
    'id': 'med_01', 'name': 'Napa Extra',
    'description': 'Paracetamol 500mg + Caffeine 65mg — for headache, fever & body pain',
    'price': 12.0,
    'imageUrl': 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'category': 'medicine',
  },
  {
    'id': 'med_02', 'name': 'Seclo 20mg',
    'description': 'Omeprazole capsule for acidity, heartburn & gastric problems',
    'price': 8.0,
    'imageUrl': 'https://images.unsplash.com/photo-1550572017-edd951b55104?auto=format&fit=crop&w=400&q=80',
    'category': 'medicine',
  },
  {
    'id': 'other_01', 'name': 'Miniket Rice 5kg',
    'description': 'Premium quality Miniket rice — best for daily cooking',
    'price': 450.0,
    'imageUrl': 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?auto=format&fit=crop&w=400&q=80',
    'category': 'others',
  }
];


void main() async {
  final portStr = Platform.environment['PORT'] ?? '8080';
  final port = int.tryParse(portStr) ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv6, port);
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

  // Load products catalog
  final File productsFile = File('server/products.json');
  List<Map<String, dynamic>> menuItems = [];
  try {
    if (await productsFile.exists()) {
      final content = await productsFile.readAsString();
      final decoded = jsonDecode(content) as List<dynamic>;
      menuItems = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      print('📦 Loaded ${menuItems.length} menu items from products.json');
    } else {
      menuItems = List<Map<String, dynamic>>.from(_defaultCatalog);
      await Directory('server').create(recursive: true);
      await productsFile.writeAsString(jsonEncode(menuItems));
      print('📦 Initialized products.json with ${menuItems.length} default menu items');
    }
  } catch (e) {
    print('⚠️ Error loading products.json: $e. Using default catalog.');
    menuItems = List<Map<String, dynamic>>.from(_defaultCatalog);
  }

  await for (HttpRequest request in server) {
    // Add CORS headers to all responses
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      continue;
    }

    final requestPath = request.uri.path;
    if (requestPath.startsWith('/uploads/')) {
      final fileName = requestPath.replaceFirst('/uploads/', '');
      if (fileName.contains('..') || fileName.contains('/') || fileName.contains('\\')) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Forbidden')
          ..close();
        continue;
      }
      final file = File('server/uploads/$fileName');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        String contentType = 'application/octet-stream';
        if (fileName.endsWith('.png')) contentType = 'image/png';
        else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) contentType = 'image/jpeg';
        else if (fileName.endsWith('.gif')) contentType = 'image/gif';
        else if (fileName.endsWith('.webp')) contentType = 'image/webp';

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.parse(contentType)
          ..add(bytes)
          ..close();
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('File not found')
          ..close();
      }
      continue;
    }

    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final ws = await WebSocketTransformer.upgrade(request);
      final client = ConnectedClient(ws);
      clients.add(client);
      print('🟢 New connection. Total: ${clients.length}');

      ws.listen(
        (data) async {
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
                break;

              // ─── Menu/Food Catalog Events ───
              case 'get_menu':
                _sendToClient(ws, 'menu_updated', {'items': menuItems});
                break;

              case 'add_food_item':
                final id = 'food_${DateTime.now().microsecondsSinceEpoch}';
                final name = msgData['name'] as String? ?? '';
                final description = msgData['description'] as String? ?? '';
                final price = (msgData['price'] as num?)?.toDouble() ?? 0.0;
                final category = msgData['category'] as String? ?? 'food';
                String imageUrl = msgData['imageUrl'] as String? ?? '';

                final imageBase64 = msgData['imageBase64'] as String?;
                if (imageBase64 != null && imageBase64.isNotEmpty) {
                  try {
                    final bytes = base64Decode(imageBase64);
                    final uploadDir = Directory('server/uploads');
                    if (!await uploadDir.exists()) {
                      await uploadDir.create(recursive: true);
                    }
                    final fileName = '${DateTime.now().microsecondsSinceEpoch}_${(100000 + Random().nextInt(900000)).toString()}.png';
                    final file = File('server/uploads/$fileName');
                    await file.writeAsBytes(bytes);
                    
                    final host = request.headers.value('host') ?? 'localhost:8080';
                    final scheme = request.requestedUri.scheme;
                    imageUrl = '$scheme://$host/uploads/$fileName';
                    print('   🖼️ Saved uploaded image to $imageUrl');
                  } catch (e) {
                    print('   ⚠️ Failed to save image: $e');
                  }
                }

                final newItem = {
                  'id': id,
                  'name': name,
                  'description': description,
                  'price': price,
                  'imageUrl': imageUrl,
                  'category': category,
                };
                menuItems.add(newItem);
                print('   🍔 Added new food item: $name');
                
                await productsFile.writeAsString(jsonEncode(menuItems));
                _broadcastAll(clients, 'menu_updated', {'items': menuItems});
                break;

              case 'update_food_item':
                final itemId = msgData['id'] as String?;
                if (itemId != null) {
                  final idx = menuItems.indexWhere((e) => e['id'] == itemId);
                  if (idx >= 0) {
                    final name = msgData['name'] as String? ?? menuItems[idx]['name'];
                    final description = msgData['description'] as String? ?? menuItems[idx]['description'];
                    final price = (msgData['price'] as num?)?.toDouble() ?? menuItems[idx]['price'];
                    final category = msgData['category'] as String? ?? menuItems[idx]['category'];
                    String imageUrl = msgData['imageUrl'] as String? ?? menuItems[idx]['imageUrl'];

                    final imageBase64 = msgData['imageBase64'] as String?;
                    if (imageBase64 != null && imageBase64.isNotEmpty) {
                      try {
                        final bytes = base64Decode(imageBase64);
                        final uploadDir = Directory('server/uploads');
                        if (!await uploadDir.exists()) {
                          await uploadDir.create(recursive: true);
                        }
                        final fileName = '${DateTime.now().microsecondsSinceEpoch}_${(100000 + Random().nextInt(900000)).toString()}.png';
                        final file = File('server/uploads/$fileName');
                        await file.writeAsBytes(bytes);
                        
                        final host = request.headers.value('host') ?? 'localhost:8080';
                        final scheme = request.requestedUri.scheme;
                        imageUrl = '$scheme://$host/uploads/$fileName';
                        print('   🖼️ Saved updated image to $imageUrl');
                      } catch (e) {
                        print('   ⚠️ Failed to save image: $e');
                      }
                    }

                    menuItems[idx] = {
                      'id': itemId,
                      'name': name,
                      'description': description,
                      'price': price,
                      'imageUrl': imageUrl,
                      'category': category,
                    };
                    print('   🍔 Updated food item: $name');
                    
                    await productsFile.writeAsString(jsonEncode(menuItems));
                    _broadcastAll(clients, 'menu_updated', {'items': menuItems});
                  }
                }
                break;

              case 'delete_food_item':
                final itemId = msgData['id'] as String?;
                if (itemId != null) {
                  final idx = menuItems.indexWhere((e) => e['id'] == itemId);
                  if (idx >= 0) {
                    final deletedName = menuItems[idx]['name'];
                    menuItems.removeAt(idx);
                    print('   🗑️ Deleted food item: $deletedName');
                    
                    await productsFile.writeAsString(jsonEncode(menuItems));
                    _broadcastAll(clients, 'menu_updated', {'items': menuItems});
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

                     Future.delayed(const Duration(hours: 2), () {
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

              // ─── Client requests missed/pending orders on reconnect ───
              case 'get_pending_orders':
                final requestingType = msgData['clientType'] as String?;
                if (requestingType == 'restaurant') {
                  final localOrderIds = (msgData['orderIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  final Set<String> processedIds = {};

                  // 1. Send all currently active orders on server
                  for (final order in orders.values) {
                    final orderId = order['id'] as String;
                    final status = order['status'] as String?;
                    if (status != 'delivered' && status != 'rejected') {
                      _sendToClient(ws, 'new_order', order);
                      processedIds.add(orderId);
                    }
                  }

                  // 2. Identify orders restaurant has active locally but are no longer active on server
                  for (final localId in localOrderIds) {
                    if (!processedIds.contains(localId)) {
                      _sendToClient(ws, 'order_not_found', {'id': localId});
                    }
                  }
                  print('   📦 Synchronized restaurant orders. Local: ${localOrderIds.length}, Active on server: ${processedIds.length}');
                } else if (requestingType == 'rider') {
                  final availableOrderIds = (msgData['availableOrderIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  final activeDeliveryId = msgData['activeDeliveryId']?.toString();
                  final Set<String> serverReadyIds = {};

                  // 1. Check orders on server
                  for (final order in orders.values) {
                    final orderId = order['id'] as String;
                    final status = order['status'] as String?;

                    // If it is active delivery of this rider, sync its status
                    if (activeDeliveryId != null && orderId == activeDeliveryId) {
                      _sendToClient(ws, 'order_status_updated', order);
                    }

                    // If it is ready for pickup, send as available
                    if (status == 'readyForPickup') {
                      _sendToClient(ws, 'order_ready_for_pickup', order);
                      serverReadyIds.add(orderId);
                    }
                  }

                  // 2. For active delivery, if not found on server, mark not found
                  if (activeDeliveryId != null && !orders.containsKey(activeDeliveryId)) {
                    _sendToClient(ws, 'order_not_found', {'id': activeDeliveryId});
                  }

                  // 3. For available orders, if no longer ready on server, mark not found so rider removes them
                  for (final localId in availableOrderIds) {
                    if (!serverReadyIds.contains(localId)) {
                      _sendToClient(ws, 'order_not_found', {'id': localId});
                    }
                  }
                  print('   🛵 Synchronized rider orders. Available: ${availableOrderIds.length}, Active: $activeDeliveryId');
                } else if (requestingType == 'customer') {
                  final orderIds = (msgData['orderIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                  for (final id in orderIds) {
                    final order = orders[id];
                    if (order != null) {
                      _sendToClient(ws, 'order_status_updated', order);
                    } else {
                      _sendToClient(ws, 'order_not_found', {'id': id});
                    }
                  }
                  print('   👤 Synchronized customer orders. Count: ${orderIds.length}');
                }
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
