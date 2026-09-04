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

  const AttendanceLoadedState({
    this.todayRecord,
    this.history = const [],
    this.successMessage,
  });

  AttendanceLoadedState copyWith({
    AttendanceRecord? todayRecord,
    List<AttendanceRecord>? history,
    String? successMessage,
  }) {
    return AttendanceLoadedState(
      todayRecord: todayRecord ?? this.todayRecord,
      history: history ?? this.history,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [todayRecord, history, successMessage];
}

class AttendanceErrorState extends AttendanceState {
  final String message;

  const AttendanceErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
