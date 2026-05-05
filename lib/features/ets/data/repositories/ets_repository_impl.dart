import '../../domain/entities/ets_exam.dart';
import '../datasources/ets_local_datasource.dart';
import '../models/ets_model.dart';

class EtsRepositoryImpl {
  final EtsLocalDataSource localDataSource;

  EtsRepositoryImpl({required this.localDataSource});

  // Este método guarda el examen y luego lo regresa
  Future<void> addExam(EtsExam exam) async {
    final model = EtsModel(
      materia: exam.materia,
      fecha: exam.fecha,
      turno: exam.turno,
      salon: exam.salon,
      profesor: exam.profesor,
      carrera: exam.carrera,
      semestre: exam.semestre,
    );
    await localDataSource.saveExam(model);
  }

  // Este saca todos los que estén guardados en el cel
  Future<List<EtsExam>> getAllExams() async {
    return await localDataSource.getExams();
  }
}