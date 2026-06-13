import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnecting = false;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  // Stream exposing incoming messages
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _isConnected;

  WebSocketService({required this.url}) {
    print('WebSocketService initialized for url: $url');
  }

  static String get defaultUrl {
    // For physical device testing on the same Wi-Fi network
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // 10.0.2.2 is the emulator's host loopback. On a physical device, this will fail fast.
      // If you run a local server, change this to your PC's IP address (e.g., 192.168.x.x).
      return 'ws://10.0.2.2:8080';
    }
    return 'ws://localhost:8080';
  }

  void connect() {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    print('🔌 Connecting to WebSocket server: $url ...');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Since WebSocketChannel doesn't block on connection,
      // we monitor the stream to verify status.
      _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            _retryCount = 0;
            print('🟢 WebSocket connected successfully!');
          }
          try {
            final data = jsonDecode(message as String);
            if (data is Map<String, dynamic>) {
              _messageController.add(data);
            }
          } catch (e) {
            print('⚠️ Failed to decode websocket message: $e');
          }
        },
        onDone: () {
          print('🔴 WebSocket connection closed.');
          _handleDisconnect();
        },
        onError: (error) {
          print('⚠️ WebSocket error: $error');
          _handleDisconnect();
        },
      );
    } catch (e) {
      print('⚠️ Failed to establish WebSocket connection: $e');
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _isConnecting = false;
    _channel = null;

    if (_retryCount >= 3) {
      print('⏹️ Max reconnection attempts reached. Stopping WebSocket retries to prevent app freezing.');
      return;
    }
    _retryCount++;

    // Retry connection after 5 seconds instead of 3 to avoid rapid blocking
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('🔄 Attempting reconnection ($_retryCount/3)...');
      connect();
    });
  }

  /// Sends a structured event through the WebSocket
  void send(String eventName, Map<String, dynamic> data) {
    if (_channel == null) {
      print('❌ Cannot send event "$eventName": WebSocket not connected.');
      return;
    }

    final messageJson = {
      'event': eventName,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(messageJson));
      print('📤 Sent event: $eventName with data: $data');
    } catch (e) {
      print('❌ Error sending websocket message: $e');
      _handleDisconnect();
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _messageController.close();
    print('🧹 WebSocketService disposed.');
  }
}
