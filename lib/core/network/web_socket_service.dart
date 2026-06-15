import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum AppClientType { customer, restaurant, rider }

class WebSocketService {
  final String url;
  final AppClientType clientType;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _retryCount = 0;
  bool _disposed = false;

  /// Called every time a successful connection is established.
  /// Use this to re-request any missed data (e.g. pending orders).
  VoidCallback? onConnected;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  WebSocketService({
    required this.url,
    this.clientType = AppClientType.customer,
    this.onConnected,
  });

  static String get defaultUrl {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ws://10.0.2.2:8080';
      }
      final baseHost = Uri.base.host;
      if (baseHost.isNotEmpty) {
        return 'ws://$baseHost:8080';
      }
      return 'ws://127.0.0.1:8080';
    }
    return 'wss://go-bite.onrender.com';
  }

  void connect() {
    if (_disposed || _isConnected || _isConnecting) return;
    _isConnecting = true;

    debugPrint('🔌 Connecting to WebSocket: $url (as ${clientType.name})');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _isConnected = true;
      _isConnecting = false;
      _retryCount = 0;
      debugPrint('🟢 WebSocket connected! Registering as ${clientType.name}...');
      _registerClientType();
      _startPingTimer();

      // Notify listener so blocs can re-request pending data
      onConnected?.call();

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            if (data is Map<String, dynamic>) {
              final event = data['event'] as String?;
              if (event == 'pong') return;
              _messageController.add(data);
            }
          } catch (e) {
            debugPrint('⚠️ Failed to decode message: $e');
          }
        },
        onDone: () {
          debugPrint('🔴 WebSocket disconnected.');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('⚠️ WebSocket error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      debugPrint('⚠️ Connection failed: $e');
      _handleDisconnect();
    }
  }

  void _registerClientType() {
    send('register', {'type': clientType.name});
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _channel != null) {
        send('ping', {'client': clientType.name});
      }
    });
  }

  void _handleDisconnect() {
    if (_disposed) return;
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _pingTimer?.cancel();

    // Exponential backoff: 3s, 6s, 12s, 24s, 48s … max 60s, then keeps retrying
    _retryCount++;
    final delaySeconds = (_retryCount <= 5)
        ? (3 * _retryCount)
        : 60; // cap at 60 seconds, keep retrying indefinitely
    final delay = Duration(seconds: delaySeconds);
    _reconnectTimer?.cancel();
    debugPrint('🔄 Reconnecting in ${delay.inSeconds}s (attempt $_retryCount)...');
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  /// Sends a structured event through the WebSocket
  void send(String eventName, Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) {
      debugPrint('❌ Cannot send "$eventName": not connected.');
      return;
    }

    final messageJson = {
      'event': eventName,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(messageJson));
      if (eventName != 'ping' && eventName != 'rider_location_updated') {
        debugPrint('📤 Sent: $eventName');
      }
    } catch (e) {
      debugPrint('❌ Send error: $e');
      _handleDisconnect();
    }
  }

  /// Call this when the app resumes from background to force a reconnect check
  void forceReconnect() {
    if (!_isConnected && !_isConnecting && !_disposed) {
      _reconnectTimer?.cancel();
      _retryCount = 0;
      debugPrint('🔁 Force reconnecting on app resume...');
      connect();
    }
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    debugPrint('🧹 WebSocketService disposed.');
  }
}
