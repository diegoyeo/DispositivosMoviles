import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  static const _keyCarrera = 'default_carrera';
  static const _keySemestre = 'default_semestre';

  final SharedPreferences _prefs;

  String? _defaultCarrera;
  String? _defaultSemestre;

  PreferencesProvider(this._prefs) {
    _defaultCarrera = _prefs.getString(_keyCarrera);
    _defaultSemestre = _prefs.getString(_keySemestre);
  }

  String? get defaultCarrera => _defaultCarrera;
  String? get defaultSemestre => _defaultSemestre;

  void setDefaultCarrera(String? carrera) {
    _defaultCarrera = carrera;
    notifyListeners();
    if (carrera == null) {
      _prefs.remove(_keyCarrera);
    } else {
      _prefs.setString(_keyCarrera, carrera);
    }
  }

  void setDefaultSemestre(String? semestre) {
    _defaultSemestre = semestre;
    notifyListeners();
    if (semestre == null) {
      _prefs.remove(_keySemestre);
    } else {
      _prefs.setString(_keySemestre, semestre);
    }
  }
}
