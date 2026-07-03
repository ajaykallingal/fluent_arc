import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/features/conversation/domain/models/chat_message.dart';
import 'package:fluent_arc/features/conversation/domain/repositories/conversation_repository.dart';
import 'package:fluent_arc/features/conversation/presentation/view_models/conversation_view_model.dart';
import 'package:fluent_arc/features/auth/domain/models/user_profile.dart';
import 'package:fluent_arc/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:fluent_arc/core/services/ai/ai_provider.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

class MockAiProvider extends Mock implements AiProvider {}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState fakeState;

  FakeAuthNotifier(this.fakeState);

  @override
  AuthState build() {
    return fakeState;
  }
}

void main() {
  late MockConversationRepository mockConversationRepository;
  late MockAiProvider mockAiProvider;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      ChatMessage.create(sender: MessageSender.user, text: ''),
    );
    registerFallbackValue(AiChatMessage(role: 'user', text: ''));
  });

  setUp(() {
    mockConversationRepository = MockConversationRepository();
    mockAiProvider = MockAiProvider();

    // Mock responses
    when(
      () => mockConversationRepository.getMessages(any()),
    ).thenAnswer((_) => Future.value([]));
    when(
      () => mockConversationRepository.saveMessage(any(), any()),
    ).thenAnswer((_) => Future.value());

    container = ProviderContainer(
      overrides: [
        conversationRepositoryProvider.overrideWithValue(
          mockConversationRepository,
        ),
        aiProvider.overrideWithValue(mockAiProvider),
        // Overrides auth state to be pre-authenticated
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              user: UserProfile(
                uid: 'user-123',
                email: 'test@example.com',
                displayName: 'Test User',
              ),
            ),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ConversationNotifier Tests', () {
    test(
      'initial load with empty history saves and returns a welcome message',
      () async {
        final state = container.read(conversationNotifierProvider);
        expect(state.messages, isEmpty);

        // Wait for initial load microtask
        await Future.delayed(const Duration(milliseconds: 10));

        final updatedState = container.read(conversationNotifierProvider);
        expect(updatedState.messages.length, equals(1));
        expect(updatedState.messages.first.sender, equals(MessageSender.ai));
        expect(updatedState.messages.first.text, contains('AI English tutor'));

        verify(
          () => mockConversationRepository.saveMessage('user-123', any()),
        ).called(1);
      },
    );

    test(
      'sendMessage triggers AI tutor response and updates state list',
      () async {
        when(
          () => mockAiProvider.generateChatResponse(any(), any()),
        ).thenAnswer((_) => Future.value('I am doing great!'));

        // 1. Trigger initialization by reading the state first
        final initialState = container.read(conversationNotifierProvider);
        expect(initialState.messages, isEmpty);

        // 2. Wait for initial welcome message load to complete
        await Future.delayed(const Duration(milliseconds: 10));

        final notifier = container.read(conversationNotifierProvider.notifier);
        await notifier.sendMessage('Hello, how are you?');

        final finalState = container.read(conversationNotifierProvider);
        expect(finalState.errorMessage, isNull);
        expect(
          finalState.messages.length,
          equals(3),
        ); // 1 welcome + 1 user + 1 AI
        expect(finalState.messages[1].text, equals('Hello, how are you?'));
        expect(finalState.messages[2].text, equals('I am doing great!'));
        expect(finalState.isTyping, isFalse);

        verify(
          () => mockConversationRepository.saveMessage('user-123', any()),
        ).called(3);
      },
    );
  });
}
