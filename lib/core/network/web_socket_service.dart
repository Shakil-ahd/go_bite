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

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  bool get isConnected => _isConnected;

  WebSocketService({
    required this.url,
    this.clientType = AppClientType.customer,
  });

  static String get defaultUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'ws://10.0.2.2:8080';
    }
    return 'ws://localhost:8080';
  }

  void connect() {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    debugPrint('🔌 Connecting to WebSocket: $url (as ${clientType.name})');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            _retryCount = 0;
            debugPrint('🟢 WebSocket connected! Registering as ${clientType.name}...');
            
            // Register client type with server
            _registerClientType();
            
            // Start ping timer to keep connection alive
            _startPingTimer();
          }
          try {
            final data = jsonDecode(message as String);
            if (data is Map<String, dynamic>) {
              final event = data['event'] as String?;
              if (event == 'pong') return; // ignore pings
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
    _isConnected = false;
    _isConnecting = false;
    _channel = null;
    _pingTimer?.cancel();

    if (_retryCount >= 5) {
      debugPrint('⏹️ Max reconnection attempts reached.');
      return;
    }
    _retryCount++;

    final delay = Duration(seconds: 3 * _retryCount);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      debugPrint('🔄 Reconnecting ($_retryCount/5)...');
      connect();
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

  void dispose() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    debugPrint('🧹 WebSocketService disposed.');
  }
}
