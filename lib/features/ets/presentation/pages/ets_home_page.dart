import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/providers/preferences_provider.dart';
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

  String _carreraFiltro = 'Todas';
  String _semestreFiltro = 'Todos';

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentRole == null) return; // invitado: sin preferencias

      final pref =
          Provider.of<PreferencesProvider>(context, listen: false);
      final ets = Provider.of<EtsProvider>(context, listen: false);

      final carrera = pref.defaultCarrera;
      final semestre = pref.defaultSemestre;

      if (carrera != null) {
        setState(() => _carreraFiltro = carrera);
        ets.filtrarPorCarrera(carrera);
      }
      if (semestre != null) {
        setState(() => _semestreFiltro = semestre);
        ets.filtrarPorSemestre(semestre);
      }
    });
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
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
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final esInvitado = auth.currentRole == null;

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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),

      body: Column(
        children: [
          // ── Zona de filtros ──────────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Dropdown Carrera — controlado por estado local
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Carrera',
                        value: _carreraFiltro,
                        items: const ['Todas', 'ISC', 'LCD', 'IIA'],
                        cs: cs,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _carreraFiltro = v);
                          etsProvider.filtrarPorCarrera(
                              v == 'Todas' ? null : v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Dropdown Semestre — controlado por estado local
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Semestre',
                        value: _semestreFiltro,
                        items: const [
                          'Todos',
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                        ],
                        cs: cs,
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _semestreFiltro = v);
                          etsProvider.filtrarPorSemestre(
                              v == 'Todos' ? null : v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // ── Lista de resultados ──────────────────────────────────────────
          Expanded(
            child: etsProvider.examenesFiltrados.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron resultados',
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : AnimatedBuilder(
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ExamDetailPage(exam: exam),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Dropdown de filtro con InputDecoration y valor controlado ─────────────────

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.cs,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ColorScheme cs;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString()),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Tarjeta de examen ────────────────────────────────────────────────────────

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
