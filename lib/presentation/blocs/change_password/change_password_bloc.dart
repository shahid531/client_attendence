import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth/change_password_usecase.dart';
import 'change_password_event.dart';
import 'change_password_state.dart';

class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  final ChangePasswordUseCase changePasswordUseCase;

  ChangePasswordBloc({
    required this.changePasswordUseCase,
  }) : super(ChangePasswordInitialState()) {
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ChangePasswordResetEvent>(_onChangePasswordReset);
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<ChangePasswordState> emit,
  ) async {
    emit(ChangePasswordLoadingState());

    final result = await changePasswordUseCase(
      ChangePasswordParams(
        oldPassword: event.oldPassword,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
      (failure) => emit(ChangePasswordFailureState(failure.message)),
      (_) => emit(const ChangePasswordSuccessState('Password updated successfully!')),
    );
  }

  void _onChangePasswordReset(
    ChangePasswordResetEvent event,
    Emitter<ChangePasswordState> emit,
  ) {
    emit(ChangePasswordInitialState());
  }
}
