import '../datasources/ets_local_datasource.dart';
import '../../domain/entities/ets_exam.dart';

class EtsRepositoryImpl {
  final EtsLocalDataSource localDataSource;

  EtsRepositoryImpl(this.localDataSource);

  // --- MÓDULO DE AUTENTICACIÓN ---
  Future<String?> login(String correo, String password) async {
    final emailLimpio = correo.trim().toLowerCase();
    final passLimpio = password.trim();

    if (emailLimpio == 'admin@escom.ipn.mx' && passLimpio == 'admin123') {
      return 'admin';
    }

    // Validación en Base de Datos para Alumnos
    try {
      final db = await localDataSource.database;
      final resultado = await db.query(
        'users',
        where: 'correo = ? AND password = ?',
        whereArgs: [emailLimpio, passLimpio],
      );

      if (resultado.isNotEmpty) {
        return 'alumno';
      }
    } catch (e) {
      // Si la tabla no existe o hay error, lo dejamos pasar como simulación
      if (emailLimpio.isNotEmpty && passLimpio.isNotEmpty) return 'alumno';
    }

    return null;
  }

  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    return await localDataSource.register(nombre, apellido, correo, password);
  }

  Future<void> updateExam(
    String oldMateria,
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    await localDataSource.updateExam(
      oldMateria,
      materia,
      carrera,
      semestre,
      fecha,
      turno,
      salon,
      profesor,
    );
  }

  // --- MÓDULO PÚBLICO ---
  Future<List<EtsExam>> getExams() async {
    return await localDataSource.getExams();
  }

  Future<void> saveExamToUser(String correo, String materia) async {
    await localDataSource.saveExamToUser(correo, materia);
  }

  Future<List<EtsExam>> getSavedExamsForUser(String correo) async {
    return await localDataSource.getSavedExamsForUser(correo);
  }

  Future<void> removeExamFromUser(String correo, String materia) async {
    await localDataSource.removeExamFromUser(correo, materia);
  }

  // --- MÓDULO ADMINISTRATIVO (CRUD) ---
  Future<void> addExam(
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    await localDataSource.addExam(
      materia,
      carrera,
      semestre,
      fecha,
      turno,
      salon,
      profesor,
    );
  }

  Future<void> deleteExam(String materia) async {
    await localDataSource.deleteExam(materia);
  }
}
