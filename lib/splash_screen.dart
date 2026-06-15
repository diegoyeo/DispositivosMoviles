import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/ets/presentation/pages/home_dashboard.dart';
import 'features/ets/presentation/pages/login_page.dart';
import 'features/ets/presentation/providers/auth_provider.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Misma clave que usa OnboardingRepositoryImpl
  static const String _kOnboardingKey = 'movida_onboarding_seen';

  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();

    // Escala del logo: crece con rebote (easeOutBack)
    _logoScale = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    // Fade del logo
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    // Nombre de la app aparece después del logo
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
      ),
    );
    // Subtítulo aparece al final
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    // Mínimo 2.8s para que las animaciones completen
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    // Verificar si hay sesión activa
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkAuthOnStartup();
    if (!mounted) return;

    if (authProvider.currentRole != null) {
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, _) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: const HomeDashboard(),
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_kOnboardingKey) ?? false;

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: hasSeenOnboarding
              ? const LoginPage()
              : const OnboardingPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primary, cs.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo: escala + fade
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Nombre: fade
                  Opacity(
                    opacity: _nameOpacity.value,
                    child: Text(
                      'MOVIDA',
                      style: tt.displaySmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtítulo: fade
                  Opacity(
                    opacity: _subtitleOpacity.value,
                    child: Text(
                      'ETS · ESCOM · IPN',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.75),
                        letterSpacing: 3,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
