import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/attendance_record.dart';
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
    on<ResetAttendanceEvent>(_onResetAttendance);
  }

  void _onResetAttendance(
    ResetAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) {
    emit(AttendanceInitialState());
  }

  Future<void> _onLoadTodayAttendance(
    LoadTodayAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final todayResult = await getTodayAttendanceUseCase(NoParams());
    final activeTodayRecord = todayResult.fold((_) => null, (r) => r);
    final currentState = state;
    if (currentState is AttendanceLoadedState) {
      emit(currentState.copyWith(todayRecord: activeTodayRecord));
    } else {
      emit(AttendanceLoadedState(todayRecord: activeTodayRecord));
    }
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistoryEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    final existingTodayRecord = currentState is AttendanceLoadedState
        ? currentState.todayRecord
        : null;
    emit(AttendanceLoadingState());
    final historyResult = await getAttendanceHistoryUseCase(
      GetAttendanceHistoryParams(
        startDate: event.startDate,
        endDate: event.endDate,
        filter: event.filter,
        page: event.page,
        size: event.size,
      ),
    );

    historyResult.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (history) {
        emit(AttendanceLoadedState(
          todayRecord: existingTodayRecord,
          history: history,
        ));
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

    result.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (newRecord) {
        final currentState = state;
        final currentHistory = currentState is AttendanceLoadedState ? currentState.history : const <AttendanceRecord>[];
        emit(AttendanceLoadedState(
          todayRecord: newRecord,
          history: currentHistory,
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

    result.fold(
      (failure) => emit(AttendanceErrorState(failure.message)),
      (updatedRecord) {
        final currentState = state;
        final currentHistory = currentState is AttendanceLoadedState ? currentState.history : const <AttendanceRecord>[];
        emit(AttendanceLoadedState(
          todayRecord: updatedRecord,
          history: currentHistory,
          successMessage: 'Successfully clocked out!',
        ));
      },
    );
  }
}

