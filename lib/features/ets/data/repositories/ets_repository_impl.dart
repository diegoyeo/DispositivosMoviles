import '../datasources/ets_local_datasource.dart';
import '../datasources/ets_remote_datasource.dart';
import '../../domain/entities/ets_exam.dart';

class EtsRepositoryImpl {
  final EtsLocalDataSource localDataSource;
  final EtsRemoteDataSource remoteDataSource;

  EtsRepositoryImpl(this.localDataSource)
      : remoteDataSource = EtsRemoteDataSource();

  // ── AUTENTICACIÓN REMOTA ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> loginRemote(
    String correo,
    String password,
  ) async {
    return await remoteDataSource.login(correo, password);
  }

  Future<Map<String, dynamic>> registerRemote(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    return await remoteDataSource.register(nombre, apellido, correo, password);
  }

  // ── EXÁMENES REMOTOS ──────────────────────────────────────────────────────

  Future<List<EtsExam>> getExams({
    String? carrera,
    String? semestre,
    String? materia,
  }) async {
    return await remoteDataSource.getExams(
      carrera: carrera,
      semestre: semestre,
      materia: materia,
    );
  }

  Future<EtsExam> addExamRemote({
    required String materia,
    required String carrera,
    required int semestre,
    required String fecha,
    required String turno,
    required String salon,
    required String profesor,
  }) async {
    return await remoteDataSource.createExam(
      materia: materia,
      fecha: fecha,
      turno: turno,
      salon: salon,
      profesor: profesor,
      carrera: carrera,
      semestre: semestre,
    );
  }

  Future<void> deleteExamById(int id) async {
    await remoteDataSource.deleteExam(id);
  }

  Future<void> updateExamById({
    required int id,
    required String materia,
    required String carrera,
    required int semestre,
    required String fecha,
    required String turno,
    required String salon,
    required String profesor,
  }) async {
    await remoteDataSource.updateExam(
      id: id,
      materia: materia,
      fecha: fecha,
      turno: turno,
      salon: salon,
      profesor: profesor,
      carrera: carrera,
      semestre: semestre,
    );
  }

  Future<List<EtsExam>> getAllExams({
    String? carrera,
    String? semestre,
    String? materia,
  }) async {
    return await remoteDataSource.getAllExams(
      carrera: carrera,
      semestre: semestre,
      materia: materia,
    );
  }

  Future<EtsExam> toggleVisibility(int id, bool visible) async {
    return await remoteDataSource.toggleVisibility(id, visible);
  }

  Future<Map<String, dynamic>> getStats() async {
    return await remoteDataSource.getStats();
  }

  // ── GUARDADOS REMOTOS ─────────────────────────────────────────────────────

  Future<List<EtsExam>> getSavedExams() async {
    return await remoteDataSource.getSavedExams();
  }

  Future<void> saveExamById(int examId) async {
    await remoteDataSource.saveExam(examId);
  }

  Future<void> removeSavedExamById(int examId) async {
    await remoteDataSource.removeSavedExam(examId);
  }

  // ── PERFIL REMOTO ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ── LEGACY — SQLite (mantenidos para rollback) ────────────────────────────

  Future<String?> login(String correo, String password) async {
    final emailLimpio = correo.trim().toLowerCase();
    final passLimpio = password.trim();

    if (emailLimpio == 'admin@escom.ipn.mx' && passLimpio == 'admin123') {
      return 'admin';
    }

    try {
      final db = await localDataSource.database;
      final resultado = await db.query(
        'users',
        where: 'correo = ? AND password = ?',
        whereArgs: [emailLimpio, passLimpio],
      );
      if (resultado.isNotEmpty) return 'alumno';
    } catch (_) {
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

  Future<void> saveExamToUser(String correo, String materia) async {
    await localDataSource.saveExamToUser(correo, materia);
  }

  Future<List<EtsExam>> getSavedExamsForUser(String correo) async {
    return await localDataSource.getSavedExamsForUser(correo);
  }

  Future<void> removeExamFromUser(String correo, String materia) async {
    await localDataSource.removeExamFromUser(correo, materia);
  }

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
}
