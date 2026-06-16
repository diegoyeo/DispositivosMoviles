import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/ets/domain/entities/ets_exam.dart';

class IcsService {
  const IcsService();

  static String _formatDate(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}'
        '${date.second.toString().padLeft(2, '0')}Z';
  }

  static String _parseFecha(String fechaStr) {
    const meses = {
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
    final partes = fechaStr.toLowerCase().split('-');
    final dia = int.parse(partes[0].trim());
    final mes = meses[partes[1].trim()] ?? 1;
    final anio = int.parse(partes[2].trim());
    return _formatDate(DateTime(anio, mes, dia));
  }

  static Future<void> exportCalendar(List<EtsExam> examenes) async {
    final buffer = StringBuffer();
    final now = _formatDateTime(DateTime.now().toUtc());

    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//MOVIDA//ETS ESCOM//ES');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');
    buffer.writeln('X-WR-CALNAME:Mis ETS ESCOM');
    buffer.writeln('X-WR-TIMEZONE:America/Mexico_City');

    for (final examen in examenes) {
      final fechaIcs = _parseFecha(examen.fecha);

      final horaInicio = examen.turno == 'Matutino' ? '080000' : '160000';
      final horaFin = examen.turno == 'Matutino' ? '100000' : '180000';
      final uid = examen.id ?? examen.materia.hashCode.abs();

      buffer.writeln('BEGIN:VEVENT');
      buffer.writeln('UID:$uid-movida-ets@escom');
      buffer.writeln('DTSTAMP:$now');
      buffer.writeln(
        'DTSTART;TZID=America/Mexico_City:${fechaIcs}T$horaInicio',
      );
      buffer.writeln(
        'DTEND;TZID=America/Mexico_City:${fechaIcs}T$horaFin',
      );
      buffer.writeln('SUMMARY:ETS ${examen.materia}');
      buffer.writeln(
        'DESCRIPTION:Carrera: ${examen.carrera}\\n'
        'Semestre: ${examen.semestre}\\n'
        'Turno: ${examen.turno}\\n'
        'Salón: ${examen.salon}\\n'
        'Profesor: ${examen.profesor}',
      );
      buffer.writeln(
        'LOCATION:ESCOM IPN - Salón ${examen.salon}\\,'
        ' Av. Juan de Dios Bátiz\\,'
        ' Gustavo A. Madero\\, CDMX',
      );
      buffer.writeln('STATUS:CONFIRMED');
      buffer.writeln(
        'CATEGORIES:ETS\\,ESCOM\\,${examen.carrera}',
      );
      buffer.writeln('BEGIN:VALARM');
      buffer.writeln('TRIGGER:-P1D');
      buffer.writeln('ACTION:DISPLAY');
      buffer.writeln(
        'DESCRIPTION:Recordatorio: Mañana tienes ETS de ${examen.materia}',
      );
      buffer.writeln('END:VALARM');
      buffer.writeln('END:VEVENT');
    }

    buffer.writeln('END:VCALENDAR');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/mis_ets_escom.ics');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/calendar')],
        subject: 'Mi Calendario ETS ESCOM — MOVIDA',
      ),
    );
  }
}
