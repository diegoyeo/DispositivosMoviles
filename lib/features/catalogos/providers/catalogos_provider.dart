import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/api_service.dart';
import '../models/carrera_model.dart';
import '../models/salon_model.dart';

class CatalogosProvider extends ChangeNotifier {
  final _api = sl<ApiService>();

  List<CarreraModel> _carreras = [];
  List<SalonModel> _salones = [];
  bool _loading = false;
  String? lastError;
  String? error;

  List<CarreraModel> get carreras => _carreras;
  List<SalonModel> get salones => _salones;
  bool get loading => _loading;

  // ── Carreras ──────────────────────────────────────────────────────────────

  Future<void> loadCarreras() async {
    try {
      final data = await _api.get(ApiConfig.carreras);
      _carreras = (data['data'] as List).map((e) => CarreraModel.fromJson(e as Map<String, dynamic>)).toList();
      lastError = null;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<bool> addCarrera({required String nombre, required String descripcion}) async {
    _loading = true; notifyListeners();
    try {
      await _api.post(ApiConfig.carreras, {'nombre': nombre, 'descripcion': descripcion}, requiresAuth: true);
      await loadCarreras();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateCarrera(int id, {required String nombre, required String descripcion}) async {
    _loading = true; notifyListeners();
    try {
      await _api.put('${ApiConfig.carreras}/$id', {'nombre': nombre, 'descripcion': descripcion}, requiresAuth: true);
      await loadCarreras();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> deleteCarrera(int id) async {
    _loading = true; notifyListeners();
    try {
      await _api.delete('${ApiConfig.carreras}/$id', requiresAuth: true);
      await loadCarreras();
      lastError = null;
      error = null;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      lastError = error;
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  // ── Salones ───────────────────────────────────────────────────────────────

  Future<void> loadSalones() async {
    try {
      final data = await _api.get(ApiConfig.salones);
      _salones = (data['data'] as List).map((e) => SalonModel.fromJson(e as Map<String, dynamic>)).toList();
      lastError = null;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<bool> addSalon({required String nombre, required String edificio, int? capacidad}) async {
    _loading = true; notifyListeners();
    try {
      await _api.post(ApiConfig.salones, {'nombre': nombre, 'edificio': edificio, 'capacidad': capacidad}, requiresAuth: true);
      await loadSalones();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> updateSalon(int id, {required String nombre, required String edificio, int? capacidad}) async {
    _loading = true; notifyListeners();
    try {
      await _api.put('${ApiConfig.salones}/$id', {'nombre': nombre, 'edificio': edificio, 'capacidad': capacidad}, requiresAuth: true);
      await loadSalones();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> deleteSalon(int id) async {
    _loading = true; notifyListeners();
    try {
      await _api.delete('${ApiConfig.salones}/$id', requiresAuth: true);
      await loadSalones();
      lastError = null;
      error = null;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      lastError = error;
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
