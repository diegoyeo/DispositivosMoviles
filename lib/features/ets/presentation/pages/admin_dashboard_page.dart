import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    final catalogoCompleto = etsProvider.catalogoCompleto;
    final totalExamenes = catalogoCompleto.length;
    final totalISC = catalogoCompleto.where((e) => e.carrera == 'ISC').length;
    final totalLCD = catalogoCompleto.where((e) => e.carrera == 'LCD').length;
    final totalIIA = catalogoCompleto.where((e) => e.carrera == 'IIA').length;

    final examenesMostrados = catalogoCompleto.where((exam) {
      final coincideCarrera =
          _selectedCareer == 'Todas' || exam.carrera == _selectedCareer;
      final materiaLimpia =
          _quitarAcentos(exam.materia.toLowerCase());
      final queryLimpia = _quitarAcentos(_searchQuery.toLowerCase());
      return coincideCarrera && materiaLimpia.contains(queryLimpia);
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
                      context,
                      'Total',
                      totalExamenes,
                      cs.primary,
                      cs.primaryContainer,
                      'Todas',
                      cs,
                    ),
                    _buildStatCard(
                      context,
                      'ISC',
                      totalISC,
                      cs.secondary,
                      cs.secondaryContainer,
                      'ISC',
                      cs,
                    ),
                    _buildStatCard(
                      context,
                      'LCD',
                      totalLCD,
                      cs.tertiary,
                      cs.tertiaryContainer,
                      'LCD',
                      cs,
                    ),
                    _buildStatCard(
                      context,
                      'IIA',
                      totalIIA,
                      cs.outline,
                      cs.surfaceContainerHighest,
                      'IIA',
                      cs,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

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
                                      title: Text(
                                        exam.materia,
                                        style: tt.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${exam.carrera} · Sem ${exam.semestre} · ${exam.fecha}',
                                        style: tt.bodySmall?.copyWith(
                                          color: cs.onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                                          Navigator.pop(
                                                              ctx),
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
                                                          if (!context.mounted) {
                                                            return;
                                                          }
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Examen eliminado del catálogo'),
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          if (!context.mounted) {
                                                            return;
                                                          }
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                e.toString().replaceFirst('Exception: ', ''),
                                                              ),
                                                              backgroundColor: Colors.red,
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
  // Shadow + border viven en el mismo AnimatedContainer → sin clipping.
  // Seleccionada: siempre morado (primary). No seleccionada: neutro con tinte.

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
  });
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
  }
}
