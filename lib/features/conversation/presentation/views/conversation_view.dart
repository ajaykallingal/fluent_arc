import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/loading_view.dart';
import '../view_models/conversation_view_model.dart';
import '../../domain/models/chat_message.dart';

class ConversationView extends ConsumerStatefulWidget {
  const ConversationView({super.key});

  @override
  ConsumerState<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends ConsumerState<ConversationView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(conversationNotifierProvider.notifier).sendMessage(text);
    _textController.clear();
    // Delay scroll slightly to wait for list to rebuild with new user message
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(conversationNotifierProvider);

    // Auto-scroll on new message received
    ref.listen<ConversationState>(conversationNotifierProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Chat History?'),
                  content: const Text('This will delete all past tutor messages in this session.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(conversationNotifierProvider.notifier).clearChat();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat log list
          Expanded(
            child: chatState.messages.isEmpty && chatState.isTyping
                ? const LoadingView(message: 'Starting conversation...')
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatState.messages.length) {
                        return _buildTypingIndicator(theme);
                      }
                      
                      final message = chatState.messages[index];
                      return _buildMessageBubble(theme, message);
                    },
                  ),
          ),

          // Error banner if exists
          if (chatState.errorMessage != null)
            Container(
              color: theme.colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // Input control box
          _buildInputArea(theme, chatState.isTyping),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant;
    final textColor = isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;
    final borderRadius = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatTime(message.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tutor is typing...',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isTyping) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Voice simulation quick action
          IconButton(
            icon: Icon(Icons.mic, color: theme.colorScheme.secondary),
            tooltip: 'Simulate Voice (Accent Coach)',
            onPressed: isTyping
                ? null
                : () {
                    // Navigate to Accent Coach
                    context.push('/accent');
                  },
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.brightness == Brightness.dark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
            onPressed: isTyping ? null : _submit,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
