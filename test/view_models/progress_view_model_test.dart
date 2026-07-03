import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/features/progress/domain/models/user_progress.dart';
import 'package:fluent_arc/features/progress/domain/repositories/progress_repository.dart';
import 'package:fluent_arc/features/progress/presentation/view_models/progress_view_model.dart';
import 'package:fluent_arc/features/auth/domain/models/user_profile.dart';
import 'package:fluent_arc/features/auth/presentation/view_models/auth_view_model.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

class FakeAuthNotifier extends AuthNotifier {
  final AuthState fakeState;

  FakeAuthNotifier(this.fakeState);

  @override
  AuthState build() {
    return fakeState;
  }
}

void main() {
  late MockProgressRepository mockProgressRepository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(
      UserProgress(
        uid: '',
        lessonsCompleted: 0,
        grammarScoreAverage: 0.0,
        vocabularyLearnedCount: 0,
        speakingSessionsCount: 0,
        streakDays: 0,
        lastActiveDate: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockProgressRepository = MockProgressRepository();

    // Default mock response
    final initialProgress = UserProgress.initial('user-123');
    when(
      () => mockProgressRepository.getUserProgress('user-123'),
    ).thenAnswer((_) => Future.value(initialProgress));
    when(
      () => mockProgressRepository.saveUserProgress(any()),
    ).thenAnswer((_) => Future.value());
    when(
      () => mockProgressRepository.incrementSpeakingSession(any()),
    ).thenAnswer((_) => Future.value());
    when(
      () => mockProgressRepository.updateGrammarScore(any(), any()),
    ).thenAnswer((_) => Future.value());

    container = ProviderContainer(
      overrides: [
        progressRepositoryProvider.overrideWithValue(mockProgressRepository),
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

  group('ProgressNotifier Tests', () {
    test('initial state loads user progress from database', () async {
      // Trigger build and initial fetch
      container.read(progressNotifierProvider);

      // Wait for microtask async fetch
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(progressNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.progress?.uid, equals('user-123'));
      expect(state.progress?.streakDays, equals(3));
      expect(state.progress?.lessonsCompleted, equals(4));
    });

    test(
      'recordSpeakingSession invokes increment and reloads progress',
      () async {
        container.read(progressNotifierProvider);
        await Future.delayed(const Duration(milliseconds: 10));

        final notifier = container.read(progressNotifierProvider.notifier);
        await notifier.recordSpeakingSession();
        await Future.delayed(const Duration(milliseconds: 10));

        verify(
          () => mockProgressRepository.incrementSpeakingSession('user-123'),
        ).called(1);
        verify(
          () => mockProgressRepository.getUserProgress('user-123'),
        ).called(2); // Initial + reload
      },
    );

    test('recordGrammarCheck invokes update and reloads progress', () async {
      container.read(progressNotifierProvider);
      await Future.delayed(const Duration(milliseconds: 10));

      final notifier = container.read(progressNotifierProvider.notifier);
      await notifier.recordGrammarCheck(90.0);
      await Future.delayed(const Duration(milliseconds: 10));

      verify(
        () => mockProgressRepository.updateGrammarScore('user-123', 90.0),
      ).called(1);
      verify(
        () => mockProgressRepository.getUserProgress('user-123'),
      ).called(2);
    });
  });
}
