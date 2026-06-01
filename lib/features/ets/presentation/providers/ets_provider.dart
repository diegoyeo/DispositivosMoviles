import 'package:flutter/material.dart';
import '../../data/repositories/ets_repository_impl.dart';
import '../../domain/entities/ets_exam.dart';

class EtsProvider extends ChangeNotifier {
  final EtsRepositoryImpl repository;

  List<EtsExam> misExamenesGuardados = [];

  // --- ACTUALIZA TU MÉTODO GUARDAR ---
  Future<void> guardarExamInterno(String correo, String materia) async {
    await repository.saveExamToUser(correo, materia);
    await loadSavedExams(correo);
  }

  // Eliminar el examen y recargar la lista interna
  Future<void> eliminarExamInterno(String correo, String materia) async {
    await repository.removeExamFromUser(correo, materia);
    await loadSavedExams(correo); // Esto refresca la pantalla de guardados
  }

  // Función de ayuda para saber si una materia ya fue guardada por el alumno
  bool estaGuardado(String materia) {
    return misExamenesGuardados.any((exam) => exam.materia == materia);
  }

  void limpiarFiltros() {
    busqueda = '';
    carreraSeleccionada = null;
    semestreSeleccionado = null;
    aplicarFiltros(); // Refresca la lista a su estado original
  }

  Future<void> loadSavedExams(String correo) async {
    misExamenesGuardados = await repository.getSavedExamsForUser(correo);
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

  // Metodo para normalizar texto (quita acentos y convierte a minusculas)
  String _normalizar(String texto) {
    var conAcentos = 'ÁÉÍÓÚáéíóú';
    var sinAcentos = 'AEIOUaeiou';
    var salida = texto;
    for (int i = 0; i < conAcentos.length; i++) {
      salida = salida.replaceAll(conAcentos[i], sinAcentos[i]);
    }
    return salida.toLowerCase();
  }

  Future<void> loadExams() async {
    _todosLosExamenes = await repository.getAllExams();

    // Ordenar ignorando acentos
    _todosLosExamenes.sort(
      (a, b) => _normalizar(a.materia).compareTo(_normalizar(b.materia)),
    );

    aplicarFiltros();
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

      // Busqueda inteligente: ambos se normalizan antes de comparar
      final materiaNormalizada = _normalizar(exam.materia);
      final busquedaNormalizada = _normalizar(busqueda);
      final coincideTexto = materiaNormalizada.contains(busquedaNormalizada);

      return coincideCarrera && coincideSemestre && coincideTexto;
    }).toList();

    notifyListeners();
  }
}
