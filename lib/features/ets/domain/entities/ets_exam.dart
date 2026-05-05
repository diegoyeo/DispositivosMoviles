class EtsExam {
  final String materia;
  final String fecha;
  final String turno;
  final String salon;
  final String profesor;
  final String carrera; // Para el buscador inteligente
  final int semestre;   // Para el buscador inteligente

  EtsExam({
    required this.materia,
    required this.fecha,
    required this.turno,
    required this.salon,
    required this.profesor,
    required this.carrera,
    required this.semestre,
  });
}