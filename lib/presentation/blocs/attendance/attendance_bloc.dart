import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/excel_exporter.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/usecases/attendance/check_in_usecase.dart';
import '../../../domain/usecases/attendance/check_out_usecase.dart';
import '../../../domain/usecases/attendance/export_attendance_usecase.dart';
import '../../../domain/usecases/attendance/get_attendance_history_usecase.dart';
import '../../../domain/usecases/attendance/get_today_attendance_usecase.dart';
import '../../../domain/usecases/attendance/regularize_attendance_usecase.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final GetAttendanceHistoryUseCase getAttendanceHistoryUseCase;
  final GetTodayAttendanceUseCase getTodayAttendanceUseCase;
  final RegularizeAttendanceUseCase regularizeAttendanceUseCase;
  final ExportAttendanceUseCase exportAttendanceUseCase;

  AttendanceBloc({
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.getAttendanceHistoryUseCase,
    required this.getTodayAttendanceUseCase,
    required this.regularizeAttendanceUseCase,
    required this.exportAttendanceUseCase,
  }) : super(AttendanceInitialState()) {
    on<LoadTodayAttendanceEvent>(_onLoadTodayAttendance);
    on<LoadAttendanceHistoryEvent>(_onLoadAttendanceHistory);
    on<CheckInRequestedEvent>(_onCheckInRequested);
    on<CheckOutRequestedEvent>(_onCheckOutRequested);
    on<ResetAttendanceEvent>(_onResetAttendance);
    on<RegularizeAttendanceRequestedEvent>(_onRegularizeAttendanceRequested);
    on<ExportAttendanceEvent>(_onExportAttendance);
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
    final currentHistory = (currentState is AttendanceLoadedState && event.isLoadMore)
        ? currentState.history
        : const <AttendanceRecord>[];

    if (event.isLoadMore) {
      if (currentState is AttendanceLoadedState) {
        emit(currentState.copyWith(isLoadingMore: true));
      }
    } else {
      emit(AttendanceLoadingState());
    }

    final historyResult = await getAttendanceHistoryUseCase(
      GetAttendanceHistoryParams(
        startDate: event.startDate,
        endDate: event.endDate,
        filter: event.filter,
        page: event.page,
        size: event.size,
        employeeId: event.employeeId,
        employeeName: event.employeeName,
      ),
    );

    historyResult.fold(
      (failure) {
        if (event.isLoadMore && currentState is AttendanceLoadedState) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else {
          emit(AttendanceErrorState(failure.message));
        }
      },
      (result) {
        final combinedHistory = event.isLoadMore
            ? [...currentHistory, ...result.records]
            : result.records;

        emit(AttendanceLoadedState(
          todayRecord: existingTodayRecord,
          history: combinedHistory,
          page: result.page,
          pageSize: result.pageSize,
          totalElements: result.totalElements,
          totalPages: result.totalPages,
          hasNext: result.hasNext,
          hasPrevious: result.hasPrevious,
          isLoadingMore: false,
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
        latitude: event.latitude,
        longitude: event.longitude,
        deviceId: event.deviceId,
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
        latitude: event.latitude,
        longitude: event.longitude,
        deviceId: event.deviceId,
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

  Future<void> _onRegularizeAttendanceRequested(
    RegularizeAttendanceRequestedEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;

    final result = await regularizeAttendanceUseCase(
      RegularizeAttendanceParams(
        attendanceId: event.attendanceId,
        requestedTimeOut: event.requestedTimeOut,
        reason: event.reason,
      ),
    );

    result.fold(
      (failure) {
        if (currentState is AttendanceLoadedState) {
          emit(currentState.copyWith(
            errorMessage: failure.message,
            successMessage: null,
          ));
        } else {
          emit(AttendanceErrorState(failure.message));
        }
      },
      (_) {
        if (currentState is AttendanceLoadedState) {
          emit(currentState.copyWith(
            successMessage: 'Regularization request submitted successfully!',
            errorMessage: null,
          ));
        } else {
          emit(const AttendanceLoadedState(
            successMessage: 'Regularization request submitted successfully!',
          ));
        }
      },
    );
  }

  Future<void> _onExportAttendance(
    ExportAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is AttendanceLoadedState) {
      emit(currentState.copyWith(
        isExporting: true,
        exportErrorMessage: null,
        exportResult: null,
        isExportShareCompleted: false,
      ));
    }

    final result = await exportAttendanceUseCase(
      ExportAttendanceParams(
        employeeId: event.employeeId,
        fromDate: event.fromDate,
        toDate: event.toDate,
      ),
    );

    await result.fold(
      (failure) async {
        final stateNow = state;
        if (stateNow is AttendanceLoadedState) {
          emit(stateNow.copyWith(
            isExporting: false,
            exportErrorMessage: failure.message,
          ));
        } else {
          emit(AttendanceErrorState(failure.message));
        }
      },
      (bytes) async {
        try {
          if (event.action == ExportAction.download) {
            final downloadResult = await ExcelExporter.saveBytesToDownloads(
              bytes: bytes,
              employeeId: event.employeeId,
              dateRange: event.dateRange,
              fromDate: event.fromDate,
              toDate: event.toDate,
            );
            final stateNow = state;
            if (stateNow is AttendanceLoadedState) {
              emit(stateNow.copyWith(
                isExporting: false,
                exportResult: downloadResult,
                exportErrorMessage: null,
              ));
            }
          } else {
            await ExcelExporter.shareBytes(
              bytes: bytes,
              employeeId: event.employeeId,
              dateRange: event.dateRange,
              fromDate: event.fromDate,
              toDate: event.toDate,
            );
            final stateNow = state;
            if (stateNow is AttendanceLoadedState) {
              emit(stateNow.copyWith(
                isExporting: false,
                isExportShareCompleted: true,
                exportErrorMessage: null,
              ));
            }
          }
        } catch (e) {
          final stateNow = state;
          if (stateNow is AttendanceLoadedState) {
            emit(stateNow.copyWith(
              isExporting: false,
              exportErrorMessage: e.toString(),
            ));
          }
        }
      },
    );
  }
}

