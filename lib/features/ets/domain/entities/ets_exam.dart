class EtsExam {
  final int? id;
  final String materia;
  final String fecha;
  final String turno;
  final String salon;
  final String profesor;
  final String carrera;
  final int semestre;

  EtsExam({
    this.id,
    required this.materia,
    required this.fecha,
    required this.turno,
    required this.salon,
    required this.profesor,
    required this.carrera,
    required this.semestre,
  });
}
