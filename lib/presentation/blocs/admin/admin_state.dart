import 'package:equatable/equatable.dart';
import '../../../domain/entities/created_employee.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitialState extends AdminState {}

class AdminLoadingState extends AdminState {}

class CreateEmployeeSuccessState extends AdminState {
  final CreatedEmployee employee;
  final String message;

  const CreateEmployeeSuccessState({
    required this.employee,
    this.message = 'Employee created successfully',
  });

  @override
  List<Object?> get props => [employee, message];
}

class AdminFailureState extends AdminState {
  final String message;

  const AdminFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
