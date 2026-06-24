import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/network/network_info.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/check_session.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/jobs/data/datasources/jobs_local_data_source.dart';
import 'features/jobs/data/datasources/jobs_remote_data_source.dart';
import 'features/jobs/data/repositories/jobs_repository_impl.dart';
import 'features/jobs/domain/repositories/jobs_repository.dart';
import 'features/jobs/domain/usecases/get_jobs.dart';
import 'features/jobs/domain/usecases/update_job_status.dart';
import 'features/jobs/presentation/bloc/jobs_bloc.dart';

import 'features/service_reports/data/datasources/reports_local_data_source.dart';
import 'features/service_reports/data/datasources/reports_remote_data_source.dart';
import 'features/service_reports/data/repositories/service_report_repository_impl.dart';
import 'features/service_reports/domain/repositories/service_report_repository.dart';
import 'features/service_reports/domain/usecases/submit_report.dart';
import 'features/service_reports/presentation/bloc/report_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Authentication
  // Bloc
  sl.registerFactory(() => AuthBloc(
        checkSession: sl(),
        loginUser: sl(),
        logoutUser: sl(),
        registerUser: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => CheckSession(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        firebaseAuth: sl(),
        firestore: sl(),
      ));
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(Hive));

  //! Features - Jobs
  // Bloc
  sl.registerFactory(() => JobsBloc(
        getJobs: sl(),
        updateJobStatus: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => GetJobs(sl()));
  sl.registerLazySingleton(() => UpdateJobStatus(sl()));

  // Repository
  sl.registerLazySingleton<JobsRepository>(() => JobsRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<JobsRemoteDataSource>(() => JobsRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<JobsLocalDataSource>(() => JobsLocalDataSourceImpl(Hive));

  //! Features - Service Reports
  // Bloc
  sl.registerFactory(() => ReportBloc(submitReport: sl()));

  // Use cases
  sl.registerLazySingleton(() => SubmitReport(sl()));

  // Repository
  sl.registerLazySingleton<ServiceReportRepository>(() => ServiceReportRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ));

  // Data sources
  sl.registerLazySingleton<ReportsRemoteDataSource>(() => ReportsRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ReportsLocalDataSource>(() => ReportsLocalDataSourceImpl(Hive));

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register firebase instances
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  
  // Register internet checker
  sl.registerLazySingleton(() => InternetConnectionChecker());
}
