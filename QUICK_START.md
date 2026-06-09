# Quick Start Guide - Folder Structure Reference

## 📂 Complete Folder Tree

```
personal_expanse_tracker/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── core.dart (barrel)
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   ├── constants/
│   │   │   └── app_constants.dart
│   │   ├── errors/
│   │   │   └── app_exception.dart
│   │   └── extensions/
│   │       └── extensions.dart
│   │
│   ├── models/
│   │   ├── user/
│   │   │   └── user_model.dart
│   │   ├── expense/
│   │   │   └── expense_model.dart
│   │   ├── receivable/
│   │   │   └── receivable_model.dart
│   │   └── transaction/
│   │
│   ├── services/
│   │   ├── firebase/
│   │   │   └── firebase_service.dart
│   │   ├── auth/
│   │   │   └── auth_service.dart
│   │   └── storage/
│   │       └── storage_service.dart
│   │
│   ├── providers/
│   │   ├── auth/
│   │   │   └── auth_provider.dart
│   │   ├── expense/
│   │   │   └── expense_provider.dart
│   │   ├── ui/
│   │   │   └── ui_provider.dart
│   │   └── theme/
│   │       └── theme_provider.dart
│   │
│   ├── screens/
│   │   ├── screens.dart (barrel)
│   │   ├── dashboard/
│   │   │   ├── dashboard.dart (barrel)
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── dashboard_providers.dart
│   │   │   └── widgets/
│   │   │       └── dashboard_widgets.dart
│   │   ├── expenses/
│   │   │   ├── expenses.dart (barrel)
│   │   │   ├── expenses_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── expenses_providers.dart
│   │   │   └── widgets/
│   │   │       └── expenses_widgets.dart
│   │   ├── analytics/
│   │   │   ├── analytics.dart (barrel)
│   │   │   ├── analytics_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── analytics_providers.dart
│   │   │   └── widgets/
│   │   │       └── analytics_widgets.dart
│   │   ├── receivables/
│   │   │   ├── receivables.dart (barrel)
│   │   │   ├── receivables_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── receivables_providers.dart
│   │   │   └── widgets/
│   │   │       └── receivables_widgets.dart
│   │   └── settings/
│   │       ├── settings.dart (barrel)
│   │       ├── settings_screen.dart
│   │       ├── providers/
│   │       │   └── settings_providers.dart
│   │       └── widgets/
│   │           └── settings_widgets.dart
│   │
│   ├── widgets/
│   │   ├── common/
│   │   │   └── common_widgets.dart
│   │   ├── responsive/
│   │   │   └── responsive_widgets.dart
│   │   └── inputs/
│   │       └── input_widgets.dart
│   │
│   ├── theme/
│   │   └── app_theme.dart
│   │
│   └── utils/
│       ├── formatters/
│       │   └── formatters.dart
│       ├── validators/
│       │   └── validators.dart
│       └── helpers/
│           └── app_helpers.dart
│
├── pubspec.yaml
├── ARCHITECTURE.md
├── PROJECT_STRUCTURE.md
└── QUICK_START.md (this file)
```

---

## 🎯 What Goes Where

### **Adding a New Feature**
```
1. Create model in models/ (if needed)
2. Create service in services/ (if API call needed)
3. Create provider in screens/*/providers/ (screen-specific state)
4. Create widgets in screens/*/widgets/ (screen-specific UI)
5. Implement screen in screens/*/screen.dart
```

### **Adding a Global State**
```
1. Create provider in providers/
2. Create notifier class
3. Watch provider in screens using ref.watch()
```

### **Creating a Utility Function**
```
Choose the right folder:
- formatters/   → Format data (currency, dates, etc.)
- validators/   → Validate input
- helpers/      → General helper functions
```

### **Creating a Reusable Widget**
```
- Common across screens    → widgets/common/
- Specific to one screen   → screens/*/widgets/
- Form inputs              → widgets/inputs/
- Responsive layouts       → widgets/responsive/
```

---

## 📋 Key Files Explained

| File | Purpose |
|------|---------|
| `main.dart` | App entry point, theme setup |
| `core/config/app_config.dart` | Firebase config, app settings |
| `core/constants/app_constants.dart` | Constants, sizing, breakpoints |
| `core/errors/app_exception.dart` | Custom exceptions |
| `core/extensions/extensions.dart` | Extension methods (DateTime, String, etc.) |
| `services/firebase/firebase_service.dart` | Firestore CRUD operations |
| `services/auth/auth_service.dart` | Authentication logic |
| `services/storage/storage_service.dart` | Local storage with SharedPreferences |
| `providers/*/` | Global state management |
| `screens/*/dashboard_screen.dart` | Main screen UI |
| `screens/*/providers/` | Screen state (can access global providers) |
| `screens/*/widgets/` | Screen-specific widgets |
| `theme/app_theme.dart` | Light/dark theme definitions |

---

## 🔑 Naming Conventions

```
Screens:           dashboard_screen.dart
Providers:         dashboard_providers.dart
Widgets:           dashboard_widgets.dart
Models:            user_model.dart
Services:          firebase_service.dart
Constants:         app_constants.dart

Classes:
- Screens:         DashboardScreen (extends ConsumerWidget)
- Providers:       dashboardProvider (StateNotifierProvider)
- Widgets:         DashboardCard, DashboardSummary
- Models:          User, Expense, Receivable
- Services:        FirebaseService, AuthService
- States:          DashboardState, ExpensesListState
- Notifiers:       DashboardNotifier, ExpensesListNotifier
```

---

## 🚀 Common Patterns

### **Watch a Provider in Screen**
```dart
final state = ref.watch(dashboardProvider);
final user = ref.watch(authProvider);
```

### **Update State from Button**
```dart
ElevatedButton(
  onPressed: () => ref.read(dashboardProvider.notifier).refresh('userId'),
  child: const Text('Refresh'),
)
```

### **Create Derived Provider**
```dart
final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseListProvider);
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
});
```

### **Handle Loading/Error States**
```dart
final state = ref.watch(myProvider);
if (state.isLoading) {
  return const LoadingIndicator();
} else if (state.error != null) {
  return ErrorWidget(message: state.error!);
} else {
  return ListView.builder(...);
}
```

### **Use Responsive Widget**
```dart
ResponsiveWidget(
  mobile: SizedBox(height: 200, child: MobileChart()),
  tablet: SizedBox(height: 300, child: TabletChart()),
  desktop: SizedBox(height: 400, child: DesktopChart()),
)
```

---

## 📦 Barrel File Pattern

**Barrel files** group exports for cleaner imports:

```dart
// screens/dashboard/dashboard.dart
export 'dashboard_screen.dart';
export 'widgets/dashboard_widgets.dart';
export 'providers/dashboard_providers.dart';
```

Now you can import everything at once:
```dart
import 'package:app/screens/dashboard/dashboard.dart';
// Get DashboardScreen, all widgets, all providers
```

---

## 🔗 Import Examples

### Import a Screen
```dart
import 'package:app/screens/dashboard/dashboard.dart';

// Use
DashboardScreen()
DashboardSummaryCard()
dashboardProvider
```

### Import Core Utils
```dart
import 'package:app/core/core.dart';

// Use
AppConstants.paddingLarge
AppValidators.validateEmail()
AuthException()
context.isMobile
```

### Import Helpers
```dart
import 'package:app/utils/formatters/formatters.dart';
import 'package:app/utils/validators/validators.dart';
import 'package:app/utils/helpers/app_helpers.dart';

// Use
AppFormatters.formatCurrency()
AppValidators.validatePassword()
AppHelpers.showSnackBar()
```

---

## 🎯 State Management Pattern (Riverpod)

### Simple State Provider
```dart
final counterProvider = StateProvider<int>((ref) => 0);
```

### State Notifier (Complex State)
```dart
final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(),
);

class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());
  
  void update() => state = state.copyWith(...);
}
```

### Derived Provider
```dart
final totalProvider = Provider<double>((ref) {
  final items = ref.watch(itemsProvider);
  return items.fold(0.0, (sum, item) => sum + item.amount);
});
```

### Family Provider (with parameter)
```dart
final userExpensesProvider = FutureProvider.family<List<Expense>, String>(
  (ref, userId) async {
    return await ref.watch(servicesProvider).fetchExpenses(userId);
  },
);

// Use
ref.watch(userExpensesProvider('user123'))
```

---

## 💾 Local Storage Pattern

```dart
// Save
await StorageService().saveString('key', 'value');
await StorageService().saveBoolean('isEnabled', true);

// Retrieve
final value = StorageService().getString('key');
final isEnabled = StorageService().getBoolean('isEnabled');

// Clear
await StorageService().clearAll();
```

---

## 🎨 Theme Usage

```dart
// Access theme colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).textTheme.headlineMedium

// Access app theme
ThemeData lightTheme = AppTheme.lightTheme;
ThemeData darkTheme = AppTheme.darkTheme;

// Toggle theme
ref.read(themeNotifierProvider.notifier).toggleTheme();
```

---

## 📱 Responsive Helper Functions

```dart
// Check device type
context.isMobile      // width < 600
context.isTablet      // 600 ≤ width < 900
context.isDesktop     // width ≥ 900

// Get screen dimensions
context.screenWidth
context.screenHeight
context.safeAreaPadding
```

---

## 🧪 Testing Structure (When Ready)

```
test/
├── core/
├── models/
├── services/
├── providers/
└── screens/
```

---

## 🎓 Learning Resources

- **Riverpod**: https://riverpod.dev
- **Flutter**: https://flutter.dev
- **Firebase**: https://firebase.google.com
- **Clean Architecture**: https://resocoder.com/clean-code-tdd

---

## ✅ Checklist for New Developers

- [ ] Understand folder structure (5 min)
- [ ] Review barrel files pattern (3 min)
- [ ] Study a complete screen (dashboard) (10 min)
- [ ] Read ARCHITECTURE.md (10 min)
- [ ] Try implementing a simple feature (30 min)

**Total: ~60 minutes to productive coding!**

---

## 🚨 Common Mistakes to Avoid

❌ **Don't** - Import from nested paths
```dart
import 'package:app/screens/dashboard/dashboard_screen.dart';
```

✅ **Do** - Use barrel files
```dart
import 'package:app/screens/dashboard/dashboard.dart';
```

---

❌ **Don't** - Mix UI and logic in screens
```dart
class MyScreen extends StatelessWidget {
  void fetchData() { ... }  // Logic in UI!
}
```

✅ **Do** - Keep logic in providers
```dart
class MyNotifier extends StateNotifier { ... }
// Screens only call: ref.read(provider.notifier).fetchData()
```

---

❌ **Don't** - Make mutable models
```dart
class Expense {
  String id;
  double amount;  // Can be modified!
}
```

✅ **Do** - Make immutable models with copyWith
```dart
@immutable
class Expense {
  final String id;
  final double amount;
  
  Expense copyWith({...}) => Expense(...);
}
```

---

**Happy coding! 🎉**
