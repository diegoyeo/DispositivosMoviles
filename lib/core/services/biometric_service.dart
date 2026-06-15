import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Usa tu huella digital para entrar a MOVIDA',
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveCredentials({
    required String correo,
    required String password,
  }) async {
    await _storage.write(key: 'bio_correo', value: correo);
    await _storage.write(key: 'bio_password', value: password);
    await _storage.write(key: 'bio_enabled', value: 'true');
  }

  static Future<Map<String, String>?> getCredentials() async {
    final enabled = await _storage.read(key: 'bio_enabled');
    if (enabled != 'true') return null;
    final correo = await _storage.read(key: 'bio_correo');
    final password = await _storage.read(key: 'bio_password');
    if (correo == null || password == null) return null;
    return {'correo': correo, 'password': password};
  }

  static Future<bool> isBiometricLinked() async {
    try {
      final enabled = await _storage.read(key: 'bio_enabled');
      if (enabled != 'true') return false;
      final correo = await _storage.read(key: 'bio_correo');
      final password = await _storage.read(key: 'bio_password');
      return correo != null && password != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearCredentials() async {
    await _storage.deleteAll();
  }
}
