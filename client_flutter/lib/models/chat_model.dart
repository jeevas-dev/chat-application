
class ChatModel {
  final String id;
  final bool isGroupChat;
  final List<dynamic> participants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LastMessage? lastMessage;

  ChatModel({
    required this.id,
    required this.isGroupChat,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      isGroupChat: json['isGroupChat'] ?? false,
      participants: json['participants'] ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['lastMessage'] != null 
          ? LastMessage.fromJson(json['lastMessage'])
          : null,
    );
  }

  // Helper method to get other participant's name
  String getOtherParticipantName(String currentUserId) {
    if (participants.isEmpty) return 'Unknown User';
    
    for (var participant in participants) {
      if (participant is Map<String, dynamic>) {
        final participantId = participant['_id'] ?? '';
        if (participantId != currentUserId) {
          return participant['name'] ?? 'Unknown User';
        }
      }
    }
    return 'Unknown User';
  }

  // Helper method to get other participant's profile
  String? getOtherParticipantProfile(String currentUserId) {
    if (participants.isEmpty) return null;
    
    for (var participant in participants) {
      if (participant is Map<String, dynamic>) {
        final participantId = participant['_id'] ?? '';
        if (participantId != currentUserId) {
          return participant['profile'];
        }
      }
    }
    return null;
  }
}

class LastMessage {
  final String id;
  final String senderId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final DateTime createdAt;

  LastMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.fileUrl,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      fileUrl: json['fileUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

