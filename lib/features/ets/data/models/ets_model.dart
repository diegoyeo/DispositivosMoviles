import '../domain/entities/ets_exam.dart';

class EtsModel extends EtsExam {
  EtsModel({
    required super.materia,
    required super.fecha,
    required super.turno,
    required super.salon,
    required super.profesor,
    required super.carrera,
    required super.semestre,
  });

  // Requerimiento: fromJSON
  factory EtsModel.fromJson(Map<String, dynamic> json) {
    return EtsModel(
      materia: json['materia'] ?? '',
      fecha: json['fecha'] ?? '',
      turno: json['turno'] ?? '',
      salon: json['salon'] ?? '',
      profesor: json['profesor'] ?? '',
      carrera: json['carrera'] ?? '',
      semestre: json['semestre'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materia': materia,
      'fecha': fecha,
      'turno': turno,
      'salon': salon,
      'profesor': profesor,
      'carrera': carrera,
      'semestre': semestre,
    };
  }
}