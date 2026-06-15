import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/ets_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final EtsRepositoryImpl repository;

  String? currentRole;
  String? currentEmail;
  String? currentNombre;
  String? currentApellido;
  String? lastError;

  static const _kToken = 'auth_token';
  static const _kCorreo = 'user_correo';
  static const _kNombre = 'user_nombre';
  static const _kApellido = 'user_apellido';
  static const _kRol = 'user_rol';

  AuthProvider(this.repository);

  Future<bool> login(String correo, String password) async {
    try {
      final data = await repository.loginRemote(correo, password);
      final user = data['user'] as Map<String, dynamic>;
      final token = data['token'] as String;

      await _saveSession(
        token: token,
        correo: user['correo'] as String,
        nombre: user['nombre'] as String,
        apellido: user['apellido'] as String,
        rol: user['rol'] as String,
      );

      currentRole = user['rol'] as String;
      currentEmail = user['correo'] as String;
      currentNombre = user['nombre'] as String;
      currentApellido = user['apellido'] as String;
      lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  Future<bool> register(
    String nombre,
    String apellido,
    String correo,
    String password,
  ) async {
    try {
      await repository.registerRemote(nombre, apellido, correo, password);
      return await login(correo, password);
    } catch (e) {
      lastError = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  void logout() {
    currentRole = null;
    currentEmail = null;
    currentNombre = null;
    currentApellido = null;
    lastError = null;
    notifyListeners();
    _clearSession();
  }

  Future<void> logoutSilent() async {
    currentRole = null;
    currentEmail = null;
    currentNombre = null;
    currentApellido = null;
    lastError = null;
    notifyListeners();
    await _clearSession();
  }

  Future<void> checkAuthOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null) return;

    currentRole = prefs.getString(_kRol);
    currentEmail = prefs.getString(_kCorreo);
    currentNombre = prefs.getString(_kNombre);
    currentApellido = prefs.getString(_kApellido);

    if (currentRole != null) notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<void> _saveSession({
    required String token,
    required String correo,
    required String nombre,
    required String apellido,
    required String rol,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kCorreo, correo);
    await prefs.setString(_kNombre, nombre);
    await prefs.setString(_kApellido, apellido);
    await prefs.setString(_kRol, rol);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kCorreo);
    await prefs.remove(_kNombre);
    await prefs.remove(_kApellido);
    await prefs.remove(_kRol);
  }
}
