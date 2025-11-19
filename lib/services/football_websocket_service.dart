import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Real-time Football WebSocket Service
/// Connects to API-Football WebSocket for instant match updates
/// Documentation: https://www.api-football.com/documentation-v3#section/Websocket
class FootballWebSocketService {
  // Singleton pattern
  static final FootballWebSocketService _instance = FootballWebSocketService._internal();
  factory FootballWebSocketService() => _instance;
  FootballWebSocketService._internal();

  static const String _wsUrl = 'wss://v3.football.api-sports.io/events';
  static const String _apiKey = '91829c7254923be05777fc60f4696d98';

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _eventController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  final Set<int> _subscribedFixtures = {};
  
  // Connection status stream
  final StreamController<ConnectionStatus> _statusController = 
      StreamController<ConnectionStatus>.broadcast();
  
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;
  
  // Real-time events stream
  Stream<Map<String, dynamic>> get events => _eventController?.stream ?? const Stream.empty();
  
  bool get isConnected => _isConnected;
  Set<int> get subscribedFixtures => Set.from(_subscribedFixtures);

  /// Initialize and connect to WebSocket
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      print('⚡ WebSocket already connected or connecting');
      return;
    }

    try {
      _isConnecting = true;
      _statusController.add(ConnectionStatus.connecting);
      
      print('⚡ Connecting to WebSocket: $_wsUrl');
      
      // Create WebSocket connection with API key in headers
      final uri = Uri.parse(_wsUrl);
      _channel = WebSocketChannel.connect(
        uri,
        // Note: WebSocket doesn't support custom headers directly
        // API-Football may require sending API key in first message
      );

      // Initialize event controller
      _eventController = StreamController<Map<String, dynamic>>.broadcast();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Send authentication message with API key
      _sendAuthMessage();

      _isConnected = true;
      _isConnecting = false;
      _statusController.add(ConnectionStatus.connected);
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      print('✅ WebSocket connected successfully');
    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnecting = false;
      _statusController.add(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Send authentication message with API key
  void _sendAuthMessage() {
    try {
      final authMessage = json.encode({
        'type': 'auth',
        'apiKey': _apiKey,
      });
      _channel?.sink.add(authMessage);
      print('🔑 Authentication message sent');
    } catch (e) {
      print('❌ Error sending auth message: $e');
    }
  }

  /// Subscribe to specific fixture for real-time updates
  void subscribeToFixture(int fixtureId) {
    if (!_isConnected) {
      print('⚠️ WebSocket not connected, cannot subscribe to fixture $fixtureId');
      return;
    }

    if (_subscribedFixtures.contains(fixtureId)) {
      print('ℹ️ Already subscribed to fixture $fixtureId');
      return;
    }

    try {
      final subscribeMessage = json.encode({
        'type': 'subscribe',
        'fixture': fixtureId,
      });
      
      _channel?.sink.add(subscribeMessage);
      _subscribedFixtures.add(fixtureId);
      
      print('📡 Subscribed to fixture: $fixtureId');
    } catch (e) {
      print('❌ Error subscribing to fixture $fixtureId: $e');
    }
  }

  /// Unsubscribe from specific fixture
  void unsubscribeFromFixture(int fixtureId) {
    if (!_isConnected || !_subscribedFixtures.contains(fixtureId)) {
      return;
    }

    try {
      final unsubscribeMessage = json.encode({
        'type': 'unsubscribe',
        'fixture': fixtureId,
      });
      
      _channel?.sink.add(unsubscribeMessage);
      _subscribedFixtures.remove(fixtureId);
      
      print('📡 Unsubscribed from fixture: $fixtureId');
    } catch (e) {
      print('❌ Error unsubscribing from fixture $fixtureId: $e');
    }
  }

  /// Subscribe to all live fixtures
  void subscribeToAllLive() {
    if (!_isConnected) {
      print('⚠️ WebSocket not connected, cannot subscribe to live fixtures');
      return;
    }

    try {
      final subscribeMessage = json.encode({
        'type': 'subscribe',
        'live': 'all',
      });
      
      _channel?.sink.add(subscribeMessage);
      print('📡 Subscribed to all live fixtures');
    } catch (e) {
      print('❌ Error subscribing to live fixtures: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);
      
      // Check message type
      if (data['type'] == 'pong') {
        // Pong response to keep connection alive
        return;
      }
      
      if (data['type'] == 'event') {
        // Real-time match event
        print('⚡ Real-time event: ${data['event']} - Fixture ${data['fixture']}');
        _eventController?.add(data);
      } else if (data['type'] == 'status') {
        // Match status update
        print('📊 Status update: Fixture ${data['fixture']} - ${data['status']}');
        _eventController?.add(data);
      } else {
        // Unknown message type
        print('ℹ️ WebSocket message: $data');
      }
    } catch (e) {
      print('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(error) {
    print('❌ WebSocket error: $error');
    _statusController.add(ConnectionStatus.error);
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    print('⚠️ WebSocket disconnected');
    _isConnected = false;
    _statusController.add(ConnectionStatus.disconnected);
    _pingTimer?.cancel();
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_reconnectTimer != null && _reconnectTimer!.isActive) {
      return;
    }

    print('🔄 Scheduling reconnect in 5 seconds...');
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        try {
          final pingMessage = json.encode({'type': 'ping'});
          _channel?.sink.add(pingMessage);
          print('🏓 Ping sent');
        } catch (e) {
          print('❌ Error sending ping: $e');
        }
      }
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    _subscribedFixtures.clear();
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _isConnected = false;
    _statusController.add(ConnectionStatus.disconnected);
    
    await _eventController?.close();
    _eventController = null;
    
    print('✅ WebSocket disconnected');
  }

  /// Reconnect to WebSocket
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _statusController.close();
  }
}

/// WebSocket connection status
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}
