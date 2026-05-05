import '../../domain/entities/ets_exam.dart';
import '../../data/repositories/ets_repository_impl.dart';

class AddExamUseCase {
  final EtsRepositoryImpl repository;

  AddExamUseCase(this.repository);

  Future<void> execute(EtsExam exam) async {
    // Aquí podrías poner reglas de negocio, por ejemplo:
    // "No guardar si la materia está vacía"
    if (exam.materia.isNotEmpty) {
      return await repository.addExam(exam);
    }
  }
}