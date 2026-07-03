import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient? _supabaseClient;
  final bool _isBackendEnabled;

  // In-memory fallback fields for offline mode
  final StreamController<UserProfile?> _fallbackController =
      StreamController<UserProfile?>.broadcast();
  UserProfile? _currentFallbackUser;

  SupabaseAuthRepository({
    supabase.SupabaseClient? supabaseClient,
    bool isBackendEnabled = true,
  }) : _supabaseClient = supabaseClient,
       _isBackendEnabled = isBackendEnabled {
    if (!_isBackendEnabled) {
      _fallbackController.add(null);
    }
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    if (_isBackendEnabled && _supabaseClient != null) {
      return _supabaseClient.auth.onAuthStateChange.map((authState) {
        final user = authState.session?.user;
        if (user == null) return null;
        return UserProfile(
          uid: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'],
          photoUrl: user.userMetadata?['avatar_url'],
        );
      });
    } else {
      return _fallbackController.stream;
    }
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (_isBackendEnabled && _supabaseClient != null) {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) return null;
      return UserProfile(
        uid: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'],
        photoUrl: user.userMetadata?['avatar_url'],
      );
    } else {
      return _currentFallbackUser;
    }
  }

  @override
  Future<UserProfile> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final response = await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = response.user!;
        return UserProfile(
          uid: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'],
          photoUrl: user.userMetadata?['avatar_url'],
        );
      } on supabase.AuthException catch (e) {
        throw Exception(e.message);
      } catch (e) {
        throw Exception('An error occurred during sign in.');
      }
    } else {
      // Mock login for offline mode
      await Future.delayed(const Duration(milliseconds: 800));
      if (password == 'password123') {
        final user = UserProfile(
          uid: 'mock-uid-12345',
          email: email,
          displayName: email.split('@')[0],
        );
        _currentFallbackUser = user;
        _fallbackController.add(user);
        return user;
      } else {
        throw Exception('Invalid credentials. (Hint: use password123)');
      }
    }
  }

  @override
  Future<UserProfile> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    if (_isBackendEnabled && _supabaseClient != null) {
      try {
        final response = await _supabaseClient.auth.signUp(
          email: email,
          password: password,
        );
        final user = response.user!;
        return UserProfile(
          uid: user.id,
          email: user.email ?? '',
          displayName: user.userMetadata?['full_name'],
          photoUrl: user.userMetadata?['avatar_url'],
        );
      } on supabase.AuthException catch (e) {
        throw Exception(e.message);
      } catch (e) {
        throw Exception('An error occurred during sign up.');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 800));
      final user = UserProfile(
        uid: 'mock-uid-12345',
        email: email,
        displayName: email.split('@')[0],
      );
      _currentFallbackUser = user;
      _fallbackController.add(user);
      return user;
    }
  }

  @override
  Future<void> signOut() async {
    if (_isBackendEnabled && _supabaseClient != null) {
      await _supabaseClient.auth.signOut();
    } else {
      _currentFallbackUser = null;
      _fallbackController.add(null);
    }
  }
}
