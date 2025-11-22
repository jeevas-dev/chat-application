// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'repository/chat_repository.dart';
import 'view_models/login_view_model.dart';
import 'view_models/chat_list_view_model.dart';
import 'view_models/chat_detail_view_model.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final chatRepository = ChatRepository(client: http.Client());

    return RepositoryProvider<ChatRepository>(
      create: (context) => chatRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LoginViewModel>(
            create: (context) => LoginViewModel(repository: chatRepository),
          ),
          BlocProvider<ChatListViewModel>(
            create: (context) => ChatListViewModel(repository: chatRepository),
          ),
          BlocProvider<ChatDetailViewModel>(
            create: (context) => ChatDetailViewModel(repository: chatRepository),
          ),
        ],
        child: MaterialApp(
          title: 'Chat App',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}