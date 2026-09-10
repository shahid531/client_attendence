import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_record.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitialState extends AttendanceState {}

class AttendanceLoadingState extends AttendanceState {}

class AttendanceLoadedState extends AttendanceState {
  final AttendanceRecord? todayRecord;
  final List<AttendanceRecord> history;
  final String? successMessage;
  final int page;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isLoadingMore;

  const AttendanceLoadedState({
    this.todayRecord,
    this.history = const [],
    this.successMessage,
    this.page = 0,
    this.pageSize = 10,
    this.totalElements = 0,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrevious = false,
    this.isLoadingMore = false,
  });

  AttendanceLoadedState copyWith({
    AttendanceRecord? todayRecord,
    List<AttendanceRecord>? history,
    String? successMessage,
    int? page,
    int? pageSize,
    int? totalElements,
    int? totalPages,
    bool? hasNext,
    bool? hasPrevious,
    bool? isLoadingMore,
  }) {
    return AttendanceLoadedState(
      todayRecord: todayRecord ?? this.todayRecord,
      history: history ?? this.history,
      successMessage: successMessage,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrevious: hasPrevious ?? this.hasPrevious,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        todayRecord,
        history,
        successMessage,
        page,
        pageSize,
        totalElements,
        totalPages,
        hasNext,
        hasPrevious,
        isLoadingMore,
      ];
}

class AttendanceErrorState extends AttendanceState {
  final String message;

  const AttendanceErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
