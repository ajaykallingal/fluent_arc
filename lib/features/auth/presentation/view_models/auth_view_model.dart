import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

final supabaseClientProvider = Provider<supabase.SupabaseClient?>((ref) {
  try {
    return supabase.Supabase.instance.client;
  } catch (e) {
    return null;
  }
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isBackendEnabled = supabaseClient != null;
  return SupabaseAuthRepository(
    supabaseClient: supabaseClient,
    isBackendEnabled: isBackendEnabled,
  );
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserProfile user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  StreamSubscription<UserProfile?>? _subscription;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);

    // Setup listener to auth state changes
    _subscription = _authRepository.authStateChanges.listen(
      (user) {
        if (ref.mounted) {
          if (user != null) {
            state = AuthState.authenticated(user);
          } else {
            // Only transition to unauthenticated if we were previously logged in
            if (state.status == AuthStatus.authenticated ||
                state.status == AuthStatus.initial) {
              state = AuthState.unauthenticated();
            }
          }
        }
      },
      onError: (e) {
        if (ref.mounted) {
          state = AuthState.error(e.toString());
        }
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    _loadInitialUser();

    return AuthState.loading();
  }

  void _loadInitialUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (ref.mounted) {
        state = user != null
            ? AuthState.authenticated(user)
            : AuthState.unauthenticated();
      }
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.unauthenticated();
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _authRepository.signInWithEmailPassword(
        email,
        password,
      );
      if (ref.mounted) {
        state = AuthState.authenticated(user);
      }
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> signUp(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _authRepository.signUpWithEmailPassword(
        email,
        password,
      );
      if (ref.mounted) {
        state = AuthState.authenticated(user);
      }
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await _authRepository.signOut();
      if (ref.mounted) {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      if (ref.mounted) {
        state = AuthState.error(e.toString());
      }
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
