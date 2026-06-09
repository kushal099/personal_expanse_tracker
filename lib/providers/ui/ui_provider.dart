import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state notifier for managing loading and error states
final uiStateProvider = StateNotifierProvider<UiStateNotifier, UiState>(
  (ref) => UiStateNotifier(),
);

class UiState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const UiState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  UiState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return UiState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  void clearMessages() {
    // Used to clear error/success messages
  }
}

class UiStateNotifier extends StateNotifier<UiState> {
  UiStateNotifier() : super(const UiState());

  void setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  void setSuccess(String message) {
    state = state.copyWith(successMessage: message, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  void clearAllMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
