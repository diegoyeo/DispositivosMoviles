import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/ets/data/datasources/ets_local_datasource.dart';
import 'features/ets/data/repositories/ets_repository_impl.dart';
import 'features/ets/presentation/providers/ets_provider.dart';
import 'features/ets/presentation/providers/auth_provider.dart';
import 'features/ets/presentation/pages/login_page.dart';

void main() {
  // 1. Inicializamos la "maquinaria" de la base de datos
  final localDataSource = EtsLocalDataSource();
  final repository = EtsRepositoryImpl(localDataSource: localDataSource);

  runApp(
    // 2. MultiProvider nos deja tener varios "Cerebros" funcionando al mismo tiempo
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EtsProvider(repository)),
        ChangeNotifierProvider(create: (_) => AuthProvider(repository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de ETS ESCOM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      // 3. La pantalla inicial ahora es el Login, ya no el Home directo
      home: const LoginPage(),
    );
  }
}
