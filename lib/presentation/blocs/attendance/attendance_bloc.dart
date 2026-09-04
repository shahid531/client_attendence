import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  }

  Future<void> _onLoadTodayAttendance(
    LoadTodayAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final todayResult = await getTodayAttendanceUseCase(NoParams());
    AttendanceRecord? activeTodayRecord = todayResult.fold((_) => null, (r) => r);

    if (activeTodayRecord != null) {
      emit(AttendanceLoadedState(todayRecord: activeTodayRecord));
    } else {
      emit(AttendanceLoadingState());
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final startDateStr = DateFormat('yyyy-MM-dd').format(startOfMonth);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endOfMonth);

    final historyResult = await getAttendanceHistoryUseCase(
      GetAttendanceHistoryParams(
        startDate: startDateStr,
        endDate: endDateStr,
      ),
    );

    historyResult.fold(
      (failure) {
        if (activeTodayRecord != null) {
          emit(AttendanceLoadedState(todayRecord: activeTodayRecord));
        } else {
          emit(AttendanceLoadedState(todayRecord: null, history: const []));
        }
      },
      (history) {
        if (history.isNotEmpty) {
          final todayStr = DateFormat('yyyy-MM-dd').format(now);
          final matches = history.where((r) {
            final rDateStr = DateFormat('yyyy-MM-dd').format(r.date);
            return rDateStr == todayStr;
          });
          if (matches.isNotEmpty) {
            final matched = matches.first;
            final current = activeTodayRecord;
            if (current == null) {
              activeTodayRecord = matched;
            } else if (current.checkOutTime == null && matched.checkOutTime != null) {
              activeTodayRecord = matched;
            } else if (current.id.startsWith('att_') && !matched.id.startsWith('att_')) {
              activeTodayRecord = matched;
            }
          }
        }
        emit(AttendanceLoadedState(todayRecord: activeTodayRecord, history: history));
      },
    );
  }

  Future<void> _onLoadAttendanceHistory(
    LoadAttendanceHistoryEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
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
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final historyResult = await getAttendanceHistoryUseCase(
          GetAttendanceHistoryParams(
            startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
            endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
          ),
        );
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
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        final historyResult = await getAttendanceHistoryUseCase(
          GetAttendanceHistoryParams(
            startDate: DateFormat('yyyy-MM-dd').format(startOfMonth),
            endDate: DateFormat('yyyy-MM-dd').format(endOfMonth),
          ),
        );
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

