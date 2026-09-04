import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../../domain/usecases/auth/login_usecase.dart';
import '../../../domain/usecases/auth/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(AuthInitialState()) {
    on<AppStartedEvent>(_onAppStarted);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<LogoutRequestedEvent>(_onLogoutRequested);
  }

  Future<void> _onAppStarted(
    AppStartedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(UnauthenticatedState()),
      (user) {
        if (user != null) {
          emit(AuthenticatedState(user));
        } else {
          emit(UnauthenticatedState());
        }
      },
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmittedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    final result = await loginUseCase(
      LoginParams(
        username: event.username,
        password: event.password,
        deviceId: event.deviceId,
        deviceModel: event.deviceModel,
        operatingSystem: event.operatingSystem,
      ),
    );

    print('RESULT: 12345: ${result}');

    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(AuthenticatedState(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequestedEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    await logoutUseCase(NoParams());
    emit(UnauthenticatedState());
  }
}
