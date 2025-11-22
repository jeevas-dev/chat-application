
import 'dart:convert';
import 'package:client_flutter/models/chat_model.dart';
import 'package:client_flutter/models/user_model.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';
import '../models/message_model.dart';

class ApiResponse<T> {
  final T? data;
  final String error;

  ApiResponse({this.data, this.error = ''});
}

class ChatRepository {
  static const String baseUrl = 'http://45.129.87.38:6065/';
  final SocketService socketService = SocketService();

  final http.Client client;

  ChatRepository({required this.client});

  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('${baseUrl}user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        UserModel user;
        String? token;

        if (jsonResponse['encrypted'] == true) {
          final data = jsonResponse['data'];
          final userData = data['user'];
          token = data['token'];
          userData['token'] = token;
          user = UserModel.fromJson(userData);
        } else {
          user = UserModel.fromJson(jsonResponse);
          token = jsonResponse['token'];
        }

        // Connect to socket after successful login with token
        if (token != null && token.isNotEmpty) {
          socketService.connect(token);
        }
        
        return ApiResponse(data: user);
      } else {
        final errorData = jsonDecode(response.body);
        return ApiResponse(error: errorData['message'] ?? 'Login failed: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Login error: $e');
    }
  }

  Future<ApiResponse<List<ChatModel>>> getUserChats(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('${baseUrl}chats/user-chats/$userId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> chatsJson = jsonResponse is List ? jsonResponse : [];
        final chats = chatsJson.map((json) => ChatModel.fromJson(json)).toList();
        return ApiResponse(data: chats);
      } else {
        return ApiResponse(error: 'Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Error loading chats: $e');
    }
  }

  Future<ApiResponse<List<MessageModel>>> getChatMessages(String chatId) async {
    try {
      final response = await client.get(
        Uri.parse('${baseUrl}messages/get-messagesformobile/$chatId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> messagesJson = jsonResponse is List ? jsonResponse : [];
        final messages = messagesJson.map((json) => MessageModel.fromJson(json)).toList();
        
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        return ApiResponse(data: messages);
      } else {
        return ApiResponse(error: 'Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Error loading messages: $e');
    }
  }

  Future<ApiResponse<MessageModel>> sendMessage(MessageModel message) async {
    try {
     
      final response = await client.post(
        Uri.parse('${baseUrl}messages/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final sentMessage = MessageModel.fromJson(jsonResponse);
        
       
        socketService.sendMessage(sentMessage);
        
        return ApiResponse(data: sentMessage);
      } else {
        return ApiResponse(error: 'Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse(error: 'Error sending message: $e');
    }
  }

  void dispose() {
    socketService.disconnect();
  }
}