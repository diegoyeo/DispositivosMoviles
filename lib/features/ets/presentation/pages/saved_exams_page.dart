import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
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
  // Configuración del calendario
  DateTime _focusedDay = DateTime.utc(
    2026,
    6,
    1,
  ); // Centramos el calendario en Junio 2026
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

      // Aseguramos que los datos estén actualizados
      await etsProvider.loadSavedExams(email);

      // Transformamos la lista a un Mapa ordenado por fechas
      _agruparExamenes(etsProvider.misExamenesGuardados);
    }
  }

  // --- TRADUCTOR DE FECHAS DE TEXTO A DATETIME ---
  DateTime _parsearFecha(String fechaStr) {
    // Ejemplo de entrada: '15-Junio-2026'
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
      int mes = meses[partes[1]] ?? 6; // Por defecto Junio
      int anio = partes.length == 3 ? int.parse(partes[2]) : 2026;

      // Usamos UTC para que TableCalendar no tenga problemas de zonas horarias
      return DateTime.utc(anio, mes, dia);
    } catch (e) {
      return DateTime.utc(2026, 6, 1); // Fecha de respaldo en caso de error
    }
  }

  // --- AGRUPAR EXÁMENES POR DÍA ---
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

  // Obtener los exámenes de un día específico para pintarlos debajo del calendario
  List<EtsExam> _getExamenesDelDia(DateTime day) {
    return _examenesPorDia[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Leemos los cambios del provider para re-agrupar si el usuario elimina un examen
    final etsProvider = Provider.of<EtsProvider>(context);
    _agruparExamenes(etsProvider.misExamenesGuardados);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Calendario de ETS'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // --- EL WIDGET DE CALENDARIO ---
          TableCalendar<EtsExam>(
            firstDay: DateTime.utc(2026, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader:
                _getExamenesDelDia, // Pinta los puntitos de los exámenes
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
              ), // Puntito del examen
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false, // Ocultamos el botón de "2 weeks"
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay =
                    focusedDay; // Actualiza el mes si toca un día del mes siguiente
              });
            },
          ),

          const Divider(thickness: 2),

          // --- LA LISTA DE EXÁMENES DEL DÍA SELECCIONADO ---
          Expanded(
            child: _getExamenesDelDia(_selectedDay!).isEmpty
                ? const Center(
                    child: Text(
                      'No tienes exámenes agendados este día 🏖️',
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
                            '${exam.turno} | Salón: ${exam.salon}',
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
