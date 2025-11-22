
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/chat_repository.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

// part 'login_event.dart';
// part 'login_state.dart';

class LoginViewModel extends Bloc<LoginEvent, LoginState> {
  final ChatRepository repository;

  LoginViewModel({required this.repository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    
    try {
      final response = await repository.login(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      if (response.data != null) {
        // Save user data to SharedPreferences
        await UserService.saveUser(response.data!);
        emit(LoginSuccess(user: response.data!));
      } else {
        emit(LoginFailure(error: response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(LoginFailure(error: 'An error occurred during login: $e'));
    }
  }
}

// login_event.dart
// part of 'login_view_model.dart';

abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final String role;

  LoginSubmitted({
    required this.email,
    required this.password,
    required this.role,
  });
}



abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final UserModel user;

  LoginSuccess({required this.user});
}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure({required this.error});
}