import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/ets_exam.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawers.dart';
import 'exam_detail_page.dart';
import 'login_page.dart';
import 'settings_page.dart';
import '../../../../core/services/ics_service.dart';
import '../../../../core/utils/error_handler.dart';

class SavedExamsPage extends StatefulWidget {
  const SavedExamsPage({super.key});

  @override
  State<SavedExamsPage> createState() => _SavedExamsPageState();
}

class _SavedExamsPageState extends State<SavedExamsPage>
    with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.utc(2026, 6, 1);
  DateTime? _selectedDay;
  Map<DateTime, List<EtsExam>> _examenesPorDia = {};

  late final AnimationController _pulseCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarExamenes();

    // Pulso suave en botón PDF
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Slide de lista al cambiar día
    _slideCtrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _cargarExamenes() async {
    final email = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).currentEmail;
    if (email != null) {
      final etsProvider = Provider.of<EtsProvider>(context, listen: false);
      await etsProvider.loadSavedExams(email);
      _agruparExamenes(etsProvider.misExamenesGuardados);
    }
  }

  DateTime _parsearFecha(String fechaStr) {
    final meses = {
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

    try {
      final partes = fechaStr.toLowerCase().split('-');
      int dia = int.parse(partes[0]);
      int mes = meses[partes[1]] ?? 6;
      int anio = partes.length == 3 ? int.parse(partes[2]) : 2026;

      return DateTime.utc(anio, mes, dia);
    } catch (e) {
      return DateTime.utc(2026, 6, 1);
    }
  }

  void _agruparExamenes(List<EtsExam> examenes) {
    Map<DateTime, List<EtsExam>> data = {};
    for (var exam in examenes) {
      DateTime fechaReal = _parsearFecha(exam.fecha);
      if (data[fechaReal] == null) {
        data[fechaReal] = [];
      }
      data[fechaReal]!.add(exam);
    }
    setState(() {
      _examenesPorDia = data;
    });
  }

  List<EtsExam> _getExamenesDelDia(DateTime day) {
    return _examenesPorDia[day] ?? [];
  }

  // ── Generación de PDF INTACTA ──────────────────────────────────────────────

  Future<void> _generarYCompartirPDF(List<EtsExam> examenes) async {
    if (examenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay examenes para exportar')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando documento PDF...')),
    );

    final pdf = pw.Document();

    examenes.sort(
      (a, b) => _parsearFecha(a.fecha).compareTo(_parsearFecha(b.fecha)),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Mi Calendario de ETS - ESCOM',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Fecha', 'Turno', 'Materia', 'Salon'],
                data: examenes
                    .map((e) => [e.fecha, e.turno, e.materia, e.salon])
                    .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Generado automaticamente desde Gestor de ETS',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Calendario_ETS_ESCOM.pdf',
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    _agruparExamenes(etsProvider.misExamenesGuardados);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final examenesHoy = _getExamenesDelDia(_selectedDay!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Calendario de ETS'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Exportar a iCalendar (.ics)',
            onPressed: () async {
              final examenes = etsProvider.misExamenesGuardados;
              if (examenes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'No tienes exámenes guardados para exportar',
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
                return;
              }
              try {
                await IcsService.exportCalendar(examenes);
              } catch (e) {
                if (context.mounted) ErrorHandler.show(context, e);
              }
            },
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) =>
                Transform.scale(scale: _pulse.value, child: child),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar a PDF',
              onPressed: () =>
                  _generarYCompartirPDF(etsProvider.misExamenesGuardados),
            ),
          ),
        ],
      ),

      drawer: Builder(
        builder: (ctx) {
          final auth = Provider.of<AuthProvider>(ctx, listen: false);
          return AlumnoDrawer(
            onNavigateHome: () {
              Navigator.pop(ctx);
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            onNavigateExams: () {
              Navigator.pop(ctx);
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            onNavigateCalendar: () => Navigator.pop(ctx),
            onNavigateSettings: () {
              Navigator.pop(ctx);
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            onLogout: () {
              auth.logout();
              Navigator.pushReplacement(
                ctx,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
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
        child: Column(
          children: [
            // ── Calendario ────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar<EtsExam>(
                firstDay: DateTime.utc(2026, 1, 1),
                lastDay: DateTime.utc(2026, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getExamenesDelDia,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedTextStyle: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  weekendTextStyle: TextStyle(
                    color: cs.error.withValues(alpha: 0.7),
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: cs.primary,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.primary,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _slideCtrl
                    ..reset()
                    ..forward();
                },
              ),
            ),

            Divider(
              height: 20,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: cs.outlineVariant,
            ),

            // ── Lista de exámenes del día ──────────────────────────────────
            Expanded(
              child: examenesHoy.isEmpty
                  ? _buildEmptyState(cs, tt)
                  : AnimatedBuilder(
                      animation: _slideCtrl,
                      builder: (_, _) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: examenesHoy.length,
                          itemBuilder: (context, index) {
                            final exam = examenesHoy[index];
                            final start =
                                (index / (examenesHoy.length + 1))
                                    .clamp(0.0, 0.70);
                            final anim = CurvedAnimation(
                              parent: _slideCtrl,
                              curve: Interval(
                                start,
                                (start + 0.55).clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(anim),
                                child: _CalendarExamCard(
                                  exam: exam,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
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
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 64,
            color: cs.onSurface.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin exámenes este día',
            style: tt.titleMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Guarda exámenes desde la lista\npara verlos en tu calendario',
            style: tt.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de examen en el calendario ──────────────────────────────────────

class _CalendarExamCard extends StatelessWidget {
  const _CalendarExamCard({required this.exam, required this.onTap});
  final EtsExam exam;
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bookmark_added_rounded,
                  color: cs.onPrimaryContainer,
                  size: 20,
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
                      '${exam.turno} · Salón ${exam.salon}',
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
