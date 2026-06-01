import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/ets_exam.dart';
import '../providers/ets_provider.dart';
import '../providers/auth_provider.dart';
import 'exam_detail_page.dart';

class SavedExamsPage extends StatefulWidget {
  const SavedExamsPage({super.key});

  @override
  State<SavedExamsPage> createState() => _SavedExamsPageState();
}

class _SavedExamsPageState extends State<SavedExamsPage> {
  DateTime _focusedDay = DateTime.utc(2026, 6, 1);
  DateTime? _selectedDay;
  Map<DateTime, List<EtsExam>> _examenesPorDia = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _cargarExamenes();
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

  // --- LOGICA DE GENERACION DE PDF ---
  Future<void> _generarYCompartirPDF(List<EtsExam> examenes) async {
    if (examenes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay examenes para exportar')),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Generando documento PDF...')));

    final pdf = pw.Document();

    // Ordenamos los examenes por fecha cronologica para el PDF
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

              // Tabla dinamica con los datos
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

    // Abre el dialogo nativo de Android para guardar en Drive, Archivos o enviar por WhatsApp
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Calendario_ETS_ESCOM.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final etsProvider = Provider.of<EtsProvider>(context);
    _agruparExamenes(etsProvider.misExamenesGuardados);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Calendario de ETS'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // --- BOTON DE EXPORTAR PDF ---
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: () =>
                _generarYCompartirPDF(etsProvider.misExamenesGuardados),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<EtsExam>(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getExamenesDelDia,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),

          const Divider(thickness: 2),

          Expanded(
            child: _getExamenesDelDia(_selectedDay!).isEmpty
                ? const Center(
                    child: Text(
                      'No tienes examenes agendados este dia',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _getExamenesDelDia(_selectedDay!).length,
                    itemBuilder: (context, index) {
                      final exam = _getExamenesDelDia(_selectedDay!)[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.bookmark_added,
                            color: Colors.green,
                          ),
                          title: Text(
                            exam.materia,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${exam.turno} | Salon: ${exam.salon}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
