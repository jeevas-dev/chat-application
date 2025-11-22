
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/chat_repository.dart';
import '../models/message_model.dart';

class ChatDetailViewModel extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository repository;

  ChatDetailViewModel({required this.repository}) : super(ChatDetailInitial()) {
    on<ChatMessagesLoaded>(_onChatMessagesLoaded);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
  }

  Future<void> _onChatMessagesLoaded(
    ChatMessagesLoaded event,
    Emitter<ChatDetailState> emit,
  ) async {
    emit(ChatDetailLoading());
    
    final response = await repository.getChatMessages(event.chatId);

    if (response.data != null) {
      emit(ChatDetailSuccess(messages: response.data!));
    } else {
      emit(ChatDetailFailure(error: response.error));
    }
  }

  Future<void> _onMessageSent(
    MessageSent event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is ChatDetailSuccess) {
      final currentState = state as ChatDetailSuccess;
      
      // Add temporary message immediately for better UX
      final temporaryMessage = MessageModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        chatId: event.message.chatId,
        senderId: event.message.senderId,
        content: event.message.content,
        messageType: event.message.messageType,
        fileUrl: event.message.fileUrl,
        timestamp: DateTime.now(),
      );

      emit(ChatDetailSuccess(
        messages: [...currentState.messages, temporaryMessage],
      ));

      // Send message via repository (which handles both HTTP and Socket)
      final response = await repository.sendMessage(event.message);

      if (response.data == null) {
        // If failed, remove temporary message and show error
        emit(ChatDetailFailure(error: response.error));
        // Restore previous messages
        emit(ChatDetailSuccess(messages: currentState.messages));
      }
      // If successful, the socket will receive the message and update via MessageReceived event
    }
  }

  void _onMessageReceived(
    MessageReceived event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (state is ChatDetailSuccess) {
      final currentState = state as ChatDetailSuccess;
      final messages = currentState.messages;
      
      // Check if message already exists (to avoid duplicates)
      final messageExists = messages.any((msg) => msg.id == event.message.id);
      
      if (!messageExists) {
        // Replace temporary message with real one if exists
        final temporaryMessageIndex = messages.indexWhere(
          (msg) => msg.id.startsWith('temp-') && msg.content == event.message.content
        );
        
        List<MessageModel> updatedMessages;
        if (temporaryMessageIndex != -1) {
          updatedMessages = List<MessageModel>.from(messages);
          updatedMessages[temporaryMessageIndex] = event.message;
        } else {
          updatedMessages = [...messages, event.message];
        }
        
        // Sort by timestamp
        updatedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        
        emit(ChatDetailSuccess(messages: updatedMessages));
      }
    }
  }
}

// chat_detail_event.dart
abstract class ChatDetailEvent {}

class ChatMessagesLoaded extends ChatDetailEvent {
  final String chatId;

  ChatMessagesLoaded({required this.chatId});
}

class MessageSent extends ChatDetailEvent {
  final MessageModel message;

  MessageSent({required this.message});
}

class MessageReceived extends ChatDetailEvent {
  final MessageModel message;

  MessageReceived({required this.message});
}

// chat_detail_state.dart
abstract class ChatDetailState {}

class ChatDetailInitial extends ChatDetailState {}

class ChatDetailLoading extends ChatDetailState {}

class ChatDetailSuccess extends ChatDetailState {
  final List<MessageModel> messages;

  ChatDetailSuccess({required this.messages});
}

class ChatDetailFailure extends ChatDetailState {
  final String error;

  ChatDetailFailure({required this.error});
}