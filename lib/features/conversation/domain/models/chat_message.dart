import 'package:uuid/uuid.dart';

enum MessageSender { user, ai }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.create({
    required MessageSender sender,
    required String text,
  }) {
    return ChatMessage(
      id: const Uuid().v4(),
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? const Uuid().v4(),
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => MessageSender.user,
      ),
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
