import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai/ai_provider.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/repositories/supabase_conversation_repository.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/conversation_repository.dart';

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isBackendEnabled = supabaseClient != null;
  return SupabaseConversationRepository(
    supabaseClient: supabaseClient,
    isBackendEnabled: isBackendEnabled,
  );
});

class ConversationState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;

  const ConversationState({
    required this.messages,
    required this.isTyping,
    this.errorMessage,
  });

  factory ConversationState.initial() => const ConversationState(messages: [], isTyping: false);

  ConversationState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConversationNotifier extends Notifier<ConversationState> {
  late final ConversationRepository _repository;
  late final AiProvider _aiProvider;
  String? _userId;

  @override
  ConversationState build() {
    _repository = ref.watch(conversationRepositoryProvider);
    _aiProvider = ref.watch(aiProvider);
    
    final authState = ref.watch(authNotifierProvider);
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      _userId = authState.user!.uid;
      _loadHistory();
    } else {
      _userId = null;
    }

    return ConversationState.initial();
  }

  void _loadHistory() async {
    if (_userId == null) return;
    try {
      final history = await _repository.getMessages(_userId!);
      if (ref.mounted) {
        if (history.isEmpty) {
          // Add a welcoming message from the tutor
          final welcomeMessage = ChatMessage.create(
            sender: MessageSender.ai,
            text: "Hello! I am your AI English tutor. What topic would you like to talk about today?",
          );
          await _repository.saveMessage(_userId!, welcomeMessage);
          state = ConversationState(messages: [welcomeMessage], isTyping: false);
        } else {
          state = ConversationState(messages: history, isTyping: false);
        }
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(errorMessage: e.toString());
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (_userId == null || text.trim().isEmpty || state.isTyping) return;

    final userMessage = ChatMessage.create(
      sender: MessageSender.user,
      text: text.trim(),
    );

    // Save locally and update UI state
    await _repository.saveMessage(_userId!, userMessage);
    final updatedList = List<ChatMessage>.from(state.messages)..add(userMessage);
    state = state.copyWith(messages: updatedList, isTyping: true, errorMessage: null);

    try {
      // Convert history to AI chat message format
      final historyPrompts = state.messages.map((msg) {
        return AiChatMessage(
          role: msg.sender == MessageSender.user ? 'user' : 'model',
          text: msg.text,
        );
      }).toList();

      // Get tutor response
      final aiResponse = await _aiProvider.generateChatResponse(historyPrompts, text);

      final aiMessage = ChatMessage.create(
        sender: MessageSender.ai,
        text: aiResponse,
      );

      await _repository.saveMessage(_userId!, aiMessage);
      
      if (ref.mounted) {
        final finalHistory = List<ChatMessage>.from(state.messages)..add(aiMessage);
        state = state.copyWith(messages: finalHistory, isTyping: false);
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isTyping: false,
          errorMessage: 'Failed to reach AI Tutor. Please try again.',
        );
      }
    }
  }

  Future<void> clearChat() async {
    if (_userId == null) return;
    state = state.copyWith(isTyping: true);
    await _repository.clearHistory(_userId!);
    
    if (ref.mounted) {
      final welcomeMessage = ChatMessage.create(
        sender: MessageSender.ai,
        text: "Hello! I've cleared our chat history. What would you like to speak about now?",
      );
      await _repository.saveMessage(_userId!, welcomeMessage);
      state = ConversationState(messages: [welcomeMessage], isTyping: false);
    }
  }
}

final conversationNotifierProvider = NotifierProvider<ConversationNotifier, ConversationState>(() {
  return ConversationNotifier();
});
