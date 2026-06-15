import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/ets_exam.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawers.dart';
import 'add_exam_page.dart';
import 'edit_exam_page.dart';
import 'home_admin_page.dart';
import 'login_page.dart';
import 'settings_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _selectedCareer = 'Todas';
  String _visibilityFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _fabCtrl;
  late final AnimationController _listCtrl;
  late final Animation<double> _fabPulse;

  String _quitarAcentos(String texto) {
    const conAcento = 'áéíóúÁÉÍÓÚüÜñÑ';
    const sinAcento = 'aeiouAEIOUuUnN';
    String resultado = texto;
    for (int i = 0; i < conAcento.length; i++) {
      resultado = resultado.replaceAll(conAcento[i], sinAcento[i]);
    }
    return resultado;
  }

  @override
  void initState() {
    super.initState();

    _fabCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _fabPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabCtrl, curve: Curves.easeInOut),
    );

    _listCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EtsProvider>().loadAllExams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Animation<double> _itemAnim(int index, int total) {
    final start = (index / (total + 1)).clamp(0.0, 0.80);
    return CurvedAnimation(
      parent: _listCtrl,
      curve: Interval(start, (start + 0.45).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
  }

  void _confirmToggleVisibility(
    BuildContext context,
    EtsExam exam,
    EtsProvider etsProvider,
    ColorScheme cs,
  ) {
    final willHide = exam.visible;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willHide ? 'Ocultar examen' : 'Mostrar examen'),
        content: Text(
          willHide
              ? '¿Ocultar este examen? Los alumnos no podrán verlo en las búsquedas pero quienes ya lo guardaron seguirán viéndolo en su calendario'
              : '¿Mostrar este examen? Volverá a aparecer en las búsquedas de todos los alumnos',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await etsProvider.toggleVisibility(exam.id!, !exam.visible);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(willHide ? 'Examen ocultado' : 'Examen visible'),
                  backgroundColor: willHide ? Colors.orange : Colors.green,
                ));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: cs.error,
                ));
              }
            },
            child: Text(
              willHide ? 'Ocultar' : 'Mostrar',
              style: TextStyle(
                color: willHide ? Colors.orange : cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    final etsProvider = Provider.of<EtsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final adminCatalogo = etsProvider.adminCatalogo;
    final totalExamenes = adminCatalogo.length;
    final totalISC = adminCatalogo.where((e) => e.carrera == 'ISC').length;
    final totalLCD = adminCatalogo.where((e) => e.carrera == 'LCD').length;
    final totalIIA = adminCatalogo.where((e) => e.carrera == 'IIA').length;

    final examenesMostrados = adminCatalogo.where((exam) {
      final coincideCarrera =
          _selectedCareer == 'Todas' || exam.carrera == _selectedCareer;
      final materiaLimpia = _quitarAcentos(exam.materia.toLowerCase());
      final queryLimpia = _quitarAcentos(_searchQuery.toLowerCase());
      final coincideTexto = materiaLimpia.contains(queryLimpia);
      final coincideVisibilidad = _visibilityFilter == 'Todos' ||
          (_visibilityFilter == 'Visibles' && exam.visible) ||
          (_visibilityFilter == 'Ocultos' && !exam.visible);
      return coincideCarrera && coincideTexto && coincideVisibilidad;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control Admin'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
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
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Estadísticas y Filtros',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // ── Tarjetas de estadísticas ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      context, 'Total', totalExamenes,
                      cs.primary, cs.primaryContainer, 'Todas', cs,
                    ),
                    _buildStatCard(
                      context, 'ISC', totalISC,
                      cs.secondary, cs.secondaryContainer, 'ISC', cs,
                    ),
                    _buildStatCard(
                      context, 'LCD', totalLCD,
                      cs.tertiary, cs.tertiaryContainer, 'LCD', cs,
                    ),
                    _buildStatCard(
                      context, 'IIA', totalIIA,
                      cs.outline, cs.surfaceContainerHighest, 'IIA', cs,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Filtro de visibilidad ──────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Todos', 'Visibles', 'Ocultos'].map((filter) {
                    final isSelected = _visibilityFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _visibilityFilter = filter),
                        selectedColor: cs.primaryContainer,
                        checkmarkColor: cs.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? cs.onPrimaryContainer
                              : cs.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 10),

              // ── Buscador ───────────────────────────────────────────────
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar materia (sin importar acentos)...',
                  prefixIcon: Icon(Icons.search, color: cs.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: cs.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: cs.surface.withValues(alpha: 0.8),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: cs.outlineVariant),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gestión de Oferta',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${examenesMostrados.length} resultados',
                    style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Lista ──────────────────────────────────────────────────
              Expanded(
                child: examenesMostrados.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron materias',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _listCtrl,
                        builder: (_, _) {
                          return ListView.builder(
                            itemCount: examenesMostrados.length,
                            itemBuilder: (context, index) {
                              final exam = examenesMostrados[index];
                              final anim =
                                  _itemAnim(index, examenesMostrados.length);
                              return FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.12),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: Opacity(
                                    opacity: exam.visible ? 1.0 : 0.5,
                                    child: Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: cs.outlineVariant
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      color: cs.surface.withValues(alpha: 0.85),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 4),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: cs.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.menu_book_rounded,
                                            color: cs.onPrimaryContainer,
                                            size: 20,
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            if (!exam.visible) ...[
                                              const Icon(
                                                Icons.visibility_off,
                                                size: 14,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                exam.materia,
                                                style: tt.titleSmall?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${exam.carrera} · Sem ${exam.semestre} · ${exam.fecha}',
                                              style: tt.bodySmall?.copyWith(
                                                color: cs.onSurface
                                                    .withValues(alpha: 0.55),
                                              ),
                                            ),
                                            if (!exam.visible)
                                              const Text(
                                                '(Oculto)',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _ScaleButton(
                                              icon: exam.visible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: exam.visible
                                                  ? cs.primary
                                                  : Colors.grey,
                                              tooltip: exam.visible
                                                  ? 'Ocultar examen'
                                                  : 'Mostrar examen',
                                              onPressed: () =>
                                                  _confirmToggleVisibility(
                                                      context,
                                                      exam,
                                                      etsProvider,
                                                      cs),
                                            ),
                                            _ScaleButton(
                                              icon: Icons.edit_rounded,
                                              color: cs.primary,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditExamPage(
                                                            exam: exam),
                                                  ),
                                                );
                                              },
                                            ),
                                            _ScaleButton(
                                              icon: Icons.delete_rounded,
                                              color: cs.error,
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (ctx) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Confirmar eliminación'),
                                                    content: Text(
                                                      '¿Eliminar el ETS de ${exam.materia}?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(ctx),
                                                        child: const Text(
                                                            'Cancelar'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          Navigator.pop(ctx);
                                                          try {
                                                            await etsProvider
                                                                .borrarExamenDelCatalogo(
                                                                    exam.materia);
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            ScaffoldMessenger
                                                                .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Examen eliminado del catálogo'),
                                                              ),
                                                            );
                                                          } catch (e) {
                                                            if (!context
                                                                .mounted) {
                                                              return;
                                                            }
                                                            ScaffoldMessenger
                                                                .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  e.toString().replaceFirst(
                                                                      'Exception: ',
                                                                      ''),
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text(
                                                          'Eliminar',
                                                          style: TextStyle(
                                                              color: cs.error),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
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
            ],
          ),
        ),
      ),

      floatingActionButton: AnimatedBuilder(
        animation: _fabCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _fabPulse.value, child: child),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExamPage()),
            );
          },
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nuevo ETS',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ── Tarjeta de estadística ─────────────────────────────────────────────────

  Widget _buildStatCard(
    BuildContext context,
    String title,
    int count,
    Color fg,
    Color bg,
    String careerCode,
    ColorScheme cs,
  ) {
    final isSelected = _selectedCareer == careerCode;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedCareer = careerCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer
              : bg.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.75)
                : fg.withValues(alpha: 0.30),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? cs.primary : cs.shadow)
                  .withValues(alpha: isSelected ? 0.28 : 0.08),
              blurRadius: isSelected ? 14 : 5,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: count.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) {
                return Text(
                  value.toInt().toString(),
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? cs.onPrimaryContainer : fg,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? cs.onPrimaryContainer
                    : cs.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botón icónico con efecto de escala al presionar ──────────────────────────

class _ScaleButton extends StatefulWidget {
  const _ScaleButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.tooltip,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.82 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(widget.icon, color: widget.color, size: 22),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}
