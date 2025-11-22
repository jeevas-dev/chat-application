
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/chat_repository.dart';
import '../models/chat_model.dart';

// part 'chat_list_event.dart';
// part 'chat_list_state.dart';

class ChatListViewModel extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository repository;

  ChatListViewModel({required this.repository}) : super(ChatListInitial()) {
    on<ChatListLoaded>(_onChatListLoaded);
  }

  Future<void> _onChatListLoaded(
    ChatListLoaded event,
    Emitter<ChatListState> emit,
  ) async {
    emit(ChatListLoading());
    
    final response = await repository.getUserChats(event.userId);

    if (response.data != null) {
      emit(ChatListSuccess(chats: response.data!));
    } else {
      emit(ChatListFailure(error: response.error));
    }
  }
}

// chat_list_event.dart
// part of 'chat_list_view_model.dart';

abstract class ChatListEvent {}

class ChatListLoaded extends ChatListEvent {
  final String userId;

  ChatListLoaded({required this.userId});
}

// chat_list_state.dart
// part of 'chat_list_view_model.dart';

abstract class ChatListState {}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListSuccess extends ChatListState {
  final List<ChatModel> chats;

  ChatListSuccess({required this.chats});
}

class ChatListFailure extends ChatListState {
  final String error;

  ChatListFailure({required this.error});
}