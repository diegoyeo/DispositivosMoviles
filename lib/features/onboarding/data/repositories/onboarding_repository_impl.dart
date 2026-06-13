import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Implementación concreta del repositorio usando SharedPreferences.
/// La clave `_kSeenKey` persiste entre sesiones en el dispositivo.
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _kSeenKey = 'bruzzy_onboarding_seen';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeenKey) ?? false;
  }

  @override
  Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeenKey, true);
  }
}
