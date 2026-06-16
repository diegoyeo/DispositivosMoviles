import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/providers/preferences_provider.dart';
import 'package:dispositivos_moviles/features/catalogos/providers/catalogos_provider.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawers.dart';
import 'login_page.dart';
import 'exam_detail_page.dart';
import 'register_page.dart';
import 'saved_exams_page.dart';
import 'settings_page.dart';

class EtsHomePage extends StatefulWidget {
  const EtsHomePage({super.key});

  @override
  State<EtsHomePage> createState() => _EtsHomePageState();
}

class _EtsHomePageState extends State<EtsHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _listCtrl;
  PreferencesProvider? _trackedPrefs;

  String _carreraFiltro = 'Todas';
  String _semestreFiltro = 'Todos';

  static const List<String> _semestres = [
    'Todos', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];
  static const List<String> _carreraFallback = ['ISC', 'LCD', 'IIA'];

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CatalogosProvider>(context, listen: false).loadCarreras();

      final pref = Provider.of<PreferencesProvider>(context, listen: false);
      final ets = Provider.of<EtsProvider>(context, listen: false);

      _applyPreferences(pref, ets);
      _trackedPrefs = pref;
      pref.addListener(_onPreferencesChanged);
    });
  }

  void _applyPreferences(PreferencesProvider pref, EtsProvider ets) {
    final rol =
        Provider.of<AuthProvider>(context, listen: false).currentRole ?? '';
    final carrera = rol == 'alumno' ? pref.defaultCarrera : null;
    final semestre = rol == 'alumno' ? pref.defaultSemestre : null;
    setState(() {
      _carreraFiltro = carrera ?? 'Todas';
      _semestreFiltro = semestre ?? 'Todos';
    });
    ets.filtrarPorCarrera(carrera);
    ets.filtrarPorSemestre(semestre);
  }

  void _onPreferencesChanged() {
    if (!mounted) return;
    final pref = Provider.of<PreferencesProvider>(context, listen: false);
    final ets = Provider.of<EtsProvider>(context, listen: false);
    _applyPreferences(pref, ets);
    _listCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _trackedPrefs?.removeListener(_onPreferencesChanged);
    _listCtrl.dispose();
    super.dispose();
  }

  void _selectCarrera(String value, EtsProvider ets) {
    setState(() => _carreraFiltro = value);
    ets.filtrarPorCarrera(value == 'Todas' ? null : value);
    _listCtrl.forward(from: 0);
  }

  void _selectSemestre(String value, EtsProvider ets) {
    setState(() => _semestreFiltro = value);
    ets.filtrarPorSemestre(value == 'Todos' ? null : value);
    _listCtrl.forward(from: 0);
  }

  Animation<double> _itemAnim(int index, int total) {
    final start = (index / (total + 1)).clamp(0.0, 0.85);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _listCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    final catalogos = Provider.of<CatalogosProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esInvitado = auth.currentRole == null;

    final carreraNames = catalogos.carreras.isEmpty
        ? _carreraFallback
        : catalogos.carreras.map((c) => c.nombre).toList();
    final todasCarreras = ['Todas', ...carreraNames];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examenes Disponibles'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),

      drawer: esInvitado
          ? GuestDrawer(
              onNavigateHome: () {
                Navigator.pop(context);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onNavigateExams: () => Navigator.pop(context),
              onNavigateLogin: () {
                etsProvider.limpiarFiltros();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              onNavigateRegister: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                );
              },
            )
          : AlumnoDrawer(
              onNavigateHome: () {
                Navigator.pop(context);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onNavigateExams: () => Navigator.pop(context),
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
                etsProvider.limpiarFiltros();
                auth.logout();
                Provider.of<PreferencesProvider>(context, listen: false)
                    .resetToDefaults();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),

      body: Column(
        children: [
          // ── Barra de búsqueda ─────────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              onChanged: etsProvider.buscarPorMateria,
              decoration: InputDecoration(
                labelText: 'Buscar Unidad de Aprendizaje...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
          ),

          // ── Filtros con chips ─────────────────────────────────────────────
          Container(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FilterChipRow(
                  label: 'Carrera',
                  chips: todasCarreras,
                  selected: _carreraFiltro,
                  onChipTap: (v) => _selectCarrera(v, etsProvider),
                ),
                const SizedBox(height: 8),
                _FilterChipRow(
                  label: 'Semestre',
                  chips: _semestres,
                  selected: _semestreFiltro,
                  onChipTap: (v) => _selectSemestre(v, etsProvider),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // ── Lista de resultados ───────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: etsProvider.examenesFiltrados.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Text(
                        'No se encontraron resultados',
                        style: tt.bodyLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      key: ValueKey('${_carreraFiltro}_$_semestreFiltro'),
                      animation: _listCtrl,
                      builder: (context, _) {
                        final examenes = etsProvider.examenesFiltrados;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: examenes.length,
                          itemBuilder: (context, index) {
                            final exam = examenes[index];
                            final anim = _itemAnim(index, examenes.length);
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.15),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: _ExamCard(
                                  exam: exam,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExamDetailPage(exam: exam),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de chips con etiqueta y scroll horizontal ────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.label,
    required this.chips,
    required this.selected,
    required this.onChipTap,
  });

  final String label;
  final List<String> chips;
  final String selected;
  final ValueChanged<String> onChipTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
        ScrollConfiguration(
          behavior:
              ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(chips.length, (i) {
                return Padding(
                  padding: EdgeInsets.only(right: i < chips.length - 1 ? 8 : 0),
                  child: _SelectableChip(
                    label: chips[i],
                    selected: chips[i] == selected,
                    onTap: () => onChipTap(chips[i]),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Chip individual con animación de color y escala al presionar ──────────────

class _SelectableChip extends StatefulWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                Icon(Icons.check_rounded, size: 16, color: cs.onPrimary),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected ? cs.onPrimary : cs.onSurfaceVariant,
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

// ─── Tarjeta de examen ─────────────────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam, required this.onTap});
  final dynamic exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      color: cs.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: cs.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.materia,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exam.carrera} · Semestre ${exam.semestre}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
