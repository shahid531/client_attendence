import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/usecases/leave/get_leave_requests_usecase.dart';
import '../../../domain/usecases/leave/submit_leave_request_usecase.dart';
import '../../../domain/usecases/leave/update_request_status_usecase.dart';
import 'leave_event.dart';
import 'leave_state.dart';

class LeaveBloc extends Bloc<LeaveEvent, LeaveState> {
  final SubmitLeaveRequestUseCase submitLeaveRequestUseCase;
  final GetLeaveRequestsUseCase getLeaveRequestsUseCase;
  final UpdateRequestStatusUseCase updateRequestStatusUseCase;

  LeaveBloc({
    required this.submitLeaveRequestUseCase,
    required this.getLeaveRequestsUseCase,
    required this.updateRequestStatusUseCase,
  }) : super(LeaveInitialState()) {
    on<LoadLeaveRequestsEvent>(_onLoadLeaveRequests);
    on<SubmitLeaveRequestEvent>(_onSubmitLeaveRequest);
    on<UpdateRequestStatusEvent>(_onUpdateRequestStatus);
  }

  Future<void> _onLoadLeaveRequests(
    LoadLeaveRequestsEvent event,
    Emitter<LeaveState> emit,
  ) async {
    emit(LeaveLoadingState());
    final result = await getLeaveRequestsUseCase(
      GetLeaveRequestsParams(status: event.status),
    );
    result.fold(
      (failure) => emit(LeaveErrorState(failure.message)),
      (requests) => emit(LeaveLoadedState(requests: requests)),
    );
  }

  Future<void> _onSubmitLeaveRequest(
    SubmitLeaveRequestEvent event,
    Emitter<LeaveState> emit,
  ) async {
    emit(LeaveLoadingState());
    final result = await submitLeaveRequestUseCase(
      SubmitLeaveParams(
        title: event.title,
        requestType: event.requestType,
        startDate: event.startDate,
        endDate: event.endDate,
        reason: event.reason,
      ),
    );

    await result.fold(
      (failure) async => emit(LeaveErrorState(failure.message)),
      (newRequest) async {
        final listResult = await getLeaveRequestsUseCase(
          const GetLeaveRequestsParams(),
        );
        final requests = listResult.getOrElse(() => [newRequest]);
        emit(LeaveLoadedState(
          requests: requests,
          successMessage: 'Request submitted successfully!',
        ));
      },
    );
  }

  Future<void> _onUpdateRequestStatus(
    UpdateRequestStatusEvent event,
    Emitter<LeaveState> emit,
  ) async {
    emit(LeaveLoadingState());
    final result = await updateRequestStatusUseCase(
      UpdateRequestStatusParams(
        requestId: event.requestId,
        status: event.status,
        remarks: event.remarks,
      ),
    );

    await result.fold(
      (failure) async => emit(LeaveErrorState(failure.message)),
      (_) async {
        final listResult = await getLeaveRequestsUseCase(
          const GetLeaveRequestsParams(),
        );
        final requests = listResult.getOrElse(() => []);
        emit(LeaveLoadedState(
          requests: requests,
          successMessage: 'Request marked as ${event.status}!',
        ));
      },
    );
  }
}
