import '../../domain/entities/ets_exam.dart';
import '../datasources/ets_local_datasource.dart';
import '../models/ets_model.dart';

class EtsRepositoryImpl {
  final EtsLocalDataSource localDataSource;

  EtsRepositoryImpl({required this.localDataSource});

  // --- Métodos de Exámenes (Los que ya tenías) ---
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

  Future<List<EtsExam>> getAllExams() async {
    return await localDataSource.getExams();
  }

  // --- Métodos de Autenticación (NUEVOS) ---
  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    return await localDataSource.registerUser(
      nombre,
      apellido,
      correo,
      password,
    );
  }

  Future<String?> login(String correo, String password) async {
    return await localDataSource.loginUser(correo, password);
  }

  Future<void> saveExamToUser(String correo, String materia) async {
    // Cambiado a String
    await localDataSource.saveExamToUser(correo, materia);
  }

  Future<List<EtsExam>> getSavedExamsForUser(String correo) async {
    return await localDataSource.getSavedExamsForUser(correo);
  }

  Future<void> removeExamFromUser(String correo, String materia) async {
    await localDataSource.removeExamFromUser(correo, materia);
  }
}
