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
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory() async {
    return Right(_history);
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

  test('should emit [AttendanceLoadingState, AttendanceLoadedState] when LoadTodayAttendanceEvent is added', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        AttendanceLoadingState(),
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
}

class FailingAttendanceRepository implements AttendanceRepository {
  @override
  Future<Either<Failure, AttendanceRecord>> checkIn({
    required String workType,
    required String location,
    required String description,
  }) async {
    return const Left(
      ServerFailure('Admin cannot mark attendance directly without an employee profile'),
    );
  }

  @override
  Future<Either<Failure, AttendanceRecord>> checkOut({
    required String recordId,
    required String description,
  }) async {
    return const Left(
      ServerFailure('Attendance time-out failed'),
    );
  }

  @override
  Future<Either<Failure, List<AttendanceRecord>>> getAttendanceHistory() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, AttendanceRecord?>> getTodayAttendance() async {
    return const Right(null);
  }
}
