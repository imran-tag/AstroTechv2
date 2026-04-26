import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/network/api_client.dart';
import 'data/datasources/local/local_database.dart';
import 'data/datasources/local/sync_queue_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/intervention_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/intervention_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/intervention_repository.dart';
import 'domain/usecases/get_interventions.dart';
import 'domain/usecases/get_intervention_detail.dart';
import 'domain/usecases/login_user.dart';
import 'domain/usecases/save_workflow.dart';
import 'domain/usecases/sync_offline_data.dart';
import 'domain/usecases/update_intervention_status.dart';
import 'domain/usecases/upload_photo.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/intervention/intervention_bloc.dart';
import 'presentation/blocs/workflow/workflow_bloc.dart';
import 'services/connectivity_service.dart';
import 'services/photo_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Core
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(getIt<FlutterSecureStorage>()),
  );

  // Services
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  getIt.registerLazySingleton<PhotoService>(
    () => PhotoService(),
  );

  // Local Data Sources
  getIt.registerLazySingleton<LocalDatabase>(
    () => LocalDatabase(),
  );

  getIt.registerLazySingleton<SyncQueueDatasource>(
    () => SyncQueueDatasource(),
  );

  // Remote Data Sources
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<InterventionRemoteDatasource>(
    () => InterventionRemoteDatasource(getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDatasource: getIt<AuthRemoteDatasource>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  getIt.registerLazySingleton<InterventionRepository>(
    () => InterventionRepositoryImpl(
      remoteDatasource: getIt<InterventionRemoteDatasource>(),
      localDatabase: getIt<LocalDatabase>(),
      syncQueue: getIt<SyncQueueDatasource>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => LoginUser(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => GetInterventions(getIt<InterventionRepository>()));
  getIt.registerLazySingleton(() => GetInterventionDetail(getIt<InterventionRepository>()));
  getIt.registerLazySingleton(() => UpdateInterventionStatus(getIt<InterventionRepository>()));
  getIt.registerLazySingleton(() => SaveWorkflow(getIt<InterventionRepository>()));
  getIt.registerLazySingleton(() => UploadPhoto(getIt<InterventionRepository>()));
  getIt.registerLazySingleton(() => SyncOfflineData(getIt<InterventionRepository>()));

  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      loginUser: getIt<LoginUser>(),
      secureStorage: getIt<FlutterSecureStorage>(),
      localDatabase: getIt<LocalDatabase>(),
    ),
  );

  getIt.registerFactory(
    () => InterventionBloc(
      getInterventions: getIt<GetInterventions>(),
      getInterventionDetail: getIt<GetInterventionDetail>(),
      updateInterventionStatus: getIt<UpdateInterventionStatus>(),
    ),
  );

  getIt.registerFactory(
    () => WorkflowBloc(
      saveWorkflow: getIt<SaveWorkflow>(),
      uploadPhoto: getIt<UploadPhoto>(),
      interventionRepository: getIt<InterventionRepository>(),
    ),
  );
}
