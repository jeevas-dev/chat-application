
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message_model.dart';

class SocketService {
  io.Socket? _socket;
  final String _baseUrl = 'http://45.129.87.38:6065';
  bool _isConnecting = false;

  
  ValueChanged<MessageModel>? onMessageReceived;
  ValueChanged<String>? onChatUpdated;
  VoidCallback? onConnected;
  ValueChanged<String>? onError;
  VoidCallback? onDisconnected;

  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      if (kDebugMode) {
        print('Socket already connected');
      }
      return;
    }

    if (_isConnecting) {
      if (kDebugMode) {
        print('Socket connection already in progress');
      }
      return;
    }

    _isConnecting = true;
    
    try {
      if (kDebugMode) {
        print('Connecting to socket with token: $token');
      }

      _socket = io.io(
        _baseUrl,
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setExtraHeaders({'Authorization': token})
          .build(),
      );

      _setupEventListeners();
      _socket!.connect();

    } catch (e) {
      _isConnecting = false;
      if (kDebugMode) {
        print('Socket connection error: $e');
      }
      onError?.call('Connection failed: $e');
    }
  }

  void _setupEventListeners() {
    _socket!.onConnect((_) {
      _isConnecting = false;
      if (kDebugMode) {
        print('Socket connected successfully');
      }
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      _isConnecting = false;
      if (kDebugMode) {
        print('Socket disconnected');
      }
      onDisconnected?.call();
    });

    _socket!.onError((data) {
      _isConnecting = false;
      if (kDebugMode) {
        print('Socket error: $data');
      }
      onError?.call(data.toString());
    });

    // Listen for new messages
    _socket!.on('new_message', (data) {
      if (kDebugMode) {
        print('New message received via socket: $data');
      }
      try {
        if (data is Map<String, dynamic>) {
          final message = MessageModel.fromJson(data);
          onMessageReceived?.call(message);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing socket message: $e');
        }
      }
    });

    // Listen for chat updates
    _socket!.on('chat_updated', (data) {
      if (kDebugMode) {
        print('Chat updated via socket: $data');
      }
      if (data is String) {
        onChatUpdated?.call(data);
      }
    });

    // Connection acknowledgement
    _socket!.on('connected', (data) {
      if (kDebugMode) {
        print('Socket connection acknowledged: $data');
      }
    });
  }

  void joinChat(String chatId) {
    if (_socket?.connected ?? false) {
      if (kDebugMode) {
        print('Joining chat: $chatId');
      }
      _socket!.emit('join_chat', chatId);
    } else {
      if (kDebugMode) {
        print('Socket not connected, cannot join chat');
      }
    }
  }

  void leaveChat(String chatId) {
    if (_socket?.connected ?? false) {
      _socket!.emit('leave_chat', chatId);
    }
  }

  void sendMessage(MessageModel message) {
    if (_socket?.connected ?? false) {
      if (kDebugMode) {
        print('Sending message via socket: ${message.toJson()}');
      }
      _socket!.emit('send_message', message.toJson());
    } else {
      if (kDebugMode) {
        print('Socket not connected, message not sent via socket');
      }
    }
  }

  void disconnect() {
    _isConnecting = false;
    _socket?.disconnect();
    _socket?.clearListeners();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}