import 'package:client_attendence/core/errors/failures.dart';
import 'package:client_attendence/domain/entities/leave_request.dart';
import 'package:client_attendence/domain/repositories/leave_repository.dart';
import 'package:client_attendence/domain/usecases/leave/get_leave_requests_usecase.dart';
import 'package:client_attendence/domain/usecases/leave/submit_leave_request_usecase.dart';
import 'package:client_attendence/domain/usecases/leave/update_request_status_usecase.dart';
import 'package:client_attendence/presentation/blocs/leave/leave_bloc.dart';
import 'package:client_attendence/presentation/blocs/leave/leave_event.dart';
import 'package:client_attendence/presentation/blocs/leave/leave_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLeaveRepository implements LeaveRepository {
  final List<LeaveRequest> _requests = [
    LeaveRequest(
      id: '12',
      title: 'Saheed Ansari - WFH Request',
      requestType: 'WFH',
      startDate: DateTime.parse('2026-09-04'),
      endDate: DateTime.parse('2026-09-04'),
      reason: 'hub',
      status: 'Pending',
      submittedAt: DateTime.parse('2026-09-04T11:22:58'),
      employeeName: 'Saheed Ansari',
      employeeId: '20173',
      requestId: 'REQD0A86734',
    ),
  ];

  @override
  Future<Either<Failure, LeaveRequestsResult>> getLeaveRequests({
    String? status,
    int page = 0,
    int pageSize = 10,
    String? employeeId,
    String? employeeName,
  }) async {
    List<LeaveRequest> list = _requests;
    if (status != null && status.isNotEmpty) {
      list = _requests.where((r) => r.status.toLowerCase() == status.toLowerCase()).toList();
    }
    return Right(LeaveRequestsResult(
      requests: list,
      page: page,
      pageSize: pageSize,
      totalElements: list.length,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    ));
  }

  @override
  Future<Either<Failure, LeaveRequest>> submitLeaveRequest({
    required String title,
    required String requestType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final req = LeaveRequest(
      id: 'new_1',
      title: title,
      requestType: requestType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      status: 'Pending',
      submittedAt: DateTime.now(),
    );
    _requests.insert(0, req);
    return Right(req);
  }

  @override
  Future<Either<Failure, void>> updateRequestStatus({
    required String requestId,
    required String status,
    String? remarks,
  }) async {
    return const Right(null);
  }
}

void main() {
  late LeaveBloc bloc;
  late MockLeaveRepository repository;

  setUp(() {
    repository = MockLeaveRepository();
    bloc = LeaveBloc(
      submitLeaveRequestUseCase: SubmitLeaveRequestUseCase(repository),
      getLeaveRequestsUseCase: GetLeaveRequestsUseCase(repository),
      updateRequestStatusUseCase: UpdateRequestStatusUseCase(repository),
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be LeaveInitialState', () {
    expect(bloc.state, LeaveInitialState());
  });

  test('should emit [LeaveLoadingState, LeaveLoadedState] when LoadLeaveRequestsEvent is dispatched with status PENDING', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        LeaveLoadingState(),
        isA<LeaveLoadedState>().having(
          (s) => s.requests.length,
          'requests length',
          1,
        ),
      ]),
    );

    bloc.add(const LoadLeaveRequestsEvent(status: 'PENDING'));
    await expectation;
  });
}
