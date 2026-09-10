import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/domain/entities/attendance_record.dart';
import 'package:client_attendence/domain/repositories/attendance_repository.dart';
import 'package:client_attendence/domain/usecases/attendance/check_in_usecase.dart';
import 'package:client_attendence/domain/usecases/attendance/check_out_usecase.dart';
import 'package:client_attendence/domain/usecases/attendance/get_attendance_history_usecase.dart';
import 'package:client_attendence/domain/usecases/attendance/get_today_attendance_usecase.dart';
import 'package:client_attendence/presentation/blocs/attendance/attendance_bloc.dart';
import 'package:client_attendence/presentation/blocs/attendance/attendance_event.dart';
import 'package:client_attendence/presentation/blocs/attendance/attendance_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAttendanceRepository implements AttendanceRepository {
  AttendanceRecord? _today;
  final List<AttendanceRecord> _history = [];

  @override
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    final record = AttendanceRecord(
      id: '1',
      date: DateTime.now(),
      checkInTime: '09:00 AM',
      workType: workType,
      location: location,
      description: description,
      totalHours: 0.0,
      status: 'Present',
    );
    _today = record;
    return Right(record);
  }

  @override
  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    final record = AttendanceRecord(
      id: recordId,
      date: DateTime.now(),
      checkInTime: '09:00 AM',
      checkOutTime: '05:00 PM',
      workType: 'GPS',
      location: 'HQ',
      description: description,
      totalHours: 8.0,
      status: 'Present',
    );
    _today = record;
    return Right(record);
  }

  @override
  Future<Either<Failure, AttendanceHistoryResult>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    String? employeeId,
    String? employeeName,
    int page = 0,
    int size = 10,
  }) async {
    return Right(AttendanceHistoryResult(
      records: _history,
      totalPages: 1,
      totalElements: _history.length,
      page: page,
      hasNext: false,
    ));
  }

  @override
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance() async {
    return Right(_today);
  }
}

void main() {
  late AttendanceBloc bloc;
  late MockAttendanceRepository repository;

  setUp(() {
    repository = MockAttendanceRepository();
    bloc = AttendanceBloc(
      checkInUseCase: CheckInUseCase(repository),
      checkOutUseCase: CheckOutUseCase(repository),
      getAttendanceHistoryUseCase: GetAttendanceHistoryUseCase(repository),
      getTodayAttendanceUseCase: GetTodayAttendanceUseCase(repository),
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be AttendanceInitialState', () {
    expect(bloc.state, AttendanceInitialState());
  });

  test('should emit [AttendanceLoadedState] when LoadTodayAttendanceEvent is added', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AttendanceLoadedState(todayRecord: null, history: []),
      ]),
    );

    bloc.add(LoadTodayAttendanceEvent());
    await expectation;
  });

  test('should emit [AttendanceLoadingState, AttendanceLoadedState] with new record when CheckInRequestedEvent is added', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        AttendanceLoadingState(),
        isA<AttendanceLoadedState>().having(
          (s) => s.todayRecord?.workType,
          'workType',
          'GPS',
        ),
      ]),
    );

    bloc.add(const CheckInRequestedEvent(
      workType: 'GPS',
      location: 'HQ',
      description: 'Starting workday',
    ));
    await expectation;
  });

  test('should emit [AttendanceLoadingState, AttendanceErrorState] when CheckIn fails', () async {
    final failingRepo = FailingAttendanceRepository();
    final failingBloc = AttendanceBloc(
      checkInUseCase: CheckInUseCase(failingRepo),
      checkOutUseCase: CheckOutUseCase(failingRepo),
      getAttendanceHistoryUseCase: GetAttendanceHistoryUseCase(failingRepo),
      getTodayAttendanceUseCase: GetTodayAttendanceUseCase(failingRepo),
    );

    final expectation = expectLater(
      failingBloc.stream,
      emitsInOrder([
        AttendanceLoadingState(),
        const AttendanceErrorState(
          'Admin cannot mark attendance directly without an employee profile',
        ),
      ]),
    );

    failingBloc.add(const CheckInRequestedEvent(
      workType: 'WFH',
      location: 'Home Office',
      description: 'WFH Task',
    ));
    await expectation;
    await failingBloc.close();
  });

  test('should emit [AttendanceLoadingState, AttendanceLoadedState] with filtered history when LoadAttendanceHistoryEvent is added', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        AttendanceLoadingState(),
        const AttendanceLoadedState(history: []),
      ]),
    );

    bloc.add(const LoadAttendanceHistoryEvent(
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    ));
    await expectation;
  });

  test('should emit [AttendanceLoadedState(isLoadingMore: true), AttendanceLoadedState(isLoadingMore: false)] when isLoadMore is true', () async {
    // Initial load
    bloc.add(const LoadAttendanceHistoryEvent(
      startDate: '2026-09-01',
      endDate: '2026-09-30',
      page: 0,
    ));
    await Future.delayed(const Duration(milliseconds: 50));

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        const AttendanceLoadedState(history: [], isLoadingMore: true),
        const AttendanceLoadedState(history: [], page: 1, isLoadingMore: false),
      ]),
    );

    bloc.add(const LoadAttendanceHistoryEvent(
      startDate: '2026-09-01',
      endDate: '2026-09-30',
      page: 1,
      isLoadMore: true,
    ));
    await expectation;
  });
}

class FailingAttendanceRepository implements AttendanceRepository {
  @override
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    return const Left(
      ServerFailure('Admin cannot mark attendance directly without an employee profile'),
    );
  }

  @override
  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
    double? latitude,
    double? longitude,
    String? deviceId,
  }) async {
    return const Left(
      ServerFailure('Attendance time-out failed'),
    );
  }

  @override
  Future<Either<Failure, AttendanceHistoryResult>> getAttendanceHistory({
    String? startDate,
    String? endDate,
    String? filter,
    String? employeeId,
    String? employeeName,
    int page = 0,
    int size = 10,
  }) async {
    return const Right(AttendanceHistoryResult(
      records: [],
      totalPages: 0,
      totalElements: 0,
      page: 0,
      hasNext: false,
    ));
  }

  @override
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance() async {
    return const Right(null);
  }
}
