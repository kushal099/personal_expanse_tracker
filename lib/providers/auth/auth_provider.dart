import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth/auth_service.dart';

const localUserId = 'local_android_user';
const localUserEmail = 'Local Android User';

/// State class for authentication
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? userEmail;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.userId,
    this.userEmail,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage,
    );
  }
}

/// Riverpod provider for authentication state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication on startup
  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      // Restore session from storage
      final restored = await _authService.restoreSession();
      if (restored) {
        final userId = _authService.getCurrentUserId();
        final userEmail = _authService.getCurrentUserEmail();
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          userId: userId,
          userEmail: userEmail,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to restore session: $e',
      );
    }
  }

  /// Login user with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.login(email, password);
      final userId = _authService.getCurrentUserId();
      final userEmail = _authService.getCurrentUserEmail();
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        userId: userId,
        userEmail: userEmail,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Sign up user with email and password
  Future<bool> signup(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signup(email, password);
      // After signup, user may need to verify email
      // For now, attempt to auto-login
      await _authService.login(email, password);
      final userId = _authService.getCurrentUserId();
      final userEmail = _authService.getCurrentUserEmail();
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        userId: userId,
        userEmail: userEmail,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
      state = const AuthState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Reset password for email
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

/// Derived provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

/// Derived provider to get current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isAuthenticated &&
      authState.userId != null &&
      authState.userId!.isNotEmpty) {
    return authState.userId;
  }
  return localUserId;
});

/// Derived provider to get current user email
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.isAuthenticated &&
      authState.userEmail != null &&
      authState.userEmail!.isNotEmpty) {
    return authState.userEmail;
  }
  return localUserEmail;
});
