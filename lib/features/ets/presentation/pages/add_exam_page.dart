import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawers.dart';
import '../../../catalogos/providers/catalogos_provider.dart';
import 'admin_dashboard_page.dart';
import 'home_admin_page.dart';
import 'login_page.dart';
import 'settings_page.dart';

class AddExamPage extends StatefulWidget {
  const AddExamPage({super.key});

  @override
  State<AddExamPage> createState() => _AddExamPageState();
}

class _AddExamPageState extends State<AddExamPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _materiaController = TextEditingController();
  final _fechaController = TextEditingController();
  final _profesorController = TextEditingController();

  String _carreraSeleccionada = 'ISC';
  String _turnoSeleccionado = 'Matutino';
  int _semestreSeleccionado = 1;
  String? _salonSeleccionado;

  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalogos = context.read<CatalogosProvider>();
      catalogos.loadCarreras();
      catalogos.loadSalones();
    });
  }

  @override
  void dispose() {
    _materiaController.dispose();
    _fechaController.dispose();
    _profesorController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );

  // ── Helpers de fecha ──────────────────────────────────────────────────────

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  String _formatFechaEs(DateTime d) => '${d.day}-${_meses[d.month]}-${d.year}';

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && mounted) {
      setState(() => _fechaController.text = _formatFechaEs(picked));
    }
  }

  // ── Lógica de negocio INTACTA ──────────────────────────────────────────────

  void _guardarExamen() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EtsProvider>(context, listen: false);

      try {
        await provider.agregarNuevoExamen(
          _materiaController.text,
          _carreraSeleccionada,
          _semestreSeleccionado,
          _fechaController.text,
          _turnoSeleccionado,
          _salonSeleccionado ?? '',
          _profesorController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Examen registrado correctamente')),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helper de campo ────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ?? (v) => v!.isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
      ),
    );
  }

  Widget _slideIn(Animation<double> anim, Widget child) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

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
    final auth = Provider.of<AuthProvider>(context);
    final catalogos = context.watch<CatalogosProvider>();
    final cs = Theme.of(context).colorScheme;
    final carreraItems = catalogos.carreras.isEmpty
        ? ['ISC', 'LCD', 'IIA']
        : catalogos.carreras.map((c) => c.nombre).toList();

    final a0 = _stagger(0.00, 0.40);
    final a1 = _stagger(0.10, 0.50);
    final a2 = _stagger(0.20, 0.60);
    final a3 = _stagger(0.30, 0.70);
    final a4 = _stagger(0.40, 0.80);
    final a5 = _stagger(0.50, 0.90);
    final a6 = _stagger(0.60, 1.00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Nuevo ETS'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      drawer: AdminDrawer(
        onNavigateHome: () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeAdminPage()),
            (route) => false,
          );
        },
        onNavigatePanel: () {
          Navigator.pop(context);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
            (route) => false,
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
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Materia
                _slideIn(
                  a0,
                  _buildField(
                    controller: _materiaController,
                    label: 'Unidad de Aprendizaje (Materia)',
                    icon: Icons.menu_book_rounded,
                  ),
                ),
                const SizedBox(height: 14),

                // Carrera + Semestre
                _slideIn(
                  a1,
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _carreraSeleccionada,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Carrera',
                            prefixIcon:
                                Icon(Icons.school_outlined, color: cs.primary),
                            filled: true,
                            fillColor: cs.surface.withValues(alpha: 0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: cs.outline.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 2),
                            ),
                          ),
                          items: carreraItems
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _carreraSeleccionada = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _semestreSeleccionado,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Semestre',
                            prefixIcon:
                                Icon(Icons.layers_rounded, color: cs.primary),
                            filled: true,
                            fillColor: cs.surface.withValues(alpha: 0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: cs.outline.withValues(alpha: 0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: cs.primary, width: 2),
                            ),
                          ),
                          items: [1, 2, 3, 4, 5, 6, 7, 8]
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.toString())))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _semestreSeleccionado = val!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Fecha
                _slideIn(
                  a2,
                  TextFormField(
                    controller: _fechaController,
                    readOnly: true,
                    onTap: _pickFecha,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    decoration: InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon:
                          Icon(Icons.calendar_today_rounded, color: cs.primary),
                      suffixIcon:
                          Icon(Icons.arrow_drop_down, color: cs.primary),
                      filled: true,
                      fillColor: cs.surface.withValues(alpha: 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.error, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Turno — isExpanded: true corrige el overflow
                _slideIn(
                  a3,
                  DropdownButtonFormField<String>(
                    initialValue: _turnoSeleccionado,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Turno',
                      prefixIcon:
                          Icon(Icons.access_time_rounded, color: cs.primary),
                      filled: true,
                      fillColor: cs.surface.withValues(alpha: 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: cs.outline.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary, width: 2),
                      ),
                    ),
                    items: ['Matutino', 'Vespertino']
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _turnoSeleccionado = val!),
                  ),
                ),
                const SizedBox(height: 14),

                // Salón
                _slideIn(
                  a4,
                  DropdownButtonFormField<String>(
                    initialValue: _salonSeleccionado,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Salón',
                      prefixIcon: Icon(Icons.room_rounded, color: cs.primary),
                      filled: true,
                      fillColor: cs.surface.withValues(alpha: 0.8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: cs.primary, width: 2)),
                    ),
                    validator: (v) => v == null ? 'Campo requerido' : null,
                    items: catalogos.salones
                        .map((s) => DropdownMenuItem(value: s.nombre, child: Text(s.displayName, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _salonSeleccionado = val),
                  ),
                ),
                const SizedBox(height: 14),

                // Profesor
                _slideIn(
                  a5,
                  _buildField(
                    controller: _profesorController,
                    label: 'Profesor Titular',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 28),

                // Botón guardar
                _slideIn(a6, _GradientButton(onPressed: _guardarExamen)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón gradiente morado ────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  const _GradientButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_rounded, color: cs.onPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Guardar Examen',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
