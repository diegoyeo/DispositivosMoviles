import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/ets/data/datasources/ets_local_datasource.dart';
import 'features/ets/data/repositories/ets_repository_impl.dart';
import 'features/ets/presentation/providers/ets_provider.dart';
import 'features/ets/presentation/pages/ets_home_page.dart';

void main() {
  // Inicializamos la base de datos y el repositorio
  final localDataSource = EtsLocalDataSource();
  final repository = EtsRepositoryImpl(localDataSource: localDataSource);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EtsProvider(repository)),
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
      title: 'App de ETS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const EtsHomePage(),
    );
  }
}
