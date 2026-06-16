import 'package:get_it/get_it.dart';

import '../services/api_service.dart';
import '../services/ics_service.dart';
import '../services/notification_service.dart';
import '../../features/ets/data/datasources/ets_local_datasource.dart';
import '../../features/ets/data/repositories/ets_repository_impl.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // ── Servicios ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<IcsService>(() => const IcsService());

  // ── Repositorio ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<EtsLocalDataSource>(() => EtsLocalDataSource());
  sl.registerLazySingleton<EtsRepositoryImpl>(
    () => EtsRepositoryImpl(sl<EtsLocalDataSource>()),
  );
}
