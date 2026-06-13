import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ets_exam.dart';
import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import '../widgets/app_drawers.dart';
import 'ets_home_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'saved_exams_page.dart';
import 'settings_page.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _enterCtrl;
  late final Animation<double> _float;
  late final Animation<double> _anim1;
  late final Animation<double> _anim2;
  late final Animation<double> _anim3;
  late final Animation<double> _anim4;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _float = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _anim1 = _stagger(0.00, 0.50);
    _anim2 = _stagger(0.15, 0.65);
    _anim3 = _stagger(0.30, 0.80);
    _anim4 = _stagger(0.45, 0.95);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentEmail != null) {
        Provider.of<EtsProvider>(context, listen: false)
            .loadSavedExams(auth.currentEmail!);
      }
    });
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _floatCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  String _getNombre(String? email) {
    if (email == null) return 'Alumno';
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'Alumno';
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  static const Map<String, int> _meses = {
    'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
    'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
    'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12,
  };

  DateTime _parseFecha(String fechaStr) {
    try {
      final partes = fechaStr.toLowerCase().split('-');
      final dia = int.parse(partes[0]);
      final mes = _meses[partes[1]] ?? 6;
      final anio = partes.length == 3 ? int.parse(partes[2]) : 2026;
      return DateTime.utc(anio, mes, dia);
    } catch (_) {
      return DateTime.utc(2026, 6, 1);
    }
  }

  EtsExam? _proximoExamen(List<EtsExam> exams) {
    if (exams.isEmpty) return null;
    final hoy = DateTime.now().toUtc();
    final futuros = exams
        .where((e) => !_parseFecha(e.fecha).isBefore(hoy))
        .toList()
      ..sort((a, b) => _parseFecha(a.fecha).compareTo(_parseFecha(b.fecha)));
    return futuros.isNotEmpty ? futuros.first : exams.first;
  }

  Widget _slideIn(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.22),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final etsProv = Provider.of<EtsProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esInvitado = auth.currentRole == null;
    final nombre = _getNombre(auth.currentEmail);
    final guardados = etsProv.misExamenesGuardados;
    final proximo = _proximoExamen(guardados);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor:
            esInvitado ? cs.onPrimaryContainer : cs.onPrimary,
      ),

      drawer: esInvitado
          ? GuestDrawer(
              onNavigateHome: () => Navigator.pop(context),
              onNavigateExams: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EtsHomePage()),
                );
              },
              onNavigateLogin: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              onNavigateRegister: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
            )
          : AlumnoDrawer(
              onNavigateHome: () => Navigator.pop(context),
              onNavigateExams: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EtsHomePage()),
                );
              },
              onNavigateCalendar: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedExamsPage()),
                );
              },
              onNavigateSettings: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              onLogout: () {
                auth.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: esInvitado
                ? [cs.primaryContainer, cs.surface]
                : [cs.primary, cs.primary, cs.primaryContainer, cs.surface],
            stops: esInvitado ? null : const [0.0, 0.28, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Saludo ────────────────────────────────────────────────
                _slideIn(_anim1, _buildHeader(cs, tt, esInvitado, nombre)),
                const SizedBox(height: 28),

                // ── Ícono birrete flotante ────────────────────────────────
                _slideIn(_anim2, _buildFloatingIcon(cs)),
                const SizedBox(height: 28),

                if (!esInvitado) ...[
                  // ── Tarjeta resumen (más prominente) ───────────────────
                  _slideIn(
                    _anim3,
                    _buildSummaryCard(cs, tt, guardados.length, proximo),
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  // ── Banner glassmorphism invitado ──────────────────────
                  _slideIn(_anim3, _buildGuestBanner(cs, tt)),
                  const SizedBox(height: 28),
                  _slideIn(
                    _anim4,
                    _DashButton(
                      label: 'Iniciar Sesión',
                      icon: Icons.login_rounded,
                      gradient: true,
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ColorScheme cs,
    TextTheme tt,
    bool esInvitado,
    String nombre,
  ) {
    final onColor = esInvitado ? cs.onSurface : cs.onPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          esInvitado ? '¡Bienvenido!' : '¡Bienvenido,',
          style: tt.headlineMedium?.copyWith(
            color: onColor,
            fontWeight: FontWeight.normal,
            fontSize: 22,
          ),
        ),
        if (!esInvitado)
          Text(
            '$nombre!',
            style: tt.headlineLarge?.copyWith(
              color: onColor,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          esInvitado
              ? 'Explora los exámenes ETS disponibles'
              : 'Alumno ESCOM · BRUZZY',
          style: tt.bodyMedium?.copyWith(
            color: onColor.withValues(alpha: esInvitado ? 0.65 : 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIcon(ColorScheme cs) {
    return Center(
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, _float.value), child: child),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cs.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.school_rounded,
            size: 54,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ColorScheme cs,
    TextTheme tt,
    int count,
    EtsExam? proximo,
  ) {
    final proximoLabel = proximo != null
        ? proximo.materia.split(' ').take(2).join(' ')
        : '—';
    final proximoSub =
        proximo != null ? proximo.fecha : 'Sin exámenes\npróximos';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.bookmark_added_rounded,
                  value: count.toString(),
                  label: 'ETS\nguardados',
                  cs: cs,
                  tt: tt,
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: cs.outlineVariant,
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.event_note_rounded,
                  value: proximoLabel,
                  label: proximoSub,
                  cs: cs,
                  tt: tt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestBanner(ColorScheme cs, TextTheme tt) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.star_outline_rounded, size: 40, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                'Desbloquea todas las funciones',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión para guardar tus exámenes, activar recordatorios y acceder a tu calendario personal.',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SummaryItem ──────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.cs,
    required this.tt,
  });
  final IconData icon;
  final String value;
  final String label;
  final ColorScheme cs;
  final TextTheme tt;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: cs.primary, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: tt.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Botón unificado (gradiente o outline) ────────────────────────────────────

class _DashButton extends StatefulWidget {
  const _DashButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool gradient;
  final VoidCallback onPressed;

  @override
  State<_DashButton> createState() => _DashButtonState();
}

class _DashButtonState extends State<_DashButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: widget.gradient
            ? _gradientContainer(cs)
            : _outlineContainer(cs),
      ),
    );
  }

  Widget _gradientContainer(ColorScheme cs) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _content(cs.onPrimary, cs.onPrimary),
    );
  }

  Widget _outlineContainer(ColorScheme cs) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: _content(cs.primary, cs.primary),
    );
  }

  Widget _content(Color iconColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          widget.label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
