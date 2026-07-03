import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_arc/features/auth/domain/models/user_profile.dart';
import 'package:fluent_arc/features/auth/domain/repositories/auth_repository.dart';
import 'package:fluent_arc/features/auth/presentation/view_models/auth_view_model.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Default mock behavior
    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) => Future.value(null));

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier Tests', () {
    test('initial state is unauthenticated if no user is logged in', () async {
      // Read first to trigger build() and initialization
      final initialState = container.read(authNotifierProvider);
      expect(initialState.status, equals(AuthStatus.loading));

      // Wait for the async getCurrentUser to resolve
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
    });

    test(
      'initial state is authenticated if a user is already logged in',
      () async {
        const user = UserProfile(
          uid: '123',
          email: 'test@example.com',
          displayName: 'Test',
        );
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenAnswer((_) => Future.value(user));

        // Read to trigger build()
        final initialState = container.read(authNotifierProvider);
        expect(initialState.status, equals(AuthStatus.loading));

        // Wait for async init to complete
        await Future.delayed(const Duration(milliseconds: 10));

        final state = container.read(authNotifierProvider);
        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.user?.uid, equals('123'));
      },
    );

    test('login success sets status to authenticated', () async {
      const user = UserProfile(
        uid: '123',
        email: 'test@example.com',
        displayName: 'Test',
      );
      when(
        () => mockAuthRepository.signInWithEmailPassword(
          'test@example.com',
          'password123',
        ),
      ).thenAnswer((_) => Future.value(user));

      final notifier = container.read(authNotifierProvider.notifier);

      // Let initial load finish
      await Future.delayed(const Duration(milliseconds: 10));

      await notifier.login('test@example.com', 'password123');

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.authenticated));
      expect(state.user?.uid, equals('123'));
    });

    test('login failure sets status to error with message', () async {
      when(
        () => mockAuthRepository.signInWithEmailPassword(
          'test@example.com',
          'bad_pass',
        ),
      ).thenThrow(Exception('Invalid credentials'));

      final notifier = container.read(authNotifierProvider.notifier);

      // Let initial load finish
      await Future.delayed(const Duration(milliseconds: 10));

      await notifier.login('test@example.com', 'bad_pass');

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.error));
      expect(state.errorMessage, equals('Invalid credentials'));
    });

    test('logout sets status to unauthenticated', () async {
      when(
        () => mockAuthRepository.signOut(),
      ).thenAnswer((_) => Future.value());

      final notifier = container.read(authNotifierProvider.notifier);

      // Let initial load finish
      await Future.delayed(const Duration(milliseconds: 10));

      await notifier.logout();

      final state = container.read(authNotifierProvider);
      expect(state.status, equals(AuthStatus.unauthenticated));
    });
  });
}
