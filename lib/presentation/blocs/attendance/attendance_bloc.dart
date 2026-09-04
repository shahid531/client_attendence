import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../domain/usecases/attendance/check_out_usecase.dart';
import '../../../domain/usecases/attendance/get_attendance_history_usecase.dart';
import '../../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final GetTodayAttendanceUseCase getTodayAttendanceUseCase;

  AttendanceBloc({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getAttendanceHistoryUseCase,
    required this.getTodayAttendanceUseCase,
  }) : super(AttendanceInitialState()) {
    on<LoadTodayAttendanceEvent>(_onLoadTodayAttendance);
    on<LoadAttendanceHistoryEvent>(_onLoadAttendanceHistory);
    on<CheckInRequestedEvent>(_onCheckInRequested);
    on<CheckOutRequestedEvent>(_onCheckOutRequested);
  }

  Future<void> _onLoadTodayAttendance(
    LoadTodayAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());
    final todayResult = await getTodayAttendanceUseCase(NoParams());
    final historyResult = await getAttendanceHistoryUseCase(NoParams());

    todayResult.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (todayRecord) {
        historyResult.fold(
          (failure) => emit(AttendanceLoadedState(todayRecord: todayRecord)),
          (history) => emit(AttendanceLoadedState(todayRecord: todayRecord, history: history)),
        );
      },
    );
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistoryEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    final historyResult = await getAttendanceHistoryUseCase(NoParams());

    historyResult.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (history) {
        if (currentState is AttendanceLoadedState) {
          emit(currentState.copyWith(history: history));
        } else {
          emit(AttendanceLoadedState(history: history));
        }
      },
    );
  }

  Future<void> _onCheckInRequested(
    CheckInRequestedEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());

    final result = await checkInUseCase(
      CheckInParams(
        workType: event.workType,
        location: event.location,
        description: event.description,
      ),
    );

    await result.fold(
      (failure) async => emit(AttendanceErrorState(failure.message)),
      (newRecord) async {
        final historyResult = await getAttendanceHistoryUseCase(NoParams());
        final history = historyResult.getOrElse(() => []);
        emit(AttendanceLoadedState(
          todayRecord: newRecord,
          history: history,
          successMessage: 'Successfully clocked in!',
        ));
      },
    );
  }

  Future<void> _onCheckOutRequested(
    CheckOutRequestedEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoadingState());

    final result = await checkOutUseCase(
      CheckOutParams(
        recordId: event.recordId,
        description: event.description,
      ),
    );

    await result.fold(
      (failure) async => emit(AttendanceErrorState(failure.message)),
      (updatedRecord) async {
        final historyResult = await getAttendanceHistoryUseCase(NoParams());
        final history = historyResult.getOrElse(() => []);
        emit(AttendanceLoadedState(
          todayRecord: updatedRecord,
          history: history,
          successMessage: 'Successfully clocked out!',
        ));
      },
    );
  }
}
