import 'package:flutter/material.dart';
import '../../data/repositories/ets_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final EtsRepositoryImpl repository;

  String? currentRole;
  String? currentEmail; // Nueva variable para recordar al usuario activo

  AuthProvider(this.repository);

  Future<bool> login(String correo, String password) async {
    final role = await repository.login(correo, password);
    if (role != null) {
      currentRole = role;
      currentEmail = correo; // Guardamos el correo
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    return await repository.register(nombre, apellido, correo, password);
  }

  void logout() {
    currentRole = null;
    currentEmail = null; // Limpiamos el correo
    notifyListeners();
  }
}
