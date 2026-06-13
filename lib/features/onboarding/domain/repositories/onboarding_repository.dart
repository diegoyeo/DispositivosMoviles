/// Contrato del dominio: define qué operaciones existen sin
/// depender de ninguna implementación concreta (shared_preferences, etc.)
abstract class OnboardingRepository {
  /// Devuelve `true` si el usuario ya completó el tutorial de bienvenida.
  Future<bool> hasSeenOnboarding();

  /// Persiste la bandera que indica que el tutorial fue visto.
  Future<void> markOnboardingAsSeen();
}
