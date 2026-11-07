class ChatMessage {
  final String id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime timestamp;
  final bool isSpeaking;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isSpeaking = false,
    this.isError = false,
  });

  ChatMessage copyWith({
    bool? isSpeaking,
    bool? isError,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content,
      timestamp: timestamp,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isError: isError ?? this.isError,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isSpeaking: false,
      isError: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'created_at': timestamp.toIso8601String(),
    };
  }
}

