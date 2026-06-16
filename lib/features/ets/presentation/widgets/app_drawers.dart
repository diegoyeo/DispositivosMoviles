import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../catalogos/pages/carreras_page.dart';
import '../../../catalogos/pages/salones_page.dart';
import '../../../map/pages/campus_map_page.dart';

// ─── AdminDrawer ──────────────────────────────────────────────────────────────
// Requiere ser usado dentro de un Theme morado para respetar la paleta admin.

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({
    super.key,
    required this.onNavigateHome,
    required this.onNavigatePanel,
    required this.onNavigateSettings,
    required this.onLogout,
  });
  final VoidCallback onNavigateHome;
  final VoidCallback onNavigatePanel;
  final VoidCallback onNavigateSettings;
  final VoidCallback onLogout;

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _a(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.10).clamp(0.0, 0.65),
          ((i * 0.10) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  Widget _tile(
    int i,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _a(i),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.25, 0),
          end: Offset.zero,
        ).animate(_a(i)),
        child: ListTile(
          leading: Icon(
            icon,
            color: destructive ? cs.error : cs.primary,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: destructive ? cs.error : cs.onSurface,
              fontWeight:
                  destructive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: cs.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Modo Administrador',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'admin@escom.ipn.mx',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          _tile(0, Icons.home_rounded, 'Inicio', widget.onNavigateHome),
          _tile(1, Icons.list_alt_rounded, 'Gestión de ETS',
              widget.onNavigatePanel),
          _tile(2, Icons.school_rounded, 'Gestión de Carreras', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CarrerasPage()));
          }),
          _tile(3, Icons.meeting_room_rounded, 'Gestión de Edificios/Salones', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SalonesPage()));
          }),
          _tile(4, Icons.settings_rounded, 'Ajustes',
              widget.onNavigateSettings),

          const Divider(),

          _tile(
            5,
            Icons.logout_rounded,
            'Cerrar Sesión',
            widget.onLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

// ─── AlumnoDrawer ─────────────────────────────────────────────────────────────

class AlumnoDrawer extends StatefulWidget {
  const AlumnoDrawer({
    super.key,
    required this.onNavigateHome,
    required this.onNavigateExams,
    required this.onNavigateCalendar,
    required this.onNavigateSettings,
    required this.onLogout,
  });
  final VoidCallback onNavigateHome;
  final VoidCallback onNavigateExams;
  final VoidCallback onNavigateCalendar;
  final VoidCallback onNavigateSettings;
  final VoidCallback onLogout;

  @override
  State<AlumnoDrawer> createState() => _AlumnoDrawerState();
}

class _AlumnoDrawerState extends State<AlumnoDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _a(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.10).clamp(0.0, 0.65),
          ((i * 0.10) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  Widget _tile(
    int i,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _a(i),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.25, 0),
          end: Offset.zero,
        ).animate(_a(i)),
        child: ListTile(
          leading: Icon(icon, color: destructive ? cs.error : cs.primary),
          title: Text(
            label,
            style: TextStyle(
              color: destructive ? cs.error : cs.onSurface,
              fontWeight:
                  destructive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getNombre(String? email) {
    if (email == null || email.isEmpty) return 'Alumno';
    final prefix = email.split('@').first;
    if (prefix.isEmpty) return 'Alumno';
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nombre = _getNombre(auth.currentEmail);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0] : 'A',
                      style: tt.headlineSmall?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  nombre,
                  style: tt.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (auth.currentEmail != null)
                  Text(
                    auth.currentEmail!,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          _tile(0, Icons.home_rounded, 'Inicio', widget.onNavigateHome),
          _tile(1, Icons.search_rounded, 'Ver Exámenes Disponibles',
              widget.onNavigateExams),
          _tile(2, Icons.calendar_month_rounded, 'Mi Calendario de ETS',
              widget.onNavigateCalendar),
          _tile(3, Icons.bookmark_rounded, 'Mis ETS Guardados',
              widget.onNavigateCalendar),
          _tile(4, Icons.settings_rounded, 'Ajustes',
              widget.onNavigateSettings),
          _tile(5, Icons.map_rounded, 'Mapa del Campus', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder<void>(
                transitionDuration:
                    const Duration(milliseconds: 350),
                pageBuilder: (ctx, animation, _) =>
                    const CampusMapPage(),
                transitionsBuilder: (ctx, animation, _, child) =>
                    SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
            );
          }),

          const Divider(),

          _tile(
            6,
            Icons.logout_rounded,
            'Cerrar Sesión',
            widget.onLogout,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

// ─── GuestDrawer ──────────────────────────────────────────────────────────────

class GuestDrawer extends StatefulWidget {
  const GuestDrawer({
    super.key,
    required this.onNavigateHome,
    required this.onNavigateExams,
    required this.onNavigateLogin,
    required this.onNavigateRegister,
  });
  final VoidCallback onNavigateHome;
  final VoidCallback onNavigateExams;
  final VoidCallback onNavigateLogin;
  final VoidCallback onNavigateRegister;

  @override
  State<GuestDrawer> createState() => _GuestDrawerState();
}

class _GuestDrawerState extends State<GuestDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Animation<double> _a(int i) => CurvedAnimation(
        parent: _ctrl,
        curve: Interval(
          (i * 0.12).clamp(0.0, 0.65),
          ((i * 0.12) + 0.50).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  Widget _tile(
    int i,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool highlighted = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _a(i),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-0.25, 0),
          end: Offset.zero,
        ).animate(_a(i)),
        child: ListTile(
          leading: Icon(
            icon,
            color: highlighted ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: highlighted ? cs.primary : cs.onSurface,
              fontWeight:
                  highlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: cs.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Modo Invitado',
                  style: tt.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sin sesión activa',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),

          // Banner glassmorphism
          FadeTransition(
            opacity: _a(0),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-0.25, 0),
                end: Offset.zero,
              ).animate(_a(0)),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_open_rounded,
                        color: cs.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Inicia sesión para acceder a todas las funciones',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          _tile(1, Icons.home_rounded, 'Inicio', widget.onNavigateHome),
          _tile(2, Icons.search_rounded, 'Ver Exámenes Disponibles',
              widget.onNavigateExams),
          _tile(3, Icons.login_rounded, 'Iniciar Sesión',
              widget.onNavigateLogin,
              highlighted: true),
          _tile(4, Icons.person_add_rounded, 'Registrarse como Alumno',
              widget.onNavigateRegister),
          _tile(5, Icons.map_rounded, 'Mapa del Campus', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder<void>(
                transitionDuration:
                    const Duration(milliseconds: 350),
                pageBuilder: (ctx, animation, _) =>
                    const CampusMapPage(),
                transitionsBuilder: (ctx, animation, _, child) =>
                    SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
