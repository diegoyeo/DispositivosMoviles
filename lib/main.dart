import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/preferences_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/ets/data/datasources/ets_local_datasource.dart';
import 'features/ets/data/repositories/ets_repository_impl.dart';
import 'features/ets/presentation/providers/ets_provider.dart';
import 'features/ets/presentation/providers/auth_provider.dart';
import 'features/catalogos/providers/catalogos_provider.dart';
import 'features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();
  final onboardingRepo = OnboardingRepositoryImpl();
  final localDataSource = EtsLocalDataSource();
  final repository = EtsRepositoryImpl(localDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EtsProvider(repository)),
        ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
        ChangeNotifierProvider(
          create: (_) => OnboardingProvider(onboardingRepo),
        ),
        ChangeNotifierProvider(create: (_) => CatalogosProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => PreferencesProvider(prefs)),
      ],
      child: const AppLifecycleObserver(
        child: MyApp(),
      ),
    ),
  );
}

class AppLifecycleObserver extends StatefulWidget {
  const AppLifecycleObserver({super.key, required this.child});
  final Widget child;

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && mounted) {
      final auth = context.read<AuthProvider>();
      if (auth.currentRole == 'admin') {
        auth.logoutSilent();
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOVIDA — ETS ESCOM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.currentTheme,
      home: const SplashScreen(),
    );
  }
}
