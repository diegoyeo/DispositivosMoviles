import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/onboarding_provider.dart';
import '../../../ets/presentation/pages/login_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelo de datos — solo icono y textos; colores vienen del tema
// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  final IconData icon;
  final String title;
  final String description;

  const _SlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

const List<_SlideData> _kSlides = [
  _SlideData(
    icon: Icons.school_rounded,
    title: 'Bienvenido a MOVIDA',
    description:
        'Tu guía definitiva para los Exámenes a Título de '
        'Suficiencia en ESCOM‑IPN. Todo lo que necesitas, '
        'en un solo lugar.',
  ),
  _SlideData(
    icon: Icons.manage_search_rounded,
    title: 'Busca tu examen',
    description:
        'Filtra por carrera, semestre y materia para '
        'encontrar el ETS que necesitas en segundos.',
  ),
  _SlideData(
    icon: Icons.notifications_active_rounded,
    title: 'Favoritos y recordatorios',
    description:
        'Guarda los exámenes de tu interés y activa '
        'notificaciones para no olvidar ninguna fecha importante.',
  ),
  _SlideData(
    icon: Icons.rocket_launch_rounded,
    title: '¡Listo para empezar!',
    description:
        'Ya conoces todo lo que MOVIDA puede hacer por ti. '
        '¡Comencemos juntos tu preparación!',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers de color — todo derivado de colorScheme, sin hardcode
// ─────────────────────────────────────────────────────────────────────────────

// Colores del ícono (container + foreground) según índice de slide
({Color container, Color onContainer}) _iconColors(
    int page, ColorScheme cs) {
  switch (page) {
    case 1:
      return (container: cs.secondaryContainer, onContainer: cs.onSecondaryContainer);
    case 2:
      return (container: cs.tertiaryContainer, onContainer: cs.onTertiaryContainer);
    default:
      return (container: cs.primaryContainer, onContainer: cs.onPrimaryContainer);
  }
}

// Par de colores para el gradiente de fondo de cada slide
List<Color> _slideGradient(int page, ColorScheme cs) {
  switch (page) {
    case 1:
      return [cs.secondaryContainer, cs.surface];
    case 2:
      return [cs.tertiaryContainer, cs.surface];
    default:
      return [cs.primaryContainer, cs.surface];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal del onboarding
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

/// StatefulWidget solo para ciclo de vida de controladores de animación y página.
/// La lógica de negocio (página actual, completar tutorial) vive en OnboardingProvider.
class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;

  // Ícono sube y baja suavemente en loop (2.5s por ciclo)
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  // Botón "Siguiente" late suavemente para guiar al usuario
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  // Anillo exterior del ícono se expande y desvanece en loop
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -7.0, end: 7.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────

  void _nextPage(OnboardingProvider provider) {
    if (provider.isLastPage) return;
    _pageController.animateToPage(
      provider.currentPage + 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    await context.read<OnboardingProvider>().completeOnboarding();
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: const LoginPage(),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, provider, _) {
        final cs = Theme.of(context).colorScheme;

        // AnimatedContainer interpola el gradiente suavemente entre slides
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _slideGradient(provider.currentPage, cs),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, provider, cs),
                  _buildIconArea(provider, cs),
                  _buildTextPageView(provider, cs),
                  _buildDots(provider, cs),
                  const SizedBox(height: 16),
                  _buildButtons(context, provider, cs),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Secciones ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(
      BuildContext context, OnboardingProvider provider, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 72),
          Text(
            '${provider.currentPage + 1} / ${OnboardingProvider.totalPages}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
          ),
          // Botón discreto — se oculta en el último slide
          AnimatedOpacity(
            opacity: provider.isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: provider.isLastPage,
              child: TextButton(
                onPressed: () => _completeOnboarding(context),
                style: TextButton.styleFrom(
                  foregroundColor: cs.onSurface.withValues(alpha: 0.55),
                ),
                child: const Text('Omitir'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Área del ícono: flotación en loop + anillo ripple + AnimatedSwitcher en la entrada.
  Widget _buildIconArea(OnboardingProvider provider, ColorScheme cs) {
    return Expanded(
      child: Center(
        // Capa 1: translación vertical para el efecto float
        child: AnimatedBuilder(
          animation: _floatAnimation,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          ),
          // "child" fijo: no se reconstruye en cada frame del float
          child: provider.currentPage == 0
              ? Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                )
              : _buildIconWithRing(provider, cs),
        ),
      ),
    );
  }

  /// Contenedor circular del ícono + anillo exterior animado tipo ripple.
  Widget _buildIconWithRing(OnboardingProvider provider, ColorScheme cs) {
    final colors = _iconColors(provider.currentPage, cs);

    return AnimatedBuilder(
      animation: _rippleController,
      builder: (_, child) {
        final t = _rippleController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Anillo ripple: se expande de 1.0→1.55 y se desvanece
            Transform.scale(
              scale: 1.0 + t * 0.55,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: (1 - t) * 0.4),
                    width: 2.5,
                  ),
                ),
              ),
            ),
            // Anillo estático interior — da profundidad al contenedor
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
            ),
            // Contenedor principal: sombra + color según slide
            child!,
          ],
        );
      },
      // El ícono con AnimatedSwitcher es el "child" fijo del ripple builder
      // para que no se reconstruya en cada frame de la animación del anillo
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.container,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.22),
              blurRadius: 22,
              spreadRadius: 4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // AnimatedSwitcher: el ícono entra con fade + slide desde abajo
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Icon(
            _kSlides[provider.currentPage].icon,
            key: ValueKey(provider.currentPage),
            size: 36,
            color: colors.onContainer,
          ),
        ),
      ),
    );
  }

  /// PageView con glassmorphism card.
  /// El AnimatedBuilder hace fade del contenido según la posición de scroll:
  /// fade + desplazamiento lateral combinados producen el efecto pedido.
  Widget _buildTextPageView(OnboardingProvider provider, ColorScheme cs) {
    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: provider.goToPage,
        itemCount: _kSlides.length,
        itemBuilder: (_, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (_, child) {
              // Opacidad basada en distancia al centro: fade sincronizado con el slide lateral
              var opacity = 1.0;
              if (_pageController.hasClients && _pageController.page != null) {
                opacity =
                    (1.0 - (_pageController.page! - index).abs()).clamp(0.25, 1.0);
              }
              return Opacity(opacity: opacity, child: child);
            },
            child: _buildGlassCard(_kSlides[index], cs),
          );
        },
      ),
    );
  }

  /// Tarjeta con efecto glassmorphism (fondo semitransparente + blur).
  Widget _buildGlassCard(_SlideData slide, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: cs.primary.withValues(alpha: 0.14),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.62),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dots con efecto stretch: el activo se alarga horizontalmente.
  Widget _buildDots(OnboardingProvider provider, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_kSlides.length, (i) {
          final isActive = i == provider.currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            // Efecto stretch: 28px cuando activo, 8px cuando inactivo
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  /// Botones con animaciones:
  /// - "Siguiente": pulso suave en loop (AnimatedBuilder + _pulseAnimation)
  /// - "Comenzar": escala de entrada (AnimatedScale + AnimatedOpacity)
  Widget _buildButtons(
      BuildContext context, OnboardingProvider provider, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Botón "Siguiente" con pulso ───────────────────────────────
            AnimatedOpacity(
              opacity: provider.isLastPage ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: IgnorePointer(
                ignoring: provider.isLastPage,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => _nextPage(provider),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: cs.primary.withValues(alpha: 0.4),
                      ),
                      child: const Text('Siguiente'),
                    ),
                  ),
                ),
              ),
            ),

            // ── Botón "Comenzar" con escala de entrada ────────────────────
            IgnorePointer(
              ignoring: !provider.isLastPage,
              child: AnimatedOpacity(
                opacity: provider.isLastPage ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedScale(
                  scale: provider.isLastPage ? 1.0 : 0.75,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _completeOnboarding(context),
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text(
                        'Comenzar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: cs.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
