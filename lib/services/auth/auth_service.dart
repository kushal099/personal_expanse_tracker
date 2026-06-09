import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_service.dart';

/// Authentication service for handling user authentication
/// Wraps Supabase Authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  late final SupabaseClient _supabase = SupabaseService.client;

  /// Sign up user with email and password
  Future<AuthResponse> signup(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Login user with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['avatar_url'] = photoUrl;

      if (updates.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(data: updates));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _supabase.auth.currentUser != null;
  }

  /// Get auth state stream
  Stream<AuthState> get authStateStream => _supabase.auth.onAuthStateChange;

  /// Restore session from stored token
  Future<bool> restoreSession() async {
    try {
      // Supabase automatically restores session from storage
      // If there's a valid session, it will be available
      return isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Get current session
  Session? getSession() {
    return _supabase.auth.currentSession;
  }
}
