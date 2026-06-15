import 'package:flutter/material.dart';
import '../../data/repositories/ets_repository_impl.dart';
import '../../domain/entities/ets_exam.dart';

class EtsProvider extends ChangeNotifier {
  final EtsRepositoryImpl repository;

  List<EtsExam> misExamenesGuardados = [];
  List<EtsExam> get catalogoCompleto => _todosLosExamenes;

  List<EtsExam> _adminExamenes = [];
  List<EtsExam> get adminCatalogo => _adminExamenes;

  Future<void> guardarExamInterno(String correo, String materia) async {
    final exam = _todosLosExamenes.firstWhere(
      (e) => e.materia == materia,
      orElse: () => throw Exception('Examen no encontrado en el catálogo'),
    );
    if (exam.id == null) throw Exception('El examen no tiene ID válido');
    await repository.saveExamById(exam.id!);
    await loadSavedExams(correo);
  }

  Future<void> agregarNuevoExamen(
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    await repository.addExamRemote(
      materia: materia,
      carrera: carrera,
      semestre: semestre,
      fecha: fecha,
      turno: turno,
      salon: salon,
      profesor: profesor,
    );
    await loadExams();
  }

  Future<void> eliminarExamInterno(String correo, String materia) async {
    final exam = misExamenesGuardados.firstWhere(
      (e) => e.materia == materia,
      orElse: () => throw Exception('Examen no encontrado en guardados'),
    );
    if (exam.id == null) throw Exception('El examen no tiene ID válido');
    await repository.removeSavedExamById(exam.id!);
    await loadSavedExams(correo);
  }

  bool estaGuardado(String materia) {
    return misExamenesGuardados.any((exam) => exam.materia == materia);
  }

  void limpiarFiltros() {
    busqueda = '';
    carreraSeleccionada = null;
    semestreSeleccionado = null;
    aplicarFiltros();
  }

  Future<void> loadSavedExams(String correo) async {
    try {
      misExamenesGuardados = await repository.getSavedExams();
    } catch (_) {
      misExamenesGuardados = [];
    }
    notifyListeners();
  }

  List<EtsExam> _todosLosExamenes = [];
  List<EtsExam> examenesFiltrados = [];

  String? carreraSeleccionada;
  String? semestreSeleccionado;
  String busqueda = '';

  EtsProvider(this.repository) {
    loadExams();
  }

  String _normalizar(String texto) {
    const conAcentos = 'ÁÉÍÓÚáéíóú';
    const sinAcentos = 'AEIOUaeiou';
    var salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase();
  }

  Future<void> borrarExamenDelCatalogo(String materia) async {
    final exam = _todosLosExamenes.firstWhere(
      (e) => e.materia == materia,
      orElse: () => throw Exception('Examen no encontrado'),
    );
    if (exam.id == null) throw Exception('El examen no tiene ID válido');
    await repository.deleteExamById(exam.id!);
    await loadExams();
  }

  Future<void> actualizarExamen(
    String oldMateria,
    String materia,
    String carrera,
    int semestre,
    String fecha,
    String turno,
    String salon,
    String profesor,
  ) async {
    final exam = _todosLosExamenes.firstWhere(
      (e) => e.materia == oldMateria,
      orElse: () => throw Exception('Examen original no encontrado'),
    );
    if (exam.id == null) throw Exception('El examen no tiene ID válido');
    await repository.updateExamById(
      id: exam.id!,
      materia: materia,
      carrera: carrera,
      semestre: semestre,
      fecha: fecha,
      turno: turno,
      salon: salon,
      profesor: profesor,
    );
    await loadExams();
  }

  Future<void> loadExams() async {
    try {
      _todosLosExamenes = await repository.getExams();
      _todosLosExamenes.sort(
        (a, b) => _normalizar(a.materia).compareTo(_normalizar(b.materia)),
      );
    } catch (_) {
      _todosLosExamenes = [];
    }
    aplicarFiltros();
  }

  Future<void> loadAllExams() async {
    try {
      _adminExamenes = await repository.getAllExams();
      _adminExamenes.sort(
        (a, b) => _normalizar(a.materia).compareTo(_normalizar(b.materia)),
      );
    } catch (_) {
      _adminExamenes = [];
    }
    notifyListeners();
  }

  Future<void> toggleVisibility(int examId, bool visible) async {
    await repository.toggleVisibility(examId, visible);
    await Future.wait([loadAllExams(), loadExams()]);
  }

  void buscarPorMateria(String texto) {
    busqueda = texto;
    aplicarFiltros();
  }

  void filtrarPorCarrera(String? carrera) {
    carreraSeleccionada = (carrera == 'Todas') ? null : carrera;
    aplicarFiltros();
  }

  void filtrarPorSemestre(String? semestre) {
    semestreSeleccionado = (semestre == 'Todos') ? null : semestre;
    aplicarFiltros();
  }

  void aplicarFiltros() {
    examenesFiltrados = _todosLosExamenes.where((exam) {
      final coincideCarrera =
          carreraSeleccionada == null || exam.carrera == carreraSeleccionada;
      final coincideSemestre =
          semestreSeleccionado == null ||
          exam.semestre.toString() == semestreSeleccionado;
      final materiaNormalizada = _normalizar(exam.materia);
      final busquedaNormalizada = _normalizar(busqueda);
      final coincideTexto = materiaNormalizada.contains(busquedaNormalizada);
      return coincideCarrera && coincideSemestre && coincideTexto;
    }).toList();

    notifyListeners();
  }
}
