import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/leave_request.dart';
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
    final currentState = state;
    final currentRequests = (currentState is LeaveLoadedState && event.isLoadMore)
        ? currentState.requests
        : const <LeaveRequest>[];

    if (event.isLoadMore) {
      if (currentState is LeaveLoadedState) {
        emit(currentState.copyWith(isLoadingMore: true));
      }
    } else {
      emit(LeaveLoadingState());
    }

    final result = await getLeaveRequestsUseCase(
      GetLeaveRequestsParams(
        status: event.status,
        page: event.page,
        pageSize: event.pageSize,
        employeeId: event.employeeId,
        employeeName: event.employeeName,
        isApprovals: event.isApprovals,
      ),
    );

    result.fold(
      (failure) {
        if (event.isLoadMore && currentState is LeaveLoadedState) {
          emit(currentState.copyWith(isLoadingMore: false));
        } else {
          emit(LeaveErrorState(failure.message));
        }
      },
      (res) {
        final combined = event.isLoadMore
            ? [...currentRequests, ...res.requests]
            : res.requests;


        emit(LeaveLoadedState(
          requests: combined,
          page: res.page,
          pageSize: res.pageSize,
          totalElements: res.totalElements,
          totalPages: res.totalPages,
          hasNext: res.hasNext,
          hasPrevious: res.hasPrevious,
          pendingCount: res.pendingCount,
          completedCount: res.completedCount,
          isLoadingMore: false,
        ));
      },
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
        final res = listResult.getOrElse(() => LeaveRequestsResult(requests: [newRequest]));
        emit(LeaveLoadedState(
          requests: res.requests,
          page: res.page,
          pageSize: res.pageSize,
          totalElements: res.totalElements,
          totalPages: res.totalPages,
          hasNext: res.hasNext,
          hasPrevious: res.hasPrevious,
          pendingCount: res.pendingCount,
          completedCount: res.completedCount,
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
      (apiMessage) async {
        final listResult = await getLeaveRequestsUseCase(
          GetLeaveRequestsParams(
            status: event.isApprovals ? 'PENDING' : 'PENDING,APPROVED,REJECTED',
            isApprovals: event.isApprovals,
          ),
        );
        final res = listResult.getOrElse(() => const LeaveRequestsResult(requests: []));
        emit(LeaveLoadedState(
          requests: res.requests,
          page: res.page,
          pageSize: res.pageSize,
          totalElements: res.totalElements,
          totalPages: res.totalPages,
          hasNext: res.hasNext,
          hasPrevious: res.hasPrevious,
          pendingCount: res.pendingCount,
          completedCount: res.completedCount,
          successMessage: apiMessage.isNotEmpty
              ? apiMessage
              : 'Request marked as ${event.status}!',
        )
        );
      },
    );
  }
}

