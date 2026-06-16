import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ets_exam.dart';
import '../providers/ets_provider.dart';
import '../../../catalogos/providers/catalogos_provider.dart';

class EditExamPage extends StatefulWidget {
  final EtsExam exam;

  const EditExamPage({super.key, required this.exam});

  @override
  State<EditExamPage> createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _materiaController;
  late TextEditingController _fechaController;
  late TextEditingController _profesorController;

  late String _carreraSeleccionada;
  late String _turnoSeleccionado;
  late int _semestreSeleccionado;
  String? _salonSeleccionado;

  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _materiaController = TextEditingController(text: widget.exam.materia);
    _fechaController = TextEditingController(text: widget.exam.fecha);
    _profesorController = TextEditingController(text: widget.exam.profesor.isNotEmpty ? widget.exam.profesor : 'Por asignar');

    _carreraSeleccionada = widget.exam.carrera;
    _turnoSeleccionado = widget.exam.turno;
    _semestreSeleccionado = widget.exam.semestre;
    _salonSeleccionado = widget.exam.salon.isNotEmpty ? widget.exam.salon : null;

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

  @override
  void dispose() {
    _materiaController.dispose();
    _fechaController.dispose();
    _profesorController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Lógica INTACTA ────────────────────────────────────────────────────────

  void _actualizarExamen() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<EtsProvider>(context, listen: false);

      try {
        await provider.actualizarExamen(
          widget.exam.materia,
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
          const SnackBar(content: Text('Examen actualizado correctamente')),
        );
        Navigator.pop(context, true);
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

  // ── Helpers de UI ─────────────────────────────────────────────────────────

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

  InputDecoration _dec(String label, IconData icon, ColorScheme cs) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface.withValues(alpha: 0.85),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: cs.outline.withValues(alpha: 0.30)),
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
    final cs = Theme.of(context).colorScheme;
    final catalogos = context.watch<CatalogosProvider>();
    final carreraItems = catalogos.carreras.isEmpty
        ? ['ISC', 'LCD', 'IIA']
        : catalogos.carreras.map((c) => c.nombre).toList();
    // Ensure existing salon value is valid; add it as option if not in list
    final salonNombres = catalogos.salones.map((s) => s.nombre).toList();
    final effectiveSalon = (_salonSeleccionado != null && !salonNombres.contains(_salonSeleccionado))
        ? null
        : _salonSeleccionado;

    final a0 = _stagger(0.00, 0.40);
    final a1 = _stagger(0.10, 0.50);
    final a2 = _stagger(0.20, 0.60);
    final a3 = _stagger(0.35, 0.75);
    final a4 = _stagger(0.50, 0.90);
    final a5 = _stagger(0.62, 1.00);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Datos del ETS'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primaryContainer.withValues(alpha: 0.08),
              cs.surface,
            ],
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
                  TextFormField(
                    controller: _materiaController,
                    validator: (v) =>
                        v!.isEmpty ? 'Campo requerido' : null,
                    decoration:
                        _dec('Materia', Icons.book_outlined, cs),
                  ),
                ),
                const SizedBox(height: 14),

                // Carrera + Semestre
                _slideIn(
                  a1,
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _carreraSeleccionada,
                          isExpanded: true,
                          decoration: _dec(
                              'Carrera', Icons.school_outlined, cs),
                          items: carreraItems
                              .map((c) => DropdownMenuItem(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _carreraSeleccionada = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          initialValue: _semestreSeleccionado,
                          isExpanded: true,
                          decoration: _dec('Semestre',
                              Icons.format_list_numbered, cs),
                          items: [1, 2, 3, 4, 5, 6, 7, 8]
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.toString())))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _semestreSeleccionado = val!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Fecha + Turno — flex 3:2 con isExpanded para evitar overflow
                _slideIn(
                  a2,
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _fechaController,
                          readOnly: true,
                          onTap: _pickFecha,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo requerido' : null,
                          decoration: _dec('Fecha',
                              Icons.calendar_today_outlined, cs).copyWith(
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _turnoSeleccionado,
                          isExpanded: true,
                          decoration: _dec(
                              'Turno', Icons.wb_sunny_outlined, cs),
                          items: ['Matutino', 'Vespertino']
                              .map((t) => DropdownMenuItem(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (val) => setState(
                              () => _turnoSeleccionado = val!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Salón
                _slideIn(
                  a3,
                  DropdownButtonFormField<String>(
                    key: ValueKey('salon_${catalogos.salones.length}'),
                    initialValue: effectiveSalon,
                    isExpanded: true,
                    decoration: _dec('Salón', Icons.room_outlined, cs),
                    validator: (v) => v == null ? 'Campo requerido' : null,
                    items: catalogos.salones
                        .map((s) => DropdownMenuItem(
                              value: s.nombre,
                              child: Text(s.displayName, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _salonSeleccionado = val),
                  ),
                ),
                const SizedBox(height: 14),

                // Profesor
                _slideIn(
                  a4,
                  TextFormField(
                    controller: _profesorController,
                    decoration: _dec('Profesor Titular',
                        Icons.person_outline_rounded, cs),
                  ),
                ),
                const SizedBox(height: 28),

                // Botón guardar con gradiente morado
                _slideIn(a5, _GradientSaveButton(onPressed: _actualizarExamen)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón gradiente morado con animación de escala ───────────────────────────

class _GradientSaveButton extends StatefulWidget {
  const _GradientSaveButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_GradientSaveButton> createState() => _GradientSaveButtonState();
}

class _GradientSaveButtonState extends State<_GradientSaveButton> {
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
                'Guardar Cambios',
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
