# Flutter Expense Tracker - Complete Project Structure Guide

## 📊 Project Overview

This is a **production-ready, scalable Flutter application** for personal expense tracking with Riverpod state management. The architecture emphasizes **modularity, maintainability, and clean code principles**.

---

## 🏗️ Complete Folder Architecture

```
lib/
├── main.dart                           # App entry point
│
├── core/                               # Core functionality layer
│   ├── core.dart                       # Barrel file (exports)
│   ├── config/
│   │   └── app_config.dart            # Firebase, app configuration
│   ├── constants/
│   │   └── app_constants.dart         # Constants, breakpoints, shadows
│   ├── errors/
│   │   └── app_exception.dart         # Custom exception classes
│   └── extensions/
│       └── extensions.dart            # Dart extensions (DateTime, String, etc.)
│
├── models/                             # Data models (immutable, with copyWith)
│   ├── user/
│   │   └── user_model.dart            # User profile model
│   ├── expense/
│   │   └── expense_model.dart         # Expense transaction model
│   ├── receivable/
│   │   └── receivable_model.dart      # Receivable (money owed) model
│   └── transaction/                    # (Extensible for future models)
│
├── services/                           # Data access layer (external APIs, databases)
│   ├── firebase/
│   │   └── firebase_service.dart      # Firebase Firestore operations
│   ├── auth/
│   │   └── auth_service.dart          # Firebase Authentication
│   └── storage/
│       └── storage_service.dart       # Local storage (SharedPreferences)
│
├── providers/                          # Global Riverpod providers
│   ├── auth/
│   │   └── auth_provider.dart         # Authentication state
│   ├── expense/
│   │   └── expense_provider.dart      # Global expense data (shared across screens)
│   ├── ui/
│   │   └── ui_provider.dart           # Loading, error, success states
│   └── theme/
│       └── theme_provider.dart        # Theme mode management
│
├── screens/                            # UI screens (modular structure)
│   ├── screens.dart                    # Barrel file for all screens
│   │
│   ├── dashboard/                      # Dashboard screen (overview)
│   │   ├── dashboard.dart              # Barrel file (exports)
│   │   ├── dashboard_screen.dart       # Main screen widget
│   │   ├── providers/
│   │   │   └── dashboard_providers.dart    # Dashboard-specific providers
│   │   └── widgets/
│   │       └── dashboard_widgets.dart      # Dashboard-specific widgets
│   │
│   ├── expenses/                       # Expenses management screen
│   │   ├── expenses.dart               # Barrel file
│   │   ├── expenses_screen.dart        # Main screen widget
│   │   ├── providers/
│   │   │   └── expenses_providers.dart     # Filter, sort, search logic
│   │   └── widgets/
│   │       └── expenses_widgets.dart       # ExpenseCard, ExpenseSearchBar, etc.
│   │
│   ├── analytics/                      # Analytics & reports screen
│   │   ├── analytics.dart              # Barrel file
│   │   ├── analytics_screen.dart       # Main screen widget
│   │   ├── providers/
│   │   │   └── analytics_providers.dart    # Chart data, summaries
│   │   └── widgets/
│   │       └── analytics_widgets.dart      # ChartPlaceholder, graphs, etc.
│   │
│   ├── receivables/                    # Money owed tracking screen
│   │   ├── receivables.dart            # Barrel file
│   │   ├── receivables_screen.dart     # Main screen widget
│   │   ├── providers/
│   │   │   └── receivables_providers.dart  # Receivables state
│   │   └── widgets/
│   │       └── receivables_widgets.dart    # ReceivableCard, etc.
│   │
│   └── settings/                       # App settings screen
│       ├── settings.dart               # Barrel file
│       ├── settings_screen.dart        # Main screen widget
│       ├── providers/
│       │   └── settings_providers.dart     # User preferences, theme, locale
│       └── widgets/
│           └── settings_widgets.dart       # SettingsSelectionTile, etc.
│
├── widgets/                            # Reusable UI components
│   ├── common/
│   │   └── common_widgets.dart        # LoadingIndicator, ErrorWidget, EmptyState
│   ├── responsive/
│   │   └── responsive_widgets.dart    # ResponsiveWidget, ResponsiveGridView
│   └── inputs/
│       └── input_widgets.dart         # CustomTextField, CustomDropdown, etc.
│
├── theme/
│   └── app_theme.dart                 # Light & dark theme definitions
│
└── utils/                              # Utility functions
    ├── formatters/
    │   └── formatters.dart            # Currency, date, number formatting
    ├── validators/
    │   └── validators.dart            # Email, password, amount validators
    └── helpers/
        └── app_helpers.dart           # SnackBars, dialogs, date helpers
```

---

## 🎯 Key Architecture Patterns

### 1. **Screen Modularity**
Each screen is **self-contained** with its own:
- **Screen widget** (`dashboard_screen.dart`)
- **Providers** (`providers/` folder) - Screen-specific state management
- **Widgets** (`widgets/` folder) - Screen-specific reusable components

**Example structure for Dashboard:**
```
screens/dashboard/
├── dashboard.dart              # Barrel file: export dashboard_screen, widgets, providers
├── dashboard_screen.dart       # Main UI
├── providers/dashboard_providers.dart
└── widgets/dashboard_widgets.dart
```

### 2. **Barrel Files for Cleaner Imports**
Use barrel files (index files) to simplify imports:

**Before:**
```dart
import 'package:app/screens/dashboard/dashboard_screen.dart';
import 'package:app/screens/dashboard/providers/dashboard_providers.dart';
import 'package:app/screens/dashboard/widgets/dashboard_widgets.dart';
```

**After:**
```dart
import 'package:app/screens/dashboard/dashboard.dart';
// Now you have access to DashboardScreen, all providers, and all widgets
```

### 3. **Provider Organization**
- **Global Providers** (`providers/`) - Shared across screens (auth, theme, UI state)
- **Screen Providers** (`screens/*/providers/`) - Screen-specific state and logic

### 4. **Separation of Concerns**

| Layer | Responsibility |
|-------|---|
| **Services** | External data access (Firebase, REST APIs, local storage) |
| **Providers** | State management and business logic |
| **Screens** | UI layout and user interactions |
| **Widgets** | Reusable UI components |
| **Utils** | Formatting, validation, helper functions |

---

## 💡 Usage Examples

### Importing a Screen
```dart
import 'package:personal_expanse_tracker/screens/dashboard/dashboard.dart';

// Use DashboardScreen, DashboardSummaryCard, dashboardProvider, etc.
```

### Importing from Core
```dart
import 'package:personal_expanse_tracker/core/core.dart';

// Use AppConstants, AppValidators, AuthException, etc.
```

### Building a Screen Widget
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final state = ref.watch(myProvider);
    
    // Use screen-specific widgets
    return Scaffold(
      body: MyScreenWidget(
        onAction: () => ref.read(myProvider.notifier).doSomething(),
      ),
    );
  }
}
```

---

## 🔄 Data Flow Architecture

```
┌─────────────┐
│   Screens   │  (UI Layer - widgets)
└──────┬──────┘
       │
┌──────▼──────────────┐
│   Providers/State   │  (State Management - Riverpod)
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│    Services         │  (Data Access - Firebase, APIs)
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│   External APIs     │  (Backend - Firebase, REST)
└─────────────────────┘
```

### Example Flow: Add Expense
1. **Screen** (`expenses_screen.dart`) - User taps "Add Expense" button
2. **Provider** (`expenses_providers.dart`) - Calls `addExpense()`
3. **Service** (`firebase_service.dart`) - Makes API call to Firestore
4. **Backend** (Firebase) - Stores data
5. **Provider** - Updates state with new expense
6. **Screen** - Rebuilds and displays new expense

---

## 📱 Responsive Design

The app supports **mobile, tablet, and desktop** using:

```dart
// In app_constants.dart
static const double mobileWidth = 600;
static const double tabletWidth = 900;
static const double desktopWidth = 1200;

// In core/extensions/extensions.dart
bool isMobile = context.isMobile;  // width < 600
bool isTablet = context.isTablet;  // 600-900
bool isDesktop = context.isDesktop; // >= 900
```

**Use ResponsiveWidget for adaptive layouts:**
```dart
ResponsiveWidget(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

---

## 🎨 Theme System

Both **light and dark themes** are defined in `theme/app_theme.dart`:

```dart
class AppTheme {
  static ThemeData get lightTheme { ... }
  static ThemeData get darkTheme { ... }
}
```

Toggle theme using the theme provider:

```dart
ref.read(themeNotifierProvider.notifier).toggleTheme();
```

---

## 🔐 Error Handling

Custom exception classes in `core/errors/app_exception.dart`:

```dart
try {
  await service.fetchData();
} on FirebaseException catch (e) {
  // Handle Firebase errors
} on AuthException catch (e) {
  // Handle auth errors
} on AppException catch (e) {
  // Handle app-specific errors
}
```

---

## 🚀 Ready-to-Implement Features

### **Screen-Specific Providers (TODO)**
Each screen has `providers/` folder with state management ready:
- Dashboard: Summary data, recent expenses, charts
- Expenses: Filtering, sorting, searching, CRUD
- Analytics: Period selection, chart data, trends
- Receivables: Status filtering, payment tracking
- Settings: User preferences, theme, notifications

### **Screen-Specific Widgets (TODO)**
Each screen has `widgets/` folder with reusable components:
- Dashboard: SummaryCards, QuickActionButtons, Charts
- Expenses: ExpenseCards, SearchBars, FilterChips
- Analytics: ChartPlaceholders, SummaryCards, Categories
- Receivables: ReceivableCards, StatusFilters
- Settings: SettingsTiles, DropdownDialogs

---

## 📋 Implementation Checklist

- [ ] **Phase 1: Core Setup**
  - [ ] Configure Firebase in `core/config/`
  - [ ] Implement authentication in `services/auth/`
  - [ ] Set up Firestore in `services/firebase/`

- [ ] **Phase 2: Global State**
  - [ ] Complete `providers/auth/`
  - [ ] Complete `providers/theme/`
  - [ ] Complete `providers/ui/`

- [ ] **Phase 3: Screen Implementation** (per screen)
  - [ ] Implement providers with API calls
  - [ ] Build screen UI
  - [ ] Add screen-specific widgets
  - [ ] Connect to global providers

- [ ] **Phase 4: Polish**
  - [ ] Add animations
  - [ ] Optimize performance
  - [ ] Add comprehensive error handling
  - [ ] Test responsiveness on all devices

---

## 🎓 Best Practices Applied

✅ **Clean Architecture** - Separation of concerns  
✅ **Modular Design** - Self-contained, reusable screens  
✅ **Single Responsibility** - Each file has one purpose  
✅ **DRY Principle** - Reusable widgets and utilities  
✅ **Immutability** - Models use copyWith pattern  
✅ **Type Safety** - Strong typing throughout  
✅ **Responsive** - Mobile, tablet, desktop support  
✅ **Dark Theme** - Light and dark mode support  
✅ **Scalability** - Easy to add new features  

---

## 📚 File Organization Rules

1. **Screen Barrel Files** - Always export screen content
2. **Provider Organization** - Global in `providers/`, screen-specific in `screens/*/providers/`
3. **Widget Organization** - Common in `widgets/common/`, screen-specific in `screens/*/widgets/`
4. **Service Layer** - All external API calls go through services
5. **Constants** - Centralize in `core/constants/`
6. **Utilities** - Group by purpose (formatters, validators, helpers)

---

## 🔗 Import Priority

1. **Dart imports** (package:flutter, package:flutter_riverpod)
2. **Package imports** (external libraries)
3. **Project imports** (relative paths)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_expanse_tracker/core/core.dart';
import 'package:personal_expanse_tracker/screens/dashboard/dashboard.dart';

import 'providers/dashboard_providers.dart';
import 'widgets/dashboard_widgets.dart';
```

---

## 🎉 Next Steps

1. **Set up Firebase** - Add credentials to `core/config/`
2. **Implement Auth** - Complete login/signup in `services/auth/`
3. **Build Screens** - Implement screen logic and UI
4. **Connect Data** - Wire up providers to UI
5. **Add Persistence** - Use `services/storage/` for local caching
6. **Test Everything** - Comprehensive testing for all features

---

**This architecture is production-ready and scales as your app grows!** 🚀
