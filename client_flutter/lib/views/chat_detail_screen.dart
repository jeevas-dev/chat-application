import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../view_models/chat_detail_view_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../repository/chat_repository.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final UserModel currentUser;
  final String chatTitle;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.currentUser,
    required this.chatTitle,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late ChatRepository _repository;
  final List<MessageModel> _messages = [];

  @override
  void initState() {
    super.initState();
    _repository = RepositoryProvider.of<ChatRepository>(context, listen: false);
    _setupSocketListeners();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatDetailViewModel>().add(ChatMessagesLoaded(chatId: widget.chatId));
      _repository.socketService.joinChat(widget.chatId);
    });
  }

  void _setupSocketListeners() {
    _repository.socketService.onMessageReceived = (MessageModel message) {
      if (message.chatId == widget.chatId) {
        final existingIndex = _messages.indexWhere((m) => m.id == message.id);
        if (existingIndex == -1) {
          setState(() {
            _messages.add(message);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          _scrollToBottom();
        }
      }
    };

    _repository.socketService.onConnected = () {
      _repository.socketService.joinChat(widget.chatId);
    };
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final message = MessageModel(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chatId,
      senderId: widget.currentUser.id,
      content: content,
      messageType: 'text',
      fileUrl: null,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });
    _messageController.clear();
    _scrollToBottom();

    context.read<ChatDetailViewModel>().add(MessageSent(message: message));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _repository.socketService.leaveChat(widget.chatId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.currentUser.role.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _repository.socketService.isConnected 
                  ? Colors.green 
                  : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _repository.socketService.isConnected 
                      ? Icons.circle 
                      : Icons.circle_outlined,
                  size: 8,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _repository.socketService.isConnected ? 'Live' : 'Offline',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatDetailViewModel, ChatDetailState>(
              listener: (context, state) {
                if (state is ChatDetailSuccess) {
                  setState(() {
                    _messages.clear();
                    _messages.addAll(state.messages);
                  });
                  _scrollToBottom();
                } else if (state is ChatDetailFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is ChatDetailLoading && _messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  );
                }

                if (_messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isMe = message.senderId == widget.currentUser.id;
                    final isTemporary = message.id.startsWith('temp-');
                    final isLastMessage = index == _messages.length - 1;

                    return Container(
                      margin: EdgeInsets.only(bottom: isLastMessage ? 0 : 8),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                widget.chatTitle.isNotEmpty 
                                    ? widget.chatTitle[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe 
                                    ? const Color(0xFF2563EB)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (isTemporary) ...[
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              isMe ? Colors.white70 : Colors.grey[600]!,
                                            ),
                                          ),
                                        ),
                                      ] else if (isMe) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.done_all,
                                          size: 12,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: widget.currentUser.profile != null
                                  ? NetworkImage('${ChatRepository.baseUrl}${widget.currentUser.profile!}')
                                  : null,
                              child: widget.currentUser.profile == null
                                  ? Text(
                                      widget.currentUser.name.isNotEmpty 
                                          ? widget.currentUser.name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 15),
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}