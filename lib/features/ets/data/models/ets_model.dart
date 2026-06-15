import '../../domain/entities/ets_exam.dart';

class EtsModel extends EtsExam {
  EtsModel({
    super.id,
    required super.materia,
    required super.fecha,
    required super.turno,
    required super.salon,
    required super.profesor,
    required super.carrera,
    required super.semestre,
    super.visible = true,
  });

  factory EtsModel.fromJson(Map<String, dynamic> json) {
    return EtsModel(
      id: json['id'] as int?,
      materia: json['materia'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      turno: json['turno'] as String? ?? '',
      salon: json['salon'] as String? ?? '',
      profesor: json['profesor'] as String? ?? '',
      carrera: json['carrera'] as String? ?? '',
      semestre: json['semestre'] as int? ?? 0,
      visible: (json['visible'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'materia': materia,
        'fecha': fecha,
        'turno': turno,
        'salon': salon,
        'profesor': profesor,
        'carrera': carrera,
        'semestre': semestre,
        'visible': visible ? 1 : 0,
      };
}
