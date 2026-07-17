import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/analytics_tracking_service.dart';
import 'firebase/firebase_bootstrap.dart';
import 'screens/dashboard_screen.dart';
import 'screens/journals_screen.dart';
import 'screens/keywords_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'viewmodels/authentication_view_model.dart';
import 'viewmodels/firebase_demo_view_model.dart';
import 'viewmodels/journals_view_model.dart';
import 'viewmodels/keywords_view_model.dart';
import 'viewmodels/notification_center_view_model.dart';
import 'viewmodels/report_export_view_model.dart';
import 'viewmodels/research_tab_view_model.dart';
import 'models/research_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseEnabled = await FirebaseBootstrap.initialize();
  if (firebaseEnabled) _configureCrashlyticsErrorHandling();

  runApp(JournalSearchApp(firebaseEnabled: firebaseEnabled));
}

void _configureCrashlyticsErrorHandling() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

class JournalSearchApp extends StatefulWidget {
  const JournalSearchApp({
    required this.firebaseEnabled,
    this.initializeFirebase,
    super.key,
  });

  final bool firebaseEnabled;
  final Future<bool> Function()? initializeFirebase;

  @override
  State<JournalSearchApp> createState() => _JournalSearchAppState();
}

class _JournalSearchAppState extends State<JournalSearchApp> {
  late bool _firebaseEnabled = widget.firebaseEnabled;
  bool _isRetryingFirebase = false;

  Future<void> _retryFirebaseInitialization() async {
    if (_isRetryingFirebase) return;
    setState(() => _isRetryingFirebase = true);

    final initialize =
        widget.initializeFirebase ?? FirebaseBootstrap.initialize;
    var enabled = false;
    try {
      enabled = await initialize();
    } catch (_) {
      enabled = false;
    }
    if (!mounted) return;

    if (enabled && widget.initializeFirebase == null) {
      _configureCrashlyticsErrorHandling();
    }
    setState(() {
      _firebaseEnabled = enabled;
      _isRetryingFirebase = false;
    });
  }

  @override
  void didUpdateWidget(covariant JournalSearchApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.firebaseEnabled != widget.firebaseEnabled) {
      _firebaseEnabled = widget.firebaseEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal Trend Analyzer',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B6DE9),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1F2937)),
        ),
      ),
      navigatorObservers: _firebaseEnabled
          ? [AnalyticsTrackingService.instance.observer]
          : const [],
      home: _firebaseEnabled
          ? Provider<AuthenticationViewModel>(
              create: (_) => AuthenticationViewModel(),
              child: const AuthGate(),
            )
          : FirebaseInitializationErrorScreen(
              isRetrying: _isRetryingFirebase,
              onRetry: _retryFirebaseInitialization,
            ),
    );
  }
}

class FirebaseInitializationErrorScreen extends StatelessWidget {
  const FirebaseInitializationErrorScreen({
    required this.isRetrying,
    required this.onRetry,
    super.key,
  });

  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('firebase_initialization_error_screen'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 52,
                        color: Color(0xFFB91C1C),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Firebase could not start',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Check the network and Firebase Android configuration, '
                        'then try again. Sign-in and protected app features stay '
                        'locked until Firebase is ready.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        key: const Key('retry_firebase_initialization_button'),
                        onPressed: isRetrying ? null : onRetry,
                        icon: isRetrying
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          isRetrying
                              ? 'Retrying Firebase...'
                              : 'Retry Firebase',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthenticationViewModel>();
    return StreamBuilder<User?>(
      stream: authViewModel.authStateChanges(),
      initialData: authViewModel.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return LoginScreen(
            onSignInWithGoogle: authViewModel.signInWithGoogle,
          );
        }

        final userId = snapshot.data!.uid;
        return MainShell(
          key: ValueKey<String>('main_shell_$userId'),
          firebaseEnabled: true,
          userId: userId,
        );
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    required this.firebaseEnabled,
    required this.userId,
    super.key,
  }) : assert(!firebaseEnabled || userId != null);

  final bool firebaseEnabled;
  final String? userId;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final ResearchTabViewModel _homeViewModel = ResearchTabViewModel(
    initialTopic: 'Artificial Intelligence',
  );
  ReportExportViewModel? _reportExportViewModel;
  NotificationCenterViewModel? _notificationViewModel;
  FirebaseDemoViewModel? _firebaseDemoViewModel;

  late final List<Widget> _pages = <Widget>[
    DashboardScreen(onOpenNotifications: () => _onTap(3)),
    ChangeNotifierProvider<JournalsViewModel>(
      create: (_) => JournalsViewModel(),
      child: const JournalsScreen(),
    ),
    ChangeNotifierProvider<KeywordsViewModel>(
      create: (_) => KeywordsViewModel(),
      child: const KeywordsScreen(),
    ),
    ProfileScreen(firebaseEnabled: widget.firebaseEnabled),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.firebaseEnabled) {
      _reportExportViewModel = ReportExportViewModel();
      _notificationViewModel = NotificationCenterViewModel(
        userId: widget.userId!,
        onForegroundNotification: _showForegroundNotification,
        onNotificationOpened: _openNotificationCenter,
      );
      _firebaseDemoViewModel = FirebaseDemoViewModel();
      unawaited(_notificationViewModel!.initialize());
    }
  }

  void _showForegroundNotification(ResearchNotification notification) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.body}'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'View', onPressed: () => _onTap(3)),
        ),
      );
    });
  }

  void _openNotificationCenter(ResearchNotification notification) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _currentIndex != 3) _onTap(3);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_notificationViewModel?.reloadStoredNotifications());
    }
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeViewModel.dispose();
    _reportExportViewModel?.dispose();
    _notificationViewModel?.dispose();
    _firebaseDemoViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ResearchTabViewModel>.value(
          value: _homeViewModel,
        ),
        if (widget.firebaseEnabled)
          ChangeNotifierProvider<ReportExportViewModel>.value(
            value: _reportExportViewModel!,
          ),
        if (widget.firebaseEnabled)
          ChangeNotifierProvider<NotificationCenterViewModel>.value(
            value: _notificationViewModel!,
          ),
        if (widget.firebaseEnabled)
          ChangeNotifierProvider<FirebaseDemoViewModel>.value(
            value: _firebaseDemoViewModel!,
          ),
      ],
      child: Builder(
        builder: (context) {
          final unreadCount = widget.firebaseEnabled
              ? context.watch<NotificationCenterViewModel>().unreadCount
              : 0;
          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: _pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTap,
              destinations: [
                const NavigationDestination(
                  key: Key('home_tab'),
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                const NavigationDestination(
                  key: Key('journals_tab'),
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books_rounded),
                  label: 'Journals',
                ),
                const NavigationDestination(
                  key: Key('keywords_tab'),
                  icon: Icon(Icons.key_outlined),
                  selectedIcon: Icon(Icons.key_rounded),
                  label: 'Keywords',
                ),
                NavigationDestination(
                  key: const Key('profile_tab'),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.person_outline_rounded),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.person_rounded),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
