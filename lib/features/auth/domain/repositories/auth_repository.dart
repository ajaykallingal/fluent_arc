import '../models/user_profile.dart';

abstract class AuthRepository {
  Stream<UserProfile?> get authStateChanges;
  
  Future<UserProfile?> getCurrentUser();

  Future<UserProfile> signInWithEmailPassword(String email, String password);

  Future<UserProfile> signUpWithEmailPassword(String email, String password);

  Future<void> signOut();
}
