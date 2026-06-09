# Project Map

Fast-reference guide for future AI coding agents working on this Flutter fintech expense tracker.

## 1. Main Screens

| Screen | Path | Purpose |
| --- | --- | --- |
| Dashboard | `lib/screens/dashboard/dashboard_screen.dart` | Financial overview, summary cards, recent transactions, quick actions |
| Expenses | `lib/screens/expenses/expenses_screen.dart` | Expense CRUD, search, filters, grouping, sorting, delete undo |
| Analytics | `lib/screens/analytics/analytics_screen.dart` | Spending summaries, category charts, trends, payment mix, budget insight |
| Receivables | `lib/screens/receivables/receivables_screen.dart` | Tracks money owed to the user; storage exists, UI still needs build-out |
| Settings | `lib/screens/settings/settings_screen.dart` | App/account/preferences entry points; persistence not complete yet |

## 2. Important Providers

| Provider | File | Purpose |
| --- | --- | --- |
| `hiveServiceProvider` | `lib/providers/storage/storage_providers.dart` | Provides singleton `HiveService` |
| `expensesProvider` | `lib/providers/storage/storage_providers.dart` | Hive-backed source of truth for expenses |
| `receivablesProvider` | `lib/providers/storage/storage_providers.dart` | Hive-backed source of truth for receivables |
| `recentExpensesProvider` | `lib/providers/storage/storage_providers.dart` | Recent user expenses from source state |
| `totalExpensesProvider` | `lib/providers/storage/storage_providers.dart` | Total expense amount for a user |
| `recentReceivablesProvider` | `lib/providers/storage/storage_providers.dart` | Recent user receivables from source state |
| `totalReceivablesProvider` | `lib/providers/storage/storage_providers.dart` | Unpaid receivables total for a user |
| `expensesListProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Expense search, filter, sort, date range, amount range UI state |
| `filteredExpensesProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Filtered and sorted expense list |
| `groupedExpensesProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Expenses grouped by calendar date |
| `expenseStatsProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Total, monthly, count, top category stats |
| `expenseCategoriesProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Available expense categories |
| `expensesByCategoryProvider` | `lib/screens/expenses/providers/expenses_providers.dart` | Category totals for filtered expenses |
| `dashboardProvider` | `lib/screens/dashboard/providers/dashboard_providers.dart` | Dashboard state and refresh scaffold |
| `monthlySpendProvider` | `lib/screens/dashboard/providers/dashboard_providers.dart` | Reactive monthly spend |
| `transactionCountProvider` | `lib/screens/dashboard/providers/dashboard_providers.dart` | Reactive monthly transaction count |
| `dailyAverageProvider` | `lib/screens/dashboard/providers/dashboard_providers.dart` | Reactive 30-day daily average |
| `receivablesTotalProvider` | `lib/screens/dashboard/providers/dashboard_providers.dart` | Reactive unpaid receivables total |
| `analyticsProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Selected analytics period and loading scaffold |
| `analyticsPeriodProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Selected analytics period |
| `analyticsExpensesProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | User-scoped analytics expense list |
| `analyticsPeriodExpensesProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Period-filtered analytics expenses |
| `analyticsSummaryProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Total spend, daily average, top category |
| `analyticsCategoryStatsProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Category totals and percentages |
| `analyticsMonthlyTotalsProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Last six months of totals |
| `analyticsTrendProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Chart trend points |
| `analyticsPaymentMethodStatsProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Payment method totals inferred from descriptions |
| `analyticsBudgetInsightProvider` | `lib/screens/analytics/providers/analytics_providers.dart` | Baseline, current, and projected spending |
| `receivablesListProvider` | `lib/screens/receivables/providers/receivables_providers.dart` | Receivables filter scaffold; currently partly dynamic |
| `filteredReceivablesProvider` | `lib/screens/receivables/providers/receivables_providers.dart` | Paid/unpaid filtered receivables |
| `unpaidCountProvider` | `lib/screens/receivables/providers/receivables_providers.dart` | Unpaid receivable count |
| `settingsProvider` | `lib/screens/settings/providers/settings_providers.dart` | Settings state scaffold |
| `themeModeProvider` | `lib/providers/theme/theme_provider.dart` | Theme mode used by `MyApp` |
| `themeNotifierProvider` | `lib/providers/theme/theme_provider.dart` | Theme toggling scaffold |
| `navigationProvider` | `lib/core/navigation/navigation_provider.dart` | Current tab and sidebar collapsed state |
| `authStateProvider` | `lib/providers/auth/auth_provider.dart` | Authentication scaffold |

## 3. Important Models

| Model | Path | Relationship |
| --- | --- | --- |
| `Expense` | `lib/models/expense/expense_model.dart` | Domain model for user spending records |
| `ExpenseHive` | `lib/models/expense/expense_hive_model.dart` | Hive persistence model mapped to/from `Expense` |
| `Receivable` | `lib/models/receivable/receivable_model.dart` | Domain model for money owed to the user |
| `ReceivableHive` | `lib/models/receivable/receivable_hive_model.dart` | Hive persistence model mapped to/from `Receivable` |
| `UserModel` | `lib/models/user/user_model.dart` | User profile scaffold |
| `ExpenseGroup` | `lib/screens/expenses/models/expense_view_models.dart` | UI grouping model for expenses by date |
| `ExpenseStats` | `lib/screens/expenses/models/expense_view_models.dart` | UI stats model for expenses |
| `AnalyticsSummary` | `lib/screens/analytics/models/analytics_models.dart` | Total spend, average daily, top category |
| `CategoryStat` | `lib/screens/analytics/models/analytics_models.dart` | Category amount and percentage |
| `MonthlyTotal` | `lib/screens/analytics/models/analytics_models.dart` | Month-level chart data |
| `TrendPoint` | `lib/screens/analytics/models/analytics_models.dart` | Trend chart point |
| `PaymentMethodStat` | `lib/screens/analytics/models/analytics_models.dart` | Payment method chart data |
| `BudgetInsight` | `lib/screens/analytics/models/analytics_models.dart` | Budget baseline/projection model |
| `NavigationItem` / `NavigationTab` | `lib/core/navigation/navigation_models.dart` | Navigation structure for app tabs |

## 4. Hive Storage

Hive setup lives in `lib/services/storage/hive_service.dart`.

### Boxes

| Box | Type | Purpose |
| --- | --- | --- |
| `expenses` | `Box<ExpenseHive>` | Stores persisted expenses |
| `receivables` | `Box<ReceivableHive>` | Stores persisted receivables |

### Adapters

| Adapter | Type ID | Purpose |
| --- | --- | --- |
| `ExpenseHiveAdapter` | `0` | Serializes/deserializes expenses |
| `ReceivableHiveAdapter` | `1` | Serializes/deserializes receivables |

### Persistence Flow

```text
UI action
  -> Riverpod notifier in providers/storage/storage_providers.dart
  -> HiveService method
  -> Hive box put/delete/read
  -> notifier updates typed Riverpod state
  -> computed providers recompute
  -> UI rebuilds reactively
```

Hive is the local source of truth. Do not change type IDs or persisted field structure without migration planning.

## 5. Widget Organization

```text
lib/widgets/
  common/       Shared app-level display widgets
  inputs/       Shared input controls
  responsive/   Shared responsive layout helpers

lib/screens/<feature>/widgets/
  Feature-specific cards, lists, sections, modals, charts, and empty states
```

Widget rules:

- Screens compose widgets.
- Widgets render UI and emit user actions.
- Providers compute state.
- Services persist data.
- Avoid business logic in reusable widgets.
- Use theme colors and category styles instead of hardcoded colors.

## 6. Current Features Implemented

- Flutter app startup with Hive initialization.
- Riverpod app state.
- Responsive app shell.
- Desktop sidebar navigation.
- Mobile bottom navigation.
- Expense CRUD with Hive persistence.
- Add expense modal.
- Edit expense modal.
- Expense delete with undo.
- Expense details sheet.
- Expense search.
- Category filtering.
- Date and amount filtering.
- Expense sorting.
- Grouped expense list by date.
- Expense stats header.
- Dashboard summary metrics.
- Recent dashboard transactions.
- Analytics summary cards.
- Category breakdown analytics.
- Monthly spending chart data.
- Trend chart data.
- Payment method inference from notes.
- Budget projection insight.
- Dark/light theme structure, with dark fintech direction.
- Category icon/color styling.
- Formatter utilities for currency and dates.

## 7. Future Planned Features

- Notifications and due-date reminders.
- Recurring expenses.
- Cloud sync.
- AI spending insights.
- Export/import.
- Authentication.
- Budget entities and budget editing.
- Full receivables CRUD UI.
- Settings persistence.
- Current-user provider replacing hardcoded `userId`.
- Provider and widget test coverage.

## 8. Development Rules Summary

From `AI_CONTRACT.md`:

- Never overwrite polished implementations.
- Always inspect existing files first.
- Make incremental, scoped changes.
- Preserve modular clean architecture.
- Preserve Hive persistence.
- Preserve Riverpod reactivity.
- Preserve responsive mobile and desktop behavior.
- Preserve the current design system and premium fintech look.
- Keep business logic out of UI widgets.
- Use reusable widgets and modular providers.
- Avoid giant files, duplicated logic, dead code, and hardcoded colors.
- Run `flutter analyze` when the local toolchain allows it.

