import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/providers/preferences_provider.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/services/biometric_service.dart';
import '../../../../../core/services/notification_service.dart';
import '../providers/auth_provider.dart';

// Estado de los botones animados dentro de los diálogos
enum _SaveState { idle, saving, success }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;

  static const _kNotifKey = 'notifications_enabled';

  bool _recordatorios = false;
  String _anticipacion = '1 día antes';

  bool _alertasNuevos = true;
  bool _recordatoriosAdmin = true;

  bool _bioAvailable = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _recordatorios = prefs.getBool(_kNotifKey) ?? false;
        });
      }
    });

    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final available = await BiometricService.isAvailable();
    final creds = available ? await BiometricService.getCredentials() : null;
    if (!mounted) return;
    setState(() {
      _bioAvailable = available;
      _bioEnabled = creds != null;
    });
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Animation<double> _a(int i) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(
          (i * 0.06).clamp(0.0, 0.70),
          ((i * 0.06) + 0.40).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  Widget _animated(int i, Widget child) => FadeTransition(
        opacity: _a(i),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(_a(i)),
          child: child,
        ),
      );

  // ── Componentes reutilizables ────────────────────────────────────────────

  Widget _sectionHeader(String title, ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ColorScheme cs,
  }) {
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _arrowTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required ColorScheme cs,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: cs.primary),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, indent: 56, color: cs.outlineVariant);

  // ── Helpers de navegación / snackbar ─────────────────────────────────────

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFloatingSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // Transición compartida para todos los diálogos animados
  Widget _dialogTransition(
    BuildContext ctx,
    Animation<double> anim,
    Animation<double> _,
    Widget child,
  ) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      );

  // ── Diálogo cambiar contraseña (animado) ──────────────────────────────────

  Future<void> _showChangePasswordDialog(BuildContext ctx) async {
    await showGeneralDialog<void>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Cambiar contraseña',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, _, _) => const _ChangePasswordDialog(),
    );
    // Refrescar estado de huella por si la contraseña fue cambiada
    if (!mounted) return;
    final creds = await BiometricService.getCredentials();
    if (!mounted) return;
    setState(() => _bioEnabled = creds != null);
  }

  // ── Toggle biometría ──────────────────────────────────────────────────────

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      final authed = await BiometricService.authenticate();
      if (!mounted) return;
      if (!authed) {
        _showFloatingSnackBar('Autenticación fallida. Intenta de nuevo');
        return;
      }
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentEmail == null) return;
      final confirmed =
          await _showBioConfirmDialog(context, auth.currentEmail!);
      if (!mounted) return;
      if (confirmed) setState(() => _bioEnabled = true);
    } else {
      final confirmed = await _showBioDisableDialog(context);
      if (!mounted) return;
      if (confirmed) {
        await BiometricService.clearCredentials();
        if (!mounted) return;
        setState(() => _bioEnabled = false);
        _showFloatingSnackBar('Huella desvinculada');
      }
    }
  }

  Future<bool> _showBioConfirmDialog(BuildContext ctx, String email) async {
    final result = await showGeneralDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Confirmar contraseña',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, _, _) => _BioConfirmDialog(email: email),
    );
    return result == true;
  }

  Future<bool> _showBioDisableDialog(BuildContext ctx) async {
    final result = await showGeneralDialog<bool>(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: 'Desactivar huella',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: _dialogTransition,
      pageBuilder: (context, _, _) => AlertDialog(
        title: const Text('Desactivar huella'),
        content: const Text(
          '¿Deseas desactivar el inicio de sesión con huella digital?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ── Notificaciones ────────────────────────────────────────────────────────

  Future<void> _toggleNotifications(bool enable) async {
    if (enable) {
      final granted = await NotificationService().requestPermissions();
      if (!mounted) return;
      if (granted) {
        setState(() => _recordatorios = true);
        (await SharedPreferences.getInstance()).setBool(_kNotifKey, true);
        _showSnackBar('Notificaciones activadas');
      } else {
        _showSnackBar('Debes permitir notificaciones en Ajustes del sistema');
      }
    } else {
      await NotificationService().cancelAllNotifications();
      if (!mounted) return;
      setState(() => _recordatorios = false);
      (await SharedPreferences.getInstance()).setBool(_kNotifKey, false);
      _showSnackBar('Notificaciones desactivadas');
    }
  }

  // ── Versión Alumno ────────────────────────────────────────────────────────

  Widget _buildAlumno(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final prefsProvider = Provider.of<PreferencesProvider>(context);

    final nombre = auth.currentNombre ?? '';
    final apellido = auth.currentApellido ?? '';
    final nombreCompleto = '$nombre $apellido'.trim();
    final nombreCap = nombreCompleto.isNotEmpty ? nombreCompleto : 'Alumno';
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A';
    final email = auth.currentEmail ?? '';

    const carreraOpts = ['Sin preferencia', 'ISC', 'LCD', 'IIA'];
    const semestreOpts = [
      'Sin preferencia',
      '1', '2', '3', '4', '5', '6', '7', '8', '9',
    ];

    var idx = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer.withValues(alpha: 0.3), cs.surface],
          ),
        ),
        child: ListView(
          children: [
            // ── Cuenta ───────────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Cuenta', cs, tt)),
            _animated(
              idx++,
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          initial,
                          style: tt.headlineMedium?.copyWith(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombreCap,
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              email,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Cambiar contraseña con escala al presionar
            _animated(
              idx++,
              _ScaleWrapper(
                onTap: () => _showChangePasswordDialog(context),
                child: _arrowTile(
                  icon: Icons.lock_outline_rounded,
                  label: 'Cambiar contraseña',
                  cs: cs,
                ),
              ),
            ),
            // Huella digital — siempre visible, con estado dinámico
            _divider(cs),
            _animated(
              idx++,
              ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  color: _bioAvailable
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
                title: const Text('Inicio de sesión con huella'),
                subtitle: Text(
                  !_bioAvailable
                      ? 'Tu dispositivo no soporta huella digital'
                      : _bioEnabled
                          ? 'Vinculada · Toca para desactivar'
                          : 'Toca para vincular tu huella',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: !_bioAvailable
                    ? Icon(Icons.block,
                        color: cs.onSurface.withValues(alpha: 0.4))
                    : Switch(
                        value: _bioEnabled,
                        onChanged: _toggleBiometric,
                      ),
              ),
            ),

            // ── Notificaciones ───────────────────────────────────────────
            _animated(idx++, _sectionHeader('Notificaciones', cs, tt)),
            _animated(
              idx++,
              _switchTile(
                icon: Icons.notifications_outlined,
                label: 'Activar recordatorios de ETS',
                value: _recordatorios,
                onChanged: _toggleNotifications,
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              ListTile(
                leading: Icon(Icons.schedule_rounded, color: cs.primary),
                title: const Text('Anticipación del recordatorio'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: '1 día antes', label: Text('1 día')),
                      ButtonSegment(
                          value: '3 días antes', label: Text('3 días')),
                      ButtonSegment(
                          value: '1 semana antes', label: Text('1 sem')),
                    ],
                    selected: {_anticipacion},
                    onSelectionChanged: (v) =>
                        setState(() => _anticipacion = v.first),
                  ),
                ),
                isThreeLine: true,
              ),
            ),
            _divider(cs),
            // Notificaciones por correo — deshabilitado, próximamente
            _animated(
              idx++,
              Opacity(
                opacity: 0.5,
                child: ListTile(
                  leading: Icon(Icons.email_outlined, color: cs.primary),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          'Notificaciones por correo',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Próximamente',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: IgnorePointer(
                    child: Switch(value: false, onChanged: null),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Las notificaciones por correo estarán '
                                'disponibles en una próxima actualización',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: cs.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Preferencias ─────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Preferencias', cs, tt)),
            _animated(
              idx++,
              ListTile(
                leading: Icon(
                  themeProvider.isDark
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  color: cs.primary,
                ),
                title: const Text('Tema oscuro'),
                subtitle: Text(themeProvider.isDark ? 'Activo' : 'Inactivo'),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ),
            _divider(cs),
            // Carrera predeterminada con chips
            _animated(
              idx++,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.school_outlined, color: cs.primary),
                        const SizedBox(width: 16),
                        Text('Carrera predeterminada',
                            style: tt.bodyLarge),
                      ],
                    ),
                  ),
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.fromLTRB(56, 0, 16, 12),
                      child: Row(
                        children:
                            List.generate(carreraOpts.length, (i) {
                          final opt = carreraOpts[i];
                          final sel = opt == 'Sin preferencia'
                              ? prefsProvider.defaultCarrera == null
                              : opt == prefsProvider.defaultCarrera;
                          return Padding(
                            padding: EdgeInsets.only(
                                right:
                                    i < carreraOpts.length - 1 ? 8 : 0),
                            child: _PrefChip(
                              label: opt,
                              selected: sel,
                              onTap: () {
                                prefsProvider.setDefaultCarrera(
                                    opt == 'Sin preferencia'
                                        ? null
                                        : opt);
                                _showFloatingSnackBar(
                                    'Preferencia guardada');
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _divider(cs),
            // Semestre predeterminado con chips
            _animated(
              idx++,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        Icon(Icons.layers_outlined, color: cs.primary),
                        const SizedBox(width: 16),
                        Text('Semestre predeterminado',
                            style: tt.bodyLarge),
                      ],
                    ),
                  ),
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.fromLTRB(56, 0, 16, 12),
                      child: Row(
                        children:
                            List.generate(semestreOpts.length, (i) {
                          final opt = semestreOpts[i];
                          final sel = opt == 'Sin preferencia'
                              ? prefsProvider.defaultSemestre == null
                              : opt == prefsProvider.defaultSemestre;
                          return Padding(
                            padding: EdgeInsets.only(
                                right: i < semestreOpts.length - 1
                                    ? 8
                                    : 0),
                            child: _PrefChip(
                              label: opt,
                              selected: sel,
                              onTap: () {
                                prefsProvider.setDefaultSemestre(
                                    opt == 'Sin preferencia'
                                        ? null
                                        : opt);
                                _showFloatingSnackBar(
                                    'Preferencia guardada');
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Acerca de ────────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Acerca de', cs, tt)),
            _animated(idx++, const _AcercaDeCard()),
            _animated(
              idx++,
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: Text(
                  '© 2026 MOVIDA · ESCOM IPN',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Versión Admin ─────────────────────────────────────────────────────────

  Widget _buildAdmin(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    var idx = 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.primaryContainer.withValues(alpha: 0.3), cs.surface],
          ),
        ),
        child: ListView(
          children: [
            // ── Cuenta Admin ─────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Cuenta Admin', cs, tt)),
            _animated(
              idx++,
              Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: cs.primaryContainer,
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 32,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: -2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: cs.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cs.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.verified,
                                size: 12,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administrador',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'admin@escom.ipn.mx',
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Gestión del Sistema ───────────────────────────────────────
            _animated(
                idx++, _sectionHeader('Gestión del Sistema', cs, tt)),
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Exportar todos los ETS a PDF',
                subtitle: 'Solo visual',
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.backup_rounded,
                label: 'Respaldar datos',
                subtitle: 'Solo visual',
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.history_rounded,
                label: 'Ver logs de actividad',
                subtitle: 'Solo visual',
                cs: cs,
              ),
            ),

            // ── Apariencia ────────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Apariencia', cs, tt)),
            _animated(
              idx++,
              ListTile(
                leading: Icon(
                  themeProvider.isDark
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                  color: cs.primary,
                ),
                title: const Text('Tema oscuro'),
                subtitle:
                    Text(themeProvider.isDark ? 'Activo' : 'Inactivo'),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ),

            // ── Notificaciones Admin ──────────────────────────────────────
            _animated(
                idx++, _sectionHeader('Notificaciones Admin', cs, tt)),
            _animated(
              idx++,
              _switchTile(
                icon: Icons.person_add_outlined,
                label: 'Alertas de nuevos registros',
                value: _alertasNuevos,
                onChanged: (v) => setState(() => _alertasNuevos = v),
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              _switchTile(
                icon: Icons.notifications_outlined,
                label: 'Recordatorios de ETS próximos',
                value: _recordatoriosAdmin,
                onChanged: (v) => setState(() => _recordatoriosAdmin = v),
                cs: cs,
              ),
            ),

            // ── Acerca de ────────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Acerca de', cs, tt)),
            _animated(
                idx++, const _AcercaDeCard(isAdmin: true)),
            _animated(
              idx++,
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 24),
                child: Text(
                  '© 2026 MOVIDA · ESCOM IPN',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build principal ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.currentRole == 'admin';

    if (isAdmin) {
      return Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        child: Builder(builder: _buildAdmin),
      );
    }

    return _buildAlumno(context);
  }
}

// ─── Wrapper de escala al presionar ───────────────────────────────────────────

class _ScaleWrapper extends StatefulWidget {
  const _ScaleWrapper({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleWrapper> createState() => _ScaleWrapperState();
}

class _ScaleWrapperState extends State<_ScaleWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      );
}

// ─── Diálogo cambiar contraseña con animación de botón ────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _SaveState _saveState = _SaveState.idle;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Capturar referencia antes de cualquier await
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Verificar si había huella activa antes de cambiar contraseña
    final hadBio = await BiometricService.getCredentials();

    setState(() => _saveState = _SaveState.saving);
    try {
      await auth.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );

      // La contraseña cambió: invalidar credenciales biométricas guardadas
      await BiometricService.clearCredentials();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);

      setState(() => _saveState = _SaveState.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      nav.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: const Text('Contraseña actualizada correctamente'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));

      if (hadBio != null) {
        messenger.showSnackBar(SnackBar(
          content: const Text(
              'Huella desvinculada. Vincúlala de nuevo en Ajustes'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveState = _SaveState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _saveState != _SaveState.idle;
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) =>
                  v != _newCtrl.text ? 'Las contraseñas no coinciden' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _save,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _saveState == _SaveState.saving
                ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : _saveState == _SaveState.success
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('success'),
                        color: Colors.green,
                      )
                    : const Text('Guardar', key: ValueKey('idle')),
          ),
        ),
      ],
    );
  }
}

// ─── Diálogo confirmar contraseña para activar huella ─────────────────────────

class _BioConfirmDialog extends StatefulWidget {
  const _BioConfirmDialog({required this.email});
  final String email;

  @override
  State<_BioConfirmDialog> createState() => _BioConfirmDialogState();
}

class _BioConfirmDialogState extends State<_BioConfirmDialog> {
  final _passwordCtrl = TextEditingController();
  _SaveState _saveState = _SaveState.idle;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Ingresa tu contraseña');
      return;
    }
    // Capturar referencia antes del primer await
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _saveState = _SaveState.saving;
      _error = null;
    });
    try {
      final ok = await auth.login(widget.email, _passwordCtrl.text);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _saveState = _SaveState.idle;
          _error = auth.lastError ?? 'Contraseña incorrecta';
        });
        return;
      }
      await BiometricService.saveCredentials(
        correo: widget.email,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      setState(() => _saveState = _SaveState.success);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      nav.pop(true);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: const Text('Huella vinculada correctamente'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveState = _SaveState.idle;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _saveState != _SaveState.idle;
    return AlertDialog(
      title: const Text('Confirma tu contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Para activar la huella, confirma tu contraseña actual.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => isBusy ? null : _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: isBusy ? null : _confirm,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _saveState == _SaveState.saving
                ? const SizedBox(
                    key: ValueKey('saving'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : _saveState == _SaveState.success
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey('success'),
                        color: Colors.green,
                      )
                    : const Text('Confirmar', key: ValueKey('idle')),
          ),
        ),
      ],
    );
  }
}

// ─── Chip de preferencia (carrera / semestre) ─────────────────────────────────

class _PrefChip extends StatefulWidget {
  const _PrefChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PrefChip> createState() => _PrefChipState();
}

class _PrefChipState extends State<_PrefChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? cs.primary
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.selected) ...[
                Icon(Icons.check_rounded,
                    size: 16, color: cs.onPrimary),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected
                      ? cs.onPrimary
                      : cs.onSurfaceVariant,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta informativa "Acerca de" ─────────────────────────────────────────

class _AcercaDeCard extends StatelessWidget {
  const _AcercaDeCard({this.isAdmin = false});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Bloque versión (centrado, sin ícono)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  'MOVIDA ETS ESCOM',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  isAdmin ? 'Versión 1.0.0 · Admin' : 'Versión 1.0.0',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.5)),
          if (!isAdmin) ...[
            // Términos — solo informativo
            ListTile(
              leading: Icon(Icons.article_outlined,
                  color: cs.onSurfaceVariant),
              title: Text('Términos y Condiciones',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              subtitle: Text(
                'Al usar MOVIDA aceptas nuestros términos de uso y condiciones del servicio',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              isThreeLine: true,
            ),
            Divider(
                height: 1,
                indent: 56,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            // Privacidad — solo informativo
            ListTile(
              leading: Icon(Icons.privacy_tip_outlined,
                  color: cs.onSurfaceVariant),
              title: Text('Política de Privacidad',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              subtitle: Text(
                'Tus datos son almacenados de forma segura y no son compartidos con terceros',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              isThreeLine: true,
            ),
          ] else ...[
            // Admin: documentación
            ListTile(
              leading: Icon(Icons.description_outlined,
                  color: cs.onSurfaceVariant),
              title: Text('Documentación técnica',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              subtitle: Text(
                'Manual de administración del sistema MOVIDA ETS',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            Divider(
                height: 1,
                indent: 56,
                color: cs.outlineVariant.withValues(alpha: 0.5)),
            // Admin: soporte
            ListTile(
              leading: Icon(Icons.support_agent_rounded,
                  color: cs.onSurfaceVariant),
              title: Text('Soporte',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              subtitle: Text(
                'Contacta al equipo de soporte técnico del ESCOM IPN',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
