import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/conversation_repository.dart';

class SupabaseConversationRepository implements ConversationRepository {
  final SupabaseClient? _supabaseClient;
  final bool _isBackendEnabled;

  // Local fallback history for offline mode
  final Map<String, List<ChatMessage>> _localHistory = {};

  SupabaseConversationRepository({
    SupabaseClient? supabaseClient,
    bool isBackendEnabled = true,
  }) : _supabaseClient = supabaseClient,
       _isBackendEnabled = isBackendEnabled;

  @override
  Future<List<ChatMessage>> getMessages(String userId) async {
    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final response = await _supabaseClient
            .from('conversations')
            .select()
            .eq('user_id', userId)
            .order('timestamp', ascending: true);

        return (response as List)
            .map((data) => ChatMessage.fromJson(data))
            .toList();
      } catch (e) {
        return _localHistory[userId] ?? [];
      }
    } else {
      return _localHistory[userId] ?? [];
    }
  }

  @override
  Future<void> saveMessage(String userId, ChatMessage message) async {
    // Add to local history list first as local sync cache
    _localHistory.putIfAbsent(userId, () => []).add(message);

    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final data = message.toJson();
        data['user_id'] = userId; // Add relation ID
        await _supabaseClient.from('conversations').upsert(data);
      } catch (_) {
        // Retain local cache
      }
    }
  }

  @override
  Future<void> clearHistory(String userId) async {
    _localHistory[userId]?.clear();

    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        await _supabaseClient
            .from('conversations')
            .delete()
            .eq('user_id', userId);
      } catch (_) {
        // Fallback handled locally
      }
    }
  }
}
