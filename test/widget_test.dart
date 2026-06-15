import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dispositivos_moviles/main.dart';
import 'package:dispositivos_moviles/features/ets/data/datasources/ets_local_datasource.dart';
import 'package:dispositivos_moviles/features/ets/data/repositories/ets_repository_impl.dart';
import 'package:dispositivos_moviles/features/ets/presentation/providers/ets_provider.dart';
import 'package:dispositivos_moviles/features/ets/presentation/providers/auth_provider.dart';
import 'package:dispositivos_moviles/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:dispositivos_moviles/features/onboarding/presentation/providers/onboarding_provider.dart';

Widget _buildApp() {
  final localDataSource = EtsLocalDataSource();
  final repository = EtsRepositoryImpl(localDataSource);
  final onboardingRepo = OnboardingRepositoryImpl();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => EtsProvider(repository)),
      ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
      ChangeNotifierProvider(
        create: (_) => OnboardingProvider(onboardingRepo),
      ),
    ],
    child: const MyApp(),
  );
}

void main() {
  testWidgets('La app muestra el SplashScreen al iniciar',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp());

    // El splash muestra el ícono y el nombre de la app
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    expect(find.text('BRUZZY'), findsOneWidget);
  });
}
