import '../../data/repositories/ets_repository_impl.dart';

class AddExamUseCase {
  final EtsRepositoryImpl repository; // Apuntamos directo a tu implementación

  AddExamUseCase(this.repository);

  Future<void> call(
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    return await repository.addExam(
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
