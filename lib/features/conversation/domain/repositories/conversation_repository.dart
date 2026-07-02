import '../models/chat_message.dart';

abstract class ConversationRepository {
  Future<List<ChatMessage>> getMessages(String userId);

  Future<void> saveMessage(String userId, ChatMessage message);

  Future<void> clearHistory(String userId);
}
