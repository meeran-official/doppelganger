class ConversationMessage {
  final int? id;
  final int? sessionId;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? category;
  final String? context;

  ConversationMessage({
    this.id,
    this.sessionId,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.category,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
      'context': context,
    };
  }

  factory ConversationMessage.fromMap(Map<String, dynamic> map) {
    return ConversationMessage(
      id: map['id'],
      sessionId: map['sessionId'],
      message: map['message'],
      isUser: map['isUser'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      category: map['category'],
      context: map['context'],
    );
  }
}

class ConversationSession {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final List<ConversationMessage> messages;

  ConversationSession({
    this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.messages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
    };
  }

  factory ConversationSession.fromMap(Map<String, dynamic> map) {
    return ConversationSession(
      id: map['id'],
      title: map['title'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
    );
  }
}
