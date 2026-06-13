import 'package:flutter/foundation.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Toda la lógica del onboarding sin un solo setState() en la UI.
/// Notifica a los widgets suscritos cuando cambia la página activa.
class OnboardingProvider extends ChangeNotifier {
  final OnboardingRepository _repository;

  int _currentPage = 0;

  static const int totalPages = 4;

  OnboardingProvider(this._repository);

  int get currentPage => _currentPage;

  /// `true` cuando el usuario está en la última diapositiva.
  bool get isLastPage => _currentPage == totalPages - 1;

  /// Sincroniza la página activa (llamado desde onPageChanged del PageView).
  void goToPage(int page) {
    if (_currentPage == page) return;
    _currentPage = page;
    notifyListeners();
  }

  /// Persiste que el onboarding fue completado y cede el control a la UI.
  Future<void> completeOnboarding() => _repository.markOnboardingAsSeen();
}
