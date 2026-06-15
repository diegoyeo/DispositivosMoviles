import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/ets_provider.dart';
import '../widgets/app_drawers.dart';
import 'admin_dashboard_page.dart';
import 'login_page.dart';
import 'settings_page.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _anim1;
  late final Animation<double> _anim2;
  late final Animation<double> _anim3;
  late final Animation<double> _anim4;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _anim1 = _stagger(0.00, 0.40);
    _anim2 = _stagger(0.20, 0.60);
    _anim3 = _stagger(0.40, 0.80);
    _anim4 = _stagger(0.60, 1.00);
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  static const Map<String, int> _meses = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
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

  Widget _slideIn(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.20),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  Widget _scaleIn(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      child: Builder(builder: _buildContent),
    );
  }

  Widget _buildContent(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final catalogo = etsProvider.catalogoCompleto;
    final total = catalogo.length;

    final hoy = DateTime.now().toUtc();
    final futuros = catalogo
        .where((e) {
          try {
            return !_parseFecha(e.fecha).isBefore(hoy);
          } catch (_) {
            return false;
          }
        })
        .toList()
      ..sort(
          (a, b) => _parseFecha(a.fecha).compareTo(_parseFecha(b.fecha)));
    final proximo = futuros.isNotEmpty ? futuros.first : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: AdminDrawer(
        onNavigateHome: () {
          Navigator.pop(context);
        },
        onNavigatePanel: () {
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
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
      body: Stack(
        children: [
          // ── Fondo degradado a pantalla completa ───────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary, cs.primaryContainer],
                ),
              ),
            ),
          ),

          // ── Contenido distribuido uniformemente ───────────────────────
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Ícono + Título ────────────────────────────────
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _scaleIn(
                          _anim1,
                          Center(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _slideIn(
                          _anim2,
                          Column(
                            children: [
                              Text(
                                'Bienvenido,',
                                style: tt.headlineMedium?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.w300,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Administrador',
                                style: tt.headlineLarge?.copyWith(
                                  color: cs.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Panel de Gestión ETS · ESCOM',
                                style: tt.bodyMedium?.copyWith(
                                  color: cs.onPrimary.withValues(alpha: 0.85),
                                  letterSpacing: 0.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ── Tarjeta resumen glassmorphism ─────────────────
                    _slideIn(
                      _anim3,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 26, horizontal: 20),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: cs.onPrimary.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _AdminStat(
                                    icon: Icons.quiz_rounded,
                                    value: total == 0
                                        ? '—'
                                        : total.toString(),
                                    label: 'ETS\nregistrados',
                                    cs: cs,
                                    tt: tt,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: cs.onPrimary.withValues(alpha: 0.25),
                                ),
                                Expanded(
                                  child: _AdminStat(
                                    icon: Icons.event_rounded,
                                    value: proximo != null
                                        ? proximo.materia
                                            .split(' ')
                                            .take(2)
                                            .join(' ')
                                        : '—',
                                    label: proximo != null
                                        ? proximo.fecha
                                        : 'Sin próximos',
                                    cs: cs,
                                    tt: tt,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Botón Ir al Panel ─────────────────────────────
                    _slideIn(
                      _anim4,
                      _PurpleButton(
                        label: 'Ir al Panel de Control',
                        icon: Icons.dashboard_rounded,
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboardPage()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón ☰ hamburguesa ───────────────────────────────────────
          Positioned(
            top: 48,
            left: 16,
            child: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estadística dentro de la tarjeta ────────────────────────────────────────

class _AdminStat extends StatelessWidget {
  const _AdminStat({
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
        Icon(icon, color: cs.onPrimary, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.onPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: cs.onPrimary.withValues(alpha: 0.85),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Botón con gradiente morado ───────────────────────────────────────────────

class _PurpleButton extends StatefulWidget {
  const _PurpleButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_PurpleButton> createState() => _PurpleButtonState();
}

class _PurpleButtonState extends State<_PurpleButton> {
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
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: cs.onPrimary, size: 22),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
