import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod provider for expense list
final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>(
      (ref) => ExpenseListNotifier(),
    );

class ExpenseListState {
  final List<dynamic> expenses; // TODO: Use Expense model
  final bool isLoading;
  final String? error;

  const ExpenseListState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseListState copyWith({
    List<dynamic>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  ExpenseListNotifier() : super(const ExpenseListState());

  // TODO: Implement fetchExpenses from Firebase
  Future<void> fetchExpenses(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      // Firebase fetch implementation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // TODO: Implement addExpense
  Future<void> addExpense(dynamic expense) async {
    try {
      // Firebase add implementation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // TODO: Implement updateExpense
  Future<void> updateExpense(String id, dynamic expense) async {
    try {
      // Firebase update implementation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // TODO: Implement deleteExpense
  Future<void> deleteExpense(String id) async {
    try {
      // Firebase delete implementation
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

/// Provider to get filtered expenses by category
final filteredExpensesProvider = Provider.family<List<dynamic>, String>((
  ref,
  category,
) {
  final expenses = ref.watch(expenseListProvider).expenses;
  // TODO: Filter expenses by category
  return expenses;
});

/// Provider to get total expenses
final totalExpensesProvider = Provider<double>((ref) {
  // TODO: Calculate total
  return 0.0;
});
