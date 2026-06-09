# Navigation Architecture Guide

## 📱 Overview

This document explains the responsive navigation architecture for the Personal Expense Tracker app. The navigation automatically adapts between desktop and mobile layouts using Riverpod for state management.

---

## 🏗️ Architecture Structure

```
lib/
├── core/
│   └── navigation/
│       ├── navigation_models.dart      # Navigation data models
│       └── navigation_provider.dart    # Riverpod providers
│
├── navigation/
│   ├── navigation.dart                 # Barrel file (exports)
│   ├── app_shell.dart                  # Main responsive shell
│   ├── desktop_sidebar.dart            # Desktop sidebar widget
│   └── mobile_bottom_navigation.dart   # Mobile bottom nav widget
│
└── screens/
    ├── dashboard/
    ├── expenses/
    ├── analytics/
    ├── receivables/
    └── settings/
```

---

## 🎯 Key Components

### 1. **Navigation Models** (`navigation_models.dart`)

Defines the navigation data structures:

```dart
enum NavigationTab {
  dashboard,
  expenses,
  analytics,
  receivables,
  settings,
}

class NavigationItem {
  final String id;
  final String label;
  final IconData icon;
  final String route;
}
```

**Extension methods** provide easy access to tab properties:
```dart
NavigationTab.dashboard.label  // "Dashboard"
NavigationTab.dashboard.icon   // Icons.dashboard_rounded
NavigationTab.dashboard.toItem() // NavigationItem
```

### 2. **Navigation Provider** (`navigation_provider.dart`)

Riverpod provider for managing navigation state:

```dart
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>(
  (ref) => NavigationNotifier(),
);
```

**Key methods:**
- `navigateTo(NavigationTab)` - Navigate to specific tab
- `toggleSidebar()` - Toggle sidebar collapse state
- `collapseSidebar()` / `expandSidebar()` - Control sidebar directly

**Derived providers:**
```dart
final currentNavigationItemProvider      // Current selected item
final isSidebarCollapsedProvider         // Sidebar state
final navigationItemsProvider            // All navigation items
```

### 3. **Desktop Sidebar** (`desktop_sidebar.dart`)

Features:
- ✅ Collapsible sidebar with smooth animation
- ✅ Logo and branding area
- ✅ Navigation items with active state highlighting
- ✅ Collapse/expand toggle button
- ✅ Tooltips for collapsed state
- ✅ Dark theme compatible

**Responsive:** Only visible when width ≥ 900px

### 4. **Mobile Bottom Navigation** (`mobile_bottom_navigation.dart`)

Features:
- ✅ Horizontal scrollable bottom bar
- ✅ Icons + labels
- ✅ Active tab highlighting with bottom border
- ✅ Dark theme compatible

**Responsive:** Only visible when width < 900px

### 5. **App Shell** (`app_shell.dart`)

Main responsive layout manager:
```dart
// Desktop: Sidebar + Content
// Mobile: Content + Bottom Nav

if (isDesktop) {
  Row(
    children: [
      DesktopSidebar(),
      Expanded(content),
    ],
  )
} else {
  Column(
    children: [
      Expanded(content),
      MobileBottomNavigation(),
    ],
  )
}
```

---

## 🔄 Data Flow

```
User taps navigation item
        ↓
NavigationItem.onTap()
        ↓
ref.read(navigationProvider.notifier).navigateTo(tab)
        ↓
NavigationState updated with new currentTab
        ↓
AppShell rebuilds
        ↓
Current screen shown based on navigationState.currentTab
```

---

## 📱 Responsive Behavior

### **Desktop View (width ≥ 900px)**
```
┌─────────────────────────────┐
│ Sidebar  │  Dashboard       │
│  - Logo  │  - Content       │
│  - Items │  - No bottom nav │
│  - Close │                  │
└─────────────────────────────┘
```

### **Tablet View (600-900px)**
```
┌──────────────────────────┐
│  Dashboard               │
│  - Content               │
│  - Bottom navigation     │
├──────────────────────────┤
│ Dashboard │ Expenses │...│
└──────────────────────────┘
```

### **Mobile View (width < 600px)**
```
┌──────────────────────────┐
│  Dashboard               │
│  - Content               │
│  - Bottom navigation     │
├──────────────────────────┤
│ Dashboard│ Expenses │...│
└──────────────────────────┘
```

---

## 🎨 Styling & Theming

### Light Theme
- Clean white sidebar/bottom nav
- Subtle gray dividers
- Blue active state

### Dark Theme
- Dark surface color for navigation
- High contrast text
- Maintains Material 3 design

Both themes automatically adapt via `Theme.of(context)`.

---

## 🚀 Usage Guide

### Navigate Programmatically

```dart
// From any widget
ref.read(navigationProvider.notifier).navigateTo(NavigationTab.expenses);

// Or using route string
ref.read(navigationProvider.notifier).navigateToRoute('/expenses');
```

### Watch Navigation State

```dart
// In any consumer widget
final navigationState = ref.watch(navigationProvider);
final currentTab = navigationState.currentTab;
final isCollapsed = navigationState.isSidebarCollapsed;
```

### Access Current Item

```dart
final currentItem = ref.watch(currentNavigationItemProvider);
print(currentItem.label);  // "Dashboard", etc.
```

---

## 🎯 Active Tab Highlighting

### Desktop Sidebar
- Primary color background on active item
- Bold text weight
- Icon color changes
- Small dot indicator on icon

### Mobile Bottom Nav
- Bottom border color changes to primary
- Icon color changes
- Bold text weight

---

## 🔧 Customization

### Add New Navigation Tab

1. **Add to enum** (`navigation_models.dart`):
```dart
enum NavigationTab {
  dashboard,
  expenses,
  // NEW TAB
  newTab,
}
```

2. **Add extension case** (`navigation_models.dart`):
```dart
case NavigationTab.newTab:
  return 'new_tab';

String get label {
  case NavigationTab.newTab:
    return 'New Tab';
}
```

3. **Add screen** (`screens/new_tab/`):
```dart
class NewTabScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(/* ... */);
  }
}
```

4. **Add to shell** (`app_shell.dart`):
```dart
case 'new_tab':
  return const NewTabScreen();
```

---

## ⚡ Performance Optimizations

### **Smooth Animations**
- 300ms duration for sidebar collapse/expand
- Animated container for smooth width change
- No jank during navigation

### **Efficient Rebuilds**
- Only affected widgets rebuild on navigation change
- Derived providers prevent unnecessary rebuilds
- Separates UI state from navigation state

### **Responsive Detection**
```dart
final isDesktop = MediaQuery.of(context).size.width >= 900;
```

Breakpoint: **900px** (tablet width threshold)

---

## 🎓 How It Works

### Navigation Selection Flow

```
1. User taps "Expenses" in navigation
   ↓
2. _SidebarNavigationItem.onTap() called
   ↓
3. ref.read(navigationProvider.notifier).navigateTo(expenses)
   ↓
4. NavigationNotifier state updated
   ↓
5. AppShell.build() rebuilds (watching navigationProvider)
   ↓
6. ExpensesScreen displayed
   ↓
7. Both Sidebar and Bottom Nav highlight Expenses
```

### Responsive Layout Flow

```
1. AppShell checks screen width
   ↓
2. if (isDesktop) show Sidebar + Content
   else show Content + Bottom Nav
   ↓
3. Single source of truth for current tab
   ↓
4. Both navigations stay in sync
```

---

## 🐛 Troubleshooting

### **Navigation not changing?**
- Check that screen is wrapped in `ConsumerWidget`
- Verify tab ID matches route string
- Check navigation provider is being watched

### **Sidebar collapsing unexpectedly?**
- Check window is actually ≥ 900px
- Verify no other code toggling sidebar
- Check animations completing properly

### **Theme not applying?**
- Ensure app is wrapped in `ProviderScope`
- Check `AppTheme.lightTheme/darkTheme` configured
- Verify theme provider is being watched

---

## 📚 File Relationships

```
app_shell.dart
  ├─ imports → desktop_sidebar.dart
  ├─ imports → mobile_bottom_navigation.dart
  └─ imports → all screen files

desktop_sidebar.dart
  └─ imports → navigation_provider.dart

mobile_bottom_navigation.dart
  └─ imports → navigation_provider.dart

navigation_provider.dart
  └─ imports → navigation_models.dart

main.dart
  └─ imports → app_shell.dart
```

---

## ✨ Key Features Summary

✅ **Responsive** - Adapts to desktop/mobile  
✅ **State-Driven** - Riverpod for navigation state  
✅ **Smooth** - Animated transitions  
✅ **Accessible** - Tooltips, clear labels  
✅ **Themeable** - Dark mode compatible  
✅ **Scalable** - Easy to add new tabs  
✅ **Performant** - Efficient rebuilds  
✅ **Clean** - Separation of concerns  

---

## 🔗 Integration Points

### **Connect to Existing Features:**

1. **Analytics** - Navigate to analytics from dashboard button
2. **Settings** - Update navigation from settings
3. **Notifications** - Navigate on notification tap
4. **Deep Linking** - Use `navigateToRoute()` with deeplink URLs

### **Example: Deep Link Handler**

```dart
onGenerateRoute: (settings) {
  ref.read(navigationProvider.notifier).navigateToRoute(settings.name ?? '/');
  return MaterialPageRoute(builder: (_) => const AppShell());
}
```

---

**Navigation Architecture Ready for Production!** 🚀
