import '../../../../core/config/api_config.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/ets_exam.dart';
import '../models/ets_model.dart';

class EtsRemoteDataSource {
  final _api = ApiService();

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String correo, String password) async {
    final res = await _api.post(ApiConfig.login, {
      'correo': correo,
      'password': password,
    });
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    final res = await _api.post(ApiConfig.register, {
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'password': password,
    });
    return res['data'] as Map<String, dynamic>;
  }

  // ── Exámenes ──────────────────────────────────────────────────────────────

  Future<List<EtsExam>> getExams({
    String? carrera,
    String? semestre,
    String? materia,
  }) async {
    var endpoint = ApiConfig.exams;
    final params = <String>[];
    if (carrera != null && carrera.isNotEmpty) params.add('carrera=$carrera');
    if (semestre != null && semestre.isNotEmpty) {
      params.add('semestre=$semestre');
    }
    if (materia != null && materia.isNotEmpty) {
      params.add('materia=${Uri.encodeComponent(materia)}');
    }
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final res = await _api.get(endpoint);
    return (res['data'] as List<dynamic>)
        .map((e) => EtsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EtsExam> createExam({
    required String materia,
    required String fecha,
    required String turno,
    required String salon,
    required String profesor,
    required String carrera,
    required int semestre,
  }) async {
    final res = await _api.post(
      ApiConfig.exams,
      {
        'materia': materia,
        'fecha': fecha,
        'turno': turno,
        'salon': salon,
        'profesor': profesor,
        'carrera': carrera,
        'semestre': semestre,
      },
      requiresAuth: true,
    );
    return EtsModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<EtsExam> updateExam({
    required int id,
    required String materia,
    required String fecha,
    required String turno,
    required String salon,
    required String profesor,
    required String carrera,
    required int semestre,
  }) async {
    final res = await _api.put(
      '${ApiConfig.exams}/$id',
      {
        'materia': materia,
        'fecha': fecha,
        'turno': turno,
        'salon': salon,
        'profesor': profesor,
        'carrera': carrera,
        'semestre': semestre,
      },
      requiresAuth: true,
    );
    return EtsModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExam(int id) async {
    await _api.delete('${ApiConfig.exams}/$id', requiresAuth: true);
  }

  Future<List<EtsExam>> getAllExams({
    String? carrera,
    String? semestre,
    String? materia,
  }) async {
    var endpoint = ApiConfig.examsAdmin;
    final params = <String>[];
    if (carrera != null && carrera.isNotEmpty) params.add('carrera=$carrera');
    if (semestre != null && semestre.isNotEmpty) params.add('semestre=$semestre');
    if (materia != null && materia.isNotEmpty) {
      params.add('materia=${Uri.encodeComponent(materia)}');
    }
    if (params.isNotEmpty) endpoint += '?${params.join('&')}';

    final res = await _api.get(endpoint, requiresAuth: true);
    return (res['data'] as List<dynamic>)
        .map((e) => EtsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EtsExam> toggleVisibility(int id, bool visible) async {
    final res = await _api.patch(
      '${ApiConfig.exams}/$id/visibility',
      {'visible': visible ? 1 : 0},
      requiresAuth: true,
    );
    return EtsModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _api.get(ApiConfig.examStats, requiresAuth: true);
    return res['data'] as Map<String, dynamic>;
  }

  // ── Guardados ─────────────────────────────────────────────────────────────

  Future<List<EtsExam>> getSavedExams() async {
    final res = await _api.get(ApiConfig.saved, requiresAuth: true);
    return (res['data'] as List<dynamic>)
        .map((e) => EtsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveExam(int examId) async {
    await _api.post('${ApiConfig.saved}/$examId', {}, requiresAuth: true);
  }

  Future<void> removeSavedExam(int examId) async {
    await _api.delete('${ApiConfig.saved}/$examId', requiresAuth: true);
  }

  // ── Perfil ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _api.get(ApiConfig.profile, requiresAuth: true);
    return res['data'] as Map<String, dynamic>;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put(
      ApiConfig.password,
      {'currentPassword': currentPassword, 'newPassword': newPassword},
      requiresAuth: true,
    );
  }
}
