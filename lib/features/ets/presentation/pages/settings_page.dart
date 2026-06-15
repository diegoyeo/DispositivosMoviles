import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/providers/preferences_provider.dart';
import '../../../../../core/providers/theme_provider.dart';
import '../../../../../core/services/notification_service.dart';
import '../providers/auth_provider.dart';

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

  // Switches admin locales
  bool _alertasNuevos = true;
  bool _recordatoriosAdmin = true;

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

  // ── Componentes de sección ───────────────────────────────────────────────

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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cambiar contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Contraseña actual'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Nueva contraseña'),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar contraseña'),
                  validator: (v) => v != newCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();
                try {
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  await auth.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (mounted) {
                    _showSnackBar('Contraseña actualizada correctamente');
                  }
                } catch (e) {
                  if (mounted) {
                    _showSnackBar(
                      e.toString().replaceFirst('Exception: ', ''),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
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
    final initial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A';
    final email = auth.currentEmail ?? '';

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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.lock_outline_rounded,
                label: 'Cambiar contraseña',
                cs: cs,
                onTap: () => _showChangePasswordDialog(context),
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
                onChanged: (v) {
                  _toggleNotifications(v);
                },
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
            _animated(
              idx++,
              Opacity(
                opacity: 0.5,
                child: ListTile(
                  leading: Icon(Icons.email_outlined, color: cs.primary),
                  title: Row(
                    children: [
                      const Text('Notificaciones por correo'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                        content: Row(
                          children: const [
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

            // Tema oscuro/claro — conectado a ThemeProvider
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
                subtitle: Text(
                  themeProvider.isDark ? 'Activo' : 'Inactivo',
                ),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ),
            _divider(cs),

            // Carrera predeterminada — conectado a PreferencesProvider
            _animated(
              idx++,
              ListTile(
                leading: Icon(Icons.school_outlined, color: cs.primary),
                title: const Text('Carrera predeterminada'),
                subtitle: Text(
                  prefsProvider.defaultCarrera != null
                      ? prefsProvider.defaultCarrera!
                      : 'Sin preferencia',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: prefsProvider.defaultCarrera ?? 'ISC',
                  underline: const SizedBox(),
                  items: ['ISC', 'LCD', 'IIA']
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      prefsProvider.setDefaultCarrera(v);
                      _showSnackBar('Carrera predeterminada guardada');
                    }
                  },
                ),
              ),
            ),
            _divider(cs),

            // Semestre predeterminado — conectado a PreferencesProvider
            _animated(
              idx++,
              ListTile(
                leading:
                    Icon(Icons.layers_outlined, color: cs.primary),
                title: const Text('Semestre predeterminado'),
                subtitle: Text(
                  prefsProvider.defaultSemestre != null
                      ? 'Semestre ${prefsProvider.defaultSemestre}'
                      : 'Sin preferencia',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                trailing: DropdownButton<String>(
                  value: prefsProvider.defaultSemestre ?? '1',
                  underline: const SizedBox(),
                  items: ['1', '2', '3', '4', '5', '6', '7', '8', '9']
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      prefsProvider.setDefaultSemestre(v);
                      _showSnackBar('Semestre predeterminado guardado');
                    }
                  },
                ),
              ),
            ),

            // ── Acerca de ────────────────────────────────────────────────
            _animated(idx++, _sectionHeader('Acerca de', cs, tt)),
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.info_outline_rounded,
                label: 'Versión de la app',
                subtitle: 'v1.0.0 — MOVIDA ETS ESCOM',
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                  icon: Icons.gavel_rounded,
                  label: 'Términos y condiciones',
                  cs: cs),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Política de privacidad',
                  cs: cs),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Calificar la app',
                  cs: cs),
            ),
            const SizedBox(height: 32),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            _animated(
              idx++,
              _arrowTile(
                icon: Icons.lock_outline_rounded,
                label: 'Cambiar contraseña',
                cs: cs,
                onTap: () => _showChangePasswordDialog(context),
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
                subtitle: Text(themeProvider.isDark ? 'Activo' : 'Inactivo'),
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
              idx++,
              _arrowTile(
                icon: Icons.info_outline_rounded,
                label: 'Versión de la app',
                subtitle: 'v1.0.0 — MOVIDA ETS ESCOM (Admin)',
                cs: cs,
              ),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                  icon: Icons.description_outlined,
                  label: 'Documentación técnica',
                  cs: cs),
            ),
            _divider(cs),
            _animated(
              idx++,
              _arrowTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Soporte',
                  cs: cs),
            ),
            const SizedBox(height: 32),
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
