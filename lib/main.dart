import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'navigation/navigation.dart';
import 'providers/onboarding/onboarding_provider.dart';
import 'providers/auth/auth_provider.dart';
import 'providers/storage/storage_providers.dart';
import 'providers/sync/sync_providers.dart';
import 'screens/settings/widgets/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme/theme_provider.dart';
import 'services/storage/hive_service.dart';
import 'services/supabase/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Hive for offline-first storage
  await HiveService.initialize();

  // Initialize Supabase (safe if config missing - app still works offline)
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('⚠️ Supabase initialization failed: $e');
    debugPrint('App will run in offline-only mode');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final authState = ref.watch(authStateProvider);

    // Auto-trigger startup sync when user is authenticated
    ref.listen(authStateProvider, (previous, next) {
      if (next.isAuthenticated &&
          (previous == null || !previous.isAuthenticated)) {
        Future.microtask(() {
          final userId = next.userId;
          if (userId != null && userId.isNotEmpty) {
            ref.read(expensesProvider.notifier).fetchExpenses(userId);
            ref.read(receivablesProvider.notifier).fetchReceivables(userId);
            ref.read(payablesProvider.notifier).fetchPayables(userId);
            ref
                .read(recurringTemplatesProvider.notifier)
                .fetchTemplates(userId);
          }
          ref.read(syncProvider.notifier).autoSyncOnStartup();
        });
      }
    });

    return MaterialApp(
      title: 'Personal Expense Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _buildHome(onboardingState, authState),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildHome(OnboardingState onboardingState, AuthState authState) {
    // Show loading while checking onboarding status
    if (onboardingState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If onboarding not completed, show onboarding
    if (!onboardingState.isCompleted) {
      return const OnboardingScreen();
    }

    // If authenticated, show app shell
    if (authState.isAuthenticated) {
      return const _LocalDataBootstrap(child: AppShell());
    }

    // Otherwise show login screen (you may want to create this)
    // For now, returning AppShell allows offline use
    return const _LocalDataBootstrap(child: AppShell());
  }
}

class _LocalDataBootstrap extends ConsumerStatefulWidget {
  final Widget child;

  const _LocalDataBootstrap({required this.child});

  @override
  ConsumerState<_LocalDataBootstrap> createState() =>
      _LocalDataBootstrapState();
}

class _LocalDataBootstrapState extends ConsumerState<_LocalDataBootstrap> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    Future.microtask(() async {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null || userId.isEmpty) return;
      await Future.wait([
        ref.read(expensesProvider.notifier).fetchExpenses(userId),
        ref.read(receivablesProvider.notifier).fetchReceivables(userId),
        ref.read(payablesProvider.notifier).fetchPayables(userId),
        ref.read(recurringTemplatesProvider.notifier).fetchTemplates(userId),
      ]);
      await ref.read(syncProvider.notifier).refreshStatus();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
