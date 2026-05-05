import 'package:flutter/material.dart';
import '../../data/repositories/ets_repository_impl.dart';
import '../../domain/entities/ets_exam.dart';

class EtsProvider extends ChangeNotifier {
  final EtsRepositoryImpl repository;
  List<EtsExam> exams = [];

  EtsProvider(this.repository) {
    loadExams(); // Carga los datos precargados en cuanto abres la app
  }

  Future<void> loadExams() async {
    exams = await repository.getAllExams();
    notifyListeners(); // Le grita a la pantalla: "¡Ya tengo los datos, actualízate!"
  }
}