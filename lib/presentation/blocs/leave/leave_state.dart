import 'package:equatable/equatable.dart';
import '../../../domain/entities/leave_request.dart';

abstract class LeaveState extends Equatable {
  const LeaveState();

  @override
  List<Object?> get props => [];
}

class LeaveInitialState extends LeaveState {}

class LeaveLoadingState extends LeaveState {}

class LeaveLoadedState extends LeaveState {
  final List<LeaveRequest> requests;
  final String? successMessage;
  final int page;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isLoadingMore;
  final int? pendingCount;
  final int? completedCount;

  const LeaveLoadedState({
    required this.requests,
    this.successMessage,
    this.page = 0,
    this.pageSize = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrevious = false,
    this.isLoadingMore = false,
    this.pendingCount,
    this.completedCount,
  });

  LeaveLoadedState copyWith({
    List<LeaveRequest>? requests,
    String? successMessage,
    int? page,
    int? pageSize,
    int? totalElements,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    bool? isLoadingMore,
    int? pendingCount,
    int? completedCount,
  }) {
    return LeaveLoadedState(
      requests: requests ?? this.requests,
      successMessage: successMessage,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  List<Object?> get props => [
        requests,
        successMessage,
        page,
        pageSize,
        totalElements,
        totalPages,
        hasNext,
        hasPrevious,
        isLoadingMore,
        pendingCount,
        completedCount,
      ];
}

class LeaveErrorState extends LeaveState {
  final String message;

  const LeaveErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
