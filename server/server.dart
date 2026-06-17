import 'dart:io';
import 'dart:convert';
import 'dart:math';

enum ClientType { customer, restaurant, rider, unknown }

class ConnectedClient {
  final WebSocket ws;
  ClientType type;
  String? orderId;

  ConnectedClient(this.ws, {this.type = ClientType.unknown, this.orderId});
}

const List<Map<String, dynamic>> _defaultCatalog = [
  {
    'id': 'food_01',
    'name': 'Kacchi Biryani',
    'description':
        'Authentic Dhaka-style Kacchi with tender goat meat, aromatic rice, potatoes & boiled eggs',
    'price': 350.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
    'restaurantId': 'puran_dhaka_kitchen@gobite.com',
    'restaurantName': 'Puran Dhaka Kitchen',
    'restaurantAddress': 'Lalbagh, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'food_02',
    'name': 'Chicken Biryani',
    'description':
        'Fragrant basmati rice with juicy chicken pieces, saffron & special spices',
    'price': 280.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
    'restaurantId': 'star_kabab@gobite.com',
    'restaurantName': 'Star Kabab & Restaurant',
    'restaurantAddress': 'Dhanmondi, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'food_03',
    'name': 'Morog Polao',
    'description':
        'Classic Bengali chicken polao with ghee-flavored rice & whole spices',
    'price': 300.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1596797038530-2c107229654b?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
    'restaurantId': 'haji_biryani@gobite.com',
    'restaurantName': 'Haji Biryani',
    'restaurantAddress': 'Puran Dhaka, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'food_04',
    'name': 'Beef Tehari',
    'description':
        'Spicy beef tehari with fragrant rice, potatoes & traditional Puran Dhaka spices',
    'price': 220.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1574653853027-5382a3d23a15?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
    'restaurantId': 'gharana_eats@gobite.com',
    'restaurantName': 'Gharana Eats',
    'restaurantAddress': 'Banani, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'food_05',
    'name': 'Khichuri + Dim Bhaji',
    'description':
        'Comfort food: Dal khichuri served with egg omelette & mixed vegetable bhaji',
    'price': 150.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=400&q=80',
    'category': 'food',
    'restaurantId': 'dhaka_kitchen@gobite.com',
    'restaurantName': 'Dhaka Kitchen',
    'restaurantAddress': 'Mirpur, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'drink_01',
    'name': 'Borhani',
    'description':
        'Traditional Bangladeshi spicy yogurt drink, perfect with biryani',
    'price': 40.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?auto=format&fit=crop&w=400&q=80',
    'category': 'drinks',
    'restaurantId': 'puran_dhaka_kitchen@gobite.com',
    'restaurantName': 'Puran Dhaka Kitchen',
    'restaurantAddress': 'Lalbagh, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'drink_02',
    'name': 'Mango Lassi',
    'description':
        'Creamy mango yogurt smoothie made with fresh seasonal mangoes',
    'price': 60.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=400&q=80',
    'category': 'drinks',
    'restaurantId': 'star_kabab@gobite.com',
    'restaurantName': 'Star Kabab & Restaurant',
    'restaurantAddress': 'Dhanmondi, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'snack_01',
    'name': 'Fuchka (8 pcs)',
    'description':
        'Crispy hollow shells filled with spicy tamarind water, chickpeas & potatoes',
    'price': 40.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=400&q=80',
    'category': 'snacks',
    'restaurantId': 'chotpoti_ghar@gobite.com',
    'restaurantName': 'Chotpoti Ghar',
    'restaurantAddress': 'Tejgaon, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'snack_02',
    'name': 'Chotpoti',
    'description':
        'Spicy chickpea curry topped with boiled egg, onion & tamarind sauce',
    'price': 50.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80',
    'category': 'snacks',
    'restaurantId': 'chotpoti_ghar@gobite.com',
    'restaurantName': 'Chotpoti Ghar',
    'restaurantAddress': 'Tejgaon, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'med_01',
    'name': 'Napa Extra',
    'description':
        'Paracetamol 500mg + Caffeine 65mg — for headache, fever & body pain',
    'price': 12.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    'category': 'medicine',
    'restaurantId': 'lazz_pharma@gobite.com',
    'restaurantName': 'Lazz Pharma',
    'restaurantAddress': 'Kakrail, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'med_02',
    'name': 'Seclo 20mg',
    'description':
        'Omeprazole capsule for acidity, heartburn & gastric problems',
    'price': 8.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1550572017-edd951b55104?auto=format&fit=crop&w=400&q=80',
    'category': 'medicine',
    'restaurantId': 'lazz_pharma@gobite.com',
    'restaurantName': 'Lazz Pharma',
    'restaurantAddress': 'Kakrail, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200&auto=format&fit=crop&q=60',
  },
  {
    'id': 'other_01',
    'name': 'Miniket Rice 5kg',
    'description': 'Premium quality Miniket rice — best for daily cooking',
    'price': 450.0,
    'imageUrl':
        'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?auto=format&fit=crop&w=400&q=80',
    'category': 'others',
    'restaurantId': 'shwapno@gobite.com',
    'restaurantName': 'Shwapno Super Store',
    'restaurantAddress': 'Gulshan, Dhaka',
    'restaurantImageUrl':
        'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?w=200&auto=format&fit=crop&q=60',
  },
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

  final Map<String, Map<String, dynamic>> orders = {};

  final File riderRatingsFile = File('${File(Platform.script.toFilePath()).parent.path}/rider_ratings.json');
  final Map<String, Map<String, dynamic>> riderRatings = {};

  final String serverDir = File(Platform.script.toFilePath()).parent.path;
  final File productsFile = File('$serverDir/products.json');
  List<Map<String, dynamic>> menuItems = [];
  try {
    if (await productsFile.exists()) {
      final content = await productsFile.readAsString();
      final decoded = jsonDecode(content) as List<dynamic>;
      menuItems = decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      print('📦 Loaded ${menuItems.length} menu items from products.json');
    } else {
      menuItems = List<Map<String, dynamic>>.from(_defaultCatalog);
      await Directory(serverDir).create(recursive: true);
      await productsFile.writeAsString(jsonEncode(menuItems));
      print(
        '📦 Initialized products.json with ${menuItems.length} default menu items',
      );
    }
  } catch (e) {
    print('⚠️ Error loading products.json: $e. Using default catalog.');
    menuItems = List<Map<String, dynamic>>.from(_defaultCatalog);
  }

  final File usersFile = File('$serverDir/users.json');
  final File restaurantsFile = File('$serverDir/restaurants.json');
  final File ridersFile = File('$serverDir/riders.json');

  Future<Map<String, Map<String, dynamic>>> loadUserMap(File file) async {
    try {
      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content) as Map<dynamic, dynamic>;
        return decoded.map(
          (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
        );
      }
    } catch (e) {
      print('⚠️ Error loading user file ${file.path}: $e');
    }
    return {};
  }

  Future<void> saveUserMap(
    File file,
    Map<String, Map<String, dynamic>> data,
  ) async {
    try {
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('⚠️ Error saving user file ${file.path}: $e');
    }
  }

  Map<String, Map<String, dynamic>> customerUsers = await loadUserMap(
    usersFile,
  );
  Map<String, Map<String, dynamic>> restaurantUsers = await loadUserMap(
    restaurantsFile,
  );
  Map<String, Map<String, dynamic>> riderUsers = await loadUserMap(ridersFile);

  final File ordersFile = File('$serverDir/orders.json');
  orders.addAll(await loadUserMap(ordersFile));
  riderRatings.addAll(await loadUserMap(riderRatingsFile));

  print(
    '👤 Loaded ${customerUsers.length} customers, ${restaurantUsers.length} restaurants, ${riderUsers.length} riders, ${orders.length} orders, ${riderRatings.length} rider ratings',
  );

  await for (HttpRequest request in server) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Origin, Content-Type, Accept',
    );

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.ok
        ..close();
      continue;
    }

    final requestPath = request.uri.path;

    if (request.method == 'POST' && requestPath == '/upload') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content) as Map<String, dynamic>;
        final imageBase64 = body['image'] as String?;
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          final bytes = base64Decode(imageBase64);
          final serverDir = File(Platform.script.toFilePath()).parent.path;
          final uploadDir = Directory('$serverDir/uploads');
          if (!await uploadDir.exists()) {
            await uploadDir.create(recursive: true);
          }
          final fileName =
              'upload_${DateTime.now().microsecondsSinceEpoch}_${(100000 + Random().nextInt(900000)).toString()}.png';
          final file = File('$serverDir/uploads/$fileName');
          await file.writeAsBytes(bytes);

          final host = request.headers.value('host') ?? 'localhost:8080';
          final scheme = request.requestedUri.scheme;
          final imageUrl = '$scheme://$host/uploads/$fileName';

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'url': imageUrl}))
            ..close();
          print('   🖼️ HTTP POST Uploaded image: $imageUrl');
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Missing "image" base64 payload')
            ..close();
        }
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Upload error: $e')
          ..close();
      }
      continue;
    }

    if (request.method == 'POST' && requestPath == '/auth/signup') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content) as Map<String, dynamic>;
        final role = body['role'] as String?;
        final profile = body['profile'] as Map<String, dynamic>?;

        if (role == null || profile == null) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Missing role or profile')
            ..close();
          continue;
        }

        final email = (profile['email'] as String).toLowerCase().trim();
        Map<String, Map<String, dynamic>> targetMap;
        File targetFile;

        if (role == 'customer') {
          targetMap = customerUsers;
          targetFile = usersFile;
        } else if (role == 'restaurant') {
          targetMap = restaurantUsers;
          targetFile = restaurantsFile;
        } else if (role == 'rider') {
          targetMap = riderUsers;
          targetFile = ridersFile;
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Invalid role')
            ..close();
          continue;
        }

        if (targetMap.containsKey(email)) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Email already registered')
            ..close();
          continue;
        }

        targetMap[email] = profile;
        await saveUserMap(targetFile, targetMap);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(profile))
          ..close();
        print('👤 Registered new $role: $email');
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Signup error: $e')
          ..close();
      }
      continue;
    }

    if (request.method == 'POST' && requestPath == '/auth/login') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content) as Map<String, dynamic>;
        final role = body['role'] as String?;
        final email = (body['email'] as String?)?.toLowerCase().trim();
        final password = body['password'] as String?;

        if (role == null || email == null || password == null) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Missing credentials')
            ..close();
          continue;
        }

        Map<String, Map<String, dynamic>> targetMap;
        if (role == 'customer') {
          targetMap = customerUsers;
        } else if (role == 'restaurant') {
          targetMap = restaurantUsers;
        } else if (role == 'rider') {
          targetMap = riderUsers;
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Invalid role')
            ..close();
          continue;
        }

        final profile = targetMap[email];
        if (profile != null && profile['password'] == password) {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(profile))
            ..close();
          print('👤 Logged in $role: $email');
        } else {
          request.response
            ..statusCode = HttpStatus.unauthorized
            ..write('Invalid email or password')
            ..close();
        }
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Login error: $e')
          ..close();
      }
      continue;
    }

    if (request.method == 'POST' && requestPath == '/auth/update') {
      try {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content) as Map<String, dynamic>;
        final role = body['role'] as String?;
        final profile = body['profile'] as Map<String, dynamic>?;

        if (role == null || profile == null) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Missing role or profile')
            ..close();
          continue;
        }

        final email = (profile['email'] as String).toLowerCase().trim();
        Map<String, Map<String, dynamic>> targetMap;
        File targetFile;

        if (role == 'customer') {
          targetMap = customerUsers;
          targetFile = usersFile;
        } else if (role == 'restaurant') {
          targetMap = restaurantUsers;
          targetFile = restaurantsFile;
        } else if (role == 'rider') {
          targetMap = riderUsers;
          targetFile = ridersFile;
        } else {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write('Invalid role')
            ..close();
          continue;
        }

        targetMap[email] = profile;
        await saveUserMap(targetFile, targetMap);

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(profile))
          ..close();
        print('👤 Updated $role profile: $email');
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..write('Update error: $e')
          ..close();
      }
      continue;
    }

    if (requestPath.startsWith('/uploads/')) {
      final fileName = requestPath.replaceFirst('/uploads/', '');
      if (fileName.contains('..') ||
          fileName.contains('/') ||
          fileName.contains('\\')) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Forbidden')
          ..close();
        continue;
      }
      final serverDir = File(Platform.script.toFilePath()).parent.path;
      final file = File('$serverDir/uploads/$fileName');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        String contentType = 'application/octet-stream';
        if (fileName.endsWith('.png'))
          contentType = 'image/png';
        else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg'))
          contentType = 'image/jpeg';
        else if (fileName.endsWith('.gif'))
          contentType = 'image/gif';
        else if (fileName.endsWith('.webp'))
          contentType = 'image/webp';

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
              case 'register':
                final type = msgData['type'] as String?;
                client.type = _parseType(type);
                print('   ✅ Registered as: ${client.type.name}');
                break;

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

                final restaurantId = msgData['restaurantId'] as String?;
                final restaurantName = msgData['restaurantName'] as String?;
                final restaurantAddress =
                    msgData['restaurantAddress'] as String?;
                final restaurantImageUrl =
                    msgData['restaurantImageUrl'] as String?;

                final imageBase64 = msgData['imageBase64'] as String?;
                if (imageBase64 != null && imageBase64.isNotEmpty) {
                  try {
                    final bytes = base64Decode(imageBase64);
                    final serverDir = File(
                      Platform.script.toFilePath(),
                    ).parent.path;
                    final uploadDir = Directory('$serverDir/uploads');
                    if (!await uploadDir.exists()) {
                      await uploadDir.create(recursive: true);
                    }
                    final fileName =
                        '${DateTime.now().microsecondsSinceEpoch}_${(100000 + Random().nextInt(900000)).toString()}.png';
                    final file = File('$serverDir/uploads/$fileName');
                    await file.writeAsBytes(bytes);

                    final host =
                        request.headers.value('host') ?? 'localhost:8080';
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
                  if (restaurantId != null) 'restaurantId': restaurantId,
                  if (restaurantName != null) 'restaurantName': restaurantName,
                  if (restaurantAddress != null)
                    'restaurantAddress': restaurantAddress,
                  if (restaurantImageUrl != null)
                    'restaurantImageUrl': restaurantImageUrl,
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
                    final name =
                        msgData['name'] as String? ?? menuItems[idx]['name'];
                    final description =
                        msgData['description'] as String? ??
                        menuItems[idx]['description'];
                    final price =
                        (msgData['price'] as num?)?.toDouble() ??
                        menuItems[idx]['price'];
                    final category =
                        msgData['category'] as String? ??
                        menuItems[idx]['category'];
                    String imageUrl =
                        msgData['imageUrl'] as String? ??
                        menuItems[idx]['imageUrl'];

                    final restaurantId =
                        msgData['restaurantId'] as String? ??
                        menuItems[idx]['restaurantId'];
                    final restaurantName =
                        msgData['restaurantName'] as String? ??
                        menuItems[idx]['restaurantName'];
                    final restaurantAddress =
                        msgData['restaurantAddress'] as String? ??
                        menuItems[idx]['restaurantAddress'];
                    final restaurantImageUrl =
                        msgData['restaurantImageUrl'] as String? ??
                        menuItems[idx]['restaurantImageUrl'];

                    final imageBase64 = msgData['imageBase64'] as String?;
                    if (imageBase64 != null && imageBase64.isNotEmpty) {
                      try {
                        final bytes = base64Decode(imageBase64);
                        final serverDir = File(
                          Platform.script.toFilePath(),
                        ).parent.path;
                        final uploadDir = Directory('$serverDir/uploads');
                        if (!await uploadDir.exists()) {
                          await uploadDir.create(recursive: true);
                        }
                        final fileName =
                            '${DateTime.now().microsecondsSinceEpoch}_${(100000 + Random().nextInt(900000)).toString()}.png';
                        final file = File('$serverDir/uploads/$fileName');
                        await file.writeAsBytes(bytes);

                        final host =
                            request.headers.value('host') ?? 'localhost:8080';
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
                      if (restaurantId != null) 'restaurantId': restaurantId,
                      if (restaurantName != null)
                        'restaurantName': restaurantName,
                      if (restaurantAddress != null)
                        'restaurantAddress': restaurantAddress,
                      if (restaurantImageUrl != null)
                        'restaurantImageUrl': restaurantImageUrl,
                    };
                    print('   🍔 Updated food item: $name');

                    await productsFile.writeAsString(jsonEncode(menuItems));
                    _broadcastAll(clients, 'menu_updated', {
                      'items': menuItems,
                    });
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
                    _broadcastAll(clients, 'menu_updated', {
                      'items': menuItems,
                    });
                  }
                }
                break;

              case 'new_order':
                final orderId = msgData['id'] as String?;
                if (orderId != null) {
                  orders[orderId] = msgData;
                  print('   📋 Order stored: $orderId');
                  await saveUserMap(ordersFile, orders);

                  _broadcastToType(
                    clients,
                    ClientType.restaurant,
                    'new_order',
                    msgData,
                    exclude: ws,
                  );
                }
                break;

              case 'order_status_updated':
                final orderId = msgData['id'] as String?;
                final newStatus = msgData['status'] as String?;
                if (orderId != null) {
                  orders[orderId] = msgData;
                  print('   🔄 Order $orderId → $newStatus');
                  await saveUserMap(ordersFile, orders);

                  _broadcastAll(
                    clients,
                    'order_status_updated',
                    msgData,
                    exclude: ws,
                  );

                  if (newStatus == 'readyForPickup') {
                    _broadcastToType(
                      clients,
                      ClientType.rider,
                      'order_ready_for_pickup',
                      msgData,
                    );
                  }

                  if (newStatus == 'delivered' || newStatus == 'rejected') {
                    if (newStatus == 'delivered') {
                      final riderName = msgData['riderName'] as String?;
                      if (riderName != null) {
                        riderRatings.putIfAbsent(
                          riderName,
                          () => {
                            'totalRatings': 0,
                            'totalScore': 0.0,
                            'totalDeliveries': 0,
                          },
                        );
                        riderRatings[riderName]!['totalDeliveries'] =
                            (riderRatings[riderName]!['totalDeliveries']
                                as int) +
                            1;

                        await saveUserMap(riderRatingsFile, riderRatings);

                        final statsData = {
                          'riderName': riderName,
                          'totalDeliveries':
                              riderRatings[riderName]!['totalDeliveries'],
                          'averageRating':
                              (riderRatings[riderName]!['totalRatings']
                                      as int) >
                                  0
                              ? (riderRatings[riderName]!['totalScore']
                                        as double) /
                                    (riderRatings[riderName]!['totalRatings']
                                        as int)
                              : 0.0,
                          'totalRatings':
                              riderRatings[riderName]!['totalRatings'],
                        };
                        _broadcastAll(
                          clients,
                          'rider_stats_updated',
                          statsData,
                          exclude: ws,
                        );
                      }
                    }

                    Future.delayed(const Duration(hours: 2), () {
                      orders.remove(orderId);
                      saveUserMap(ordersFile, orders);
                    });
                  }
                }
                break;

              case 'rider_location_updated':
                _broadcastToType(
                  clients,
                  ClientType.customer,
                  'rider_location_updated',
                  msgData,
                  exclude: ws,
                );
                break;

              case 'rider_accepted_order':
                final orderId = msgData['orderId'] as String?;
                if (orderId != null) {
                  client.orderId = orderId;
                  final order = orders[orderId];
                  if (order != null) {
                    final updated = {
                      ...order,
                      'riderName': msgData['riderName'],
                    };

                    orders[orderId] = updated;
                    await saveUserMap(ordersFile, orders);
                    _broadcastToType(
                      clients,
                      ClientType.customer,
                      'order_status_updated',
                      updated,
                      exclude: ws,
                    );
                    _broadcastToType(
                      clients,
                      ClientType.restaurant,
                      'order_status_updated',
                      updated,
                      exclude: ws,
                    );
                    _broadcastToType(
                      clients,
                      ClientType.rider,
                      'order_status_updated',
                      updated,
                      exclude: ws,
                    );
                  }
                }
                break;

              case 'rate_rider':
                final riderName = msgData['riderName'] as String?;
                final rating = msgData['rating'] as num?;
                final review = msgData['review'] as String?;
                if (riderName != null && rating != null) {
                  riderRatings.putIfAbsent(
                    riderName,
                    () => {
                      'totalRatings': 0,
                      'totalScore': 0.0,
                      'totalDeliveries': 0,
                      'reviews': [],
                    },
                  );

                  riderRatings[riderName]!['totalRatings'] =
                      (riderRatings[riderName]!['totalRatings'] as int) + 1;
                  riderRatings[riderName]!['totalScore'] =
                      (riderRatings[riderName]!['totalScore'] as double) +
                      rating.toDouble();

                  if (review != null && review.isNotEmpty) {
                    final reviewsList =
                        (riderRatings[riderName]!['reviews']
                            as List<dynamic>? ??
                        []);
                    reviewsList.add({
                      'rating': rating,
                      'review': review,
                      'timestamp': DateTime.now().toIso8601String(),
                    });
                    riderRatings[riderName]!['reviews'] = reviewsList;
                  }

                  final avg =
                      (riderRatings[riderName]!['totalScore'] as double) /
                      (riderRatings[riderName]!['totalRatings'] as int);

                  final statsData = {
                    'riderName': riderName,
                    'averageRating': avg,
                    'totalRatings': riderRatings[riderName]!['totalRatings'],
                    'totalDeliveries':
                        riderRatings[riderName]!['totalDeliveries'],
                    'reviews': riderRatings[riderName]!['reviews'],
                  };
                  await saveUserMap(riderRatingsFile, riderRatings);
                  print('   ⭐ Rider $riderName rated $rating. New avg: $avg');
                  _broadcastAll(
                    clients,
                    'rider_stats_updated',
                    statsData,
                    exclude: ws,
                  );
                }
                break;

              case 'rate_food_item':
                final foodId = msgData['foodId'] as String?;
                final rating = msgData['rating'] as num?;
                final review = msgData['review'] as String?;
                final userName = msgData['userName'] as String? ?? 'Anonymous';

                if (foodId != null && rating != null) {
                  final idx = menuItems.indexWhere((e) => e['id'] == foodId);
                  if (idx >= 0) {
                    final item = menuItems[idx];
                    final reviewsList = List<Map<String, dynamic>>.from(
                      item['reviews'] as List<dynamic>? ?? [],
                    );

                    reviewsList.add({
                      'rating': rating.toDouble(),
                      'review': review ?? '',
                      'userName': userName,
                      'timestamp': DateTime.now().toIso8601String(),
                    });

                    final double totalScore = reviewsList.fold(
                      0.0,
                      (sum, r) => sum + (r['rating'] as num).toDouble(),
                    );
                    final double avg = totalScore / reviewsList.length;

                    menuItems[idx] = {
                      ...item,
                      'reviews': reviewsList,
                      'averageRating': avg,
                      'ratingCount': reviewsList.length,
                    };

                    print(
                      '   ⭐ Food item $foodId rated $rating by $userName. New avg: $avg',
                    );

                    await productsFile.writeAsString(jsonEncode(menuItems));
                    _broadcastAll(clients, 'menu_updated', {
                      'items': menuItems,
                    });
                  }
                }
                break;

              case 'ping':
                _sendToClient(ws, 'pong', {
                  'time': DateTime.now().toIso8601String(),
                });
                break;

              case 'get_pending_orders':
                final requestingType = msgData['clientType'] as String?;
                if (requestingType == 'restaurant') {
                  final localOrderIds =
                      (msgData['orderIds'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [];
                  final Set<String> processedIds = {};

                  for (final order in orders.values) {
                    final orderId = order['id'] as String;
                    final status = order['status'] as String?;
                    if (status != 'delivered' && status != 'rejected') {
                      _sendToClient(ws, 'new_order', order);
                      processedIds.add(orderId);
                    }
                  }

                  for (final localId in localOrderIds) {
                    if (!processedIds.contains(localId)) {
                      _sendToClient(ws, 'order_not_found', {'id': localId});
                    }
                  }
                  print(
                    '   📦 Synchronized restaurant orders. Local: ${localOrderIds.length}, Active on server: ${processedIds.length}',
                  );
                } else if (requestingType == 'rider') {
                  final availableOrderIds =
                      (msgData['availableOrderIds'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [];
                  final activeDeliveryId = msgData['activeDeliveryId']
                      ?.toString();
                  final Set<String> serverReadyIds = {};

                  for (final order in orders.values) {
                    final orderId = order['id'] as String;
                    final status = order['status'] as String?;

                    if (activeDeliveryId != null &&
                        orderId == activeDeliveryId) {
                      _sendToClient(ws, 'order_status_updated', order);
                    }

                    if (status == 'readyForPickup') {
                      _sendToClient(ws, 'order_ready_for_pickup', order);
                      serverReadyIds.add(orderId);
                    }
                  }

                  if (activeDeliveryId != null &&
                      !orders.containsKey(activeDeliveryId)) {
                    _sendToClient(ws, 'order_not_found', {
                      'id': activeDeliveryId,
                    });
                  }

                  for (final localId in availableOrderIds) {
                    if (!serverReadyIds.contains(localId)) {
                      _sendToClient(ws, 'order_not_found', {'id': localId});
                    }
                  }
                  print(
                    '   🛵 Synchronized rider orders. Available: ${availableOrderIds.length}, Active: $activeDeliveryId',
                  );
                } else if (requestingType == 'customer') {
                  final orderIds =
                      (msgData['orderIds'] as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [];
                  for (final id in orderIds) {
                    final order = orders[id];
                    if (order != null) {
                      _sendToClient(ws, 'order_status_updated', order);
                    } else {
                      _sendToClient(ws, 'order_not_found', {'id': id});
                    }
                  }
                  print(
                    '   👤 Synchronized customer orders. Count: ${orderIds.length}',
                  );
                }
                break;

              default:
                _broadcastAll(
                  clients,
                  event,
                  msgData,
                  timestamp: timestamp,
                  exclude: ws,
                );
            }
          } catch (e) {
            print('⚠️ Parse error: $e');
          }
        },
        onDone: () {
          clients.remove(client);
          print(
            '🔴 Client disconnected (${client.type.name}). Total: ${clients.length}',
          );
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
    case 'customer':
      return ClientType.customer;
    case 'restaurant':
      return ClientType.restaurant;
    case 'rider':
      return ClientType.rider;
    default:
      return ClientType.unknown;
  }
}

void _sendToClient(WebSocket ws, String event, Map<String, dynamic> data) {
  try {
    if (ws.readyState == WebSocket.open) {
      ws.add(
        jsonEncode({
          'event': event,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
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
