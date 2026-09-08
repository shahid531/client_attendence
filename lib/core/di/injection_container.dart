import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/leave_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/leave_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/leave_repository.dart';
import '../../domain/usecases/admin/create_employee_usecase.dart';
import '../../domain/usecases/attendance/check_in_usecase.dart';
import '../../domain/usecases/attendance/check_out_usecase.dart';
import '../../domain/usecases/attendance/get_attendance_history_usecase.dart';
import '../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import '../../domain/usecases/auth/change_password_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/logout_usecase.dart';
import '../../domain/usecases/dashboard/get_dashboard_stats_usecase.dart';
import '../../domain/usecases/leave/get_leave_requests_usecase.dart';
import '../../domain/usecases/leave/submit_leave_request_usecase.dart';
import '../../domain/usecases/leave/update_request_status_usecase.dart';
import '../../presentation/blocs/admin/admin_bloc.dart';
import '../../presentation/blocs/attendance/attendance_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/change_password/change_password_bloc.dart';
import '../../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../../presentation/blocs/leave/leave_bloc.dart';
import '../network/network_info.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  //! External & Core
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print('\n==================== [API REQUEST] ====================');
        print('--> ${options.method.toUpperCase()} ${options.uri}');
        print('Headers: ${options.headers}');
        if (options.data != null) {
          print('Body: ${options.data}');
        }
        print('=======================================================\n');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('\n==================== [API RESPONSE] ====================');
        print('<-- ${response.statusCode} ${response.requestOptions.uri}');
        debugPrint('Response Data: ${response.data}');
        print('========================================================\n');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('\n==================== [API ERROR] ====================');
        print('<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
        print('Error Message: ${e.message}');
        print('Error Data: ${e.response?.data}');
        print('=====================================================\n');
        return handler.next(e);
      },
    ),
  );

  sl.registerLazySingleton<Dio>(() => dio);


  //! Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      dio: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(
      dio: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerLazySingleton<LeaveRemoteDataSource>(
    () => LeaveRemoteDataSourceImpl(
      dio: sl(),
      sharedPreferences: sl(),
    ),
  );
  sl.registerLazySingleton<AdminRemoteDataSource>(
    () => AdminRemoteDataSourceImpl(
      dio: sl(),
      sharedPreferences: sl(),
    ),
  );


  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<LeaveRepository>(
    () => LeaveRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(remoteDataSource: sl()),
  );

  //! Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => CheckInUseCase(sl()));
  sl.registerLazySingleton(() => CheckOutUseCase(sl()));
  sl.registerLazySingleton(() => GetAttendanceHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetTodayAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => SubmitLeaveRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetLeaveRequestsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateRequestStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetDashboardStatsUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => CreateEmployeeUseCase(sl()));

  //! Blocs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ChangePasswordBloc(
      changePasswordUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => AttendanceBloc(
      checkInUseCase: sl(),
      checkOutUseCase: sl(),
      getAttendanceHistoryUseCase: sl(),
      getTodayAttendanceUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => LeaveBloc(
      submitLeaveRequestUseCase: sl(),
      getLeaveRequestsUseCase: sl(),
      updateRequestStatusUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => DashboardBloc(
      getDashboardStatsUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => AdminBloc(
      createEmployeeUseCase: sl(),
    ),
  );
}
