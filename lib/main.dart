import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/preferences_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/catalogos/providers/catalogos_provider.dart';
import 'features/ets/data/datasources/ets_local_datasource.dart';
import 'features/ets/data/repositories/ets_repository_impl.dart';
import 'features/ets/presentation/pages/login_page.dart';
import 'features/ets/presentation/providers/auth_provider.dart';
import 'features/ets/presentation/providers/ets_provider.dart';
import 'features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';
import 'splash_screen.dart';

// Clave global para navegar desde fuera del árbol de widgets (lifecycle observer)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  final prefs = await SharedPreferences.getInstance();

  // PASO 3: Limpiar sesión admin si quedó guardada.
  // Garantía principal: aunque Android mate el proceso sin disparar ningún
  // lifecycle event, main() siempre se ejecuta al abrir la app de nuevo.
  if (prefs.getString('user_rol') == 'admin') {
    await prefs.remove('auth_token');
    await prefs.remove('user_correo');
    await prefs.remove('user_nombre');
    await prefs.remove('user_apellido');
    await prefs.remove('user_rol');
    await prefs.remove('admin_background_timestamp');
  }

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
    final auth = context.read<AuthProvider>();

    // PASO 1a: App va a segundo plano — guardar timestamp si es admin.
    if (state == AppLifecycleState.paused) {
      if (auth.currentRole == 'admin') {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt(
            'admin_background_timestamp',
            DateTime.now().millisecondsSinceEpoch,
          );
        });
      }
    }

    // PASO 1b: App vuelve al primer plano — verificar tiempo en background.
    if (state == AppLifecycleState.resumed) {
      if (auth.currentRole == 'admin') {
        SharedPreferences.getInstance().then((prefs) {
          final timestamp = prefs.getInt('admin_background_timestamp');
          if (timestamp != null) {
            final elapsed = DateTime.now().difference(
              DateTime.fromMillisecondsSinceEpoch(timestamp),
            );
            if (elapsed.inSeconds > 3) {
              auth.logoutSilent();
              prefs.remove('admin_background_timestamp');
              navigatorKey.currentState?.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
          }
        });
      }
    }

    // detached como red de seguridad adicional (no confiable en Android)
    if (state == AppLifecycleState.detached) {
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
      navigatorKey: navigatorKey,
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
