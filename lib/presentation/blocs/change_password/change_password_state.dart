import 'package:equatable/equatable.dart';

abstract class ChangePasswordState extends Equatable {
  const ChangePasswordState();

  @override
  List<Object?> get props => [];
}

class ChangePasswordInitialState extends ChangePasswordState {}

class ChangePasswordLoadingState extends ChangePasswordState {}

class ChangePasswordSuccessState extends ChangePasswordState {
  final String message;

  const ChangePasswordSuccessState([this.message = 'Password changed successfully!']);

  @override
  List<Object?> get props => [message];
}

class ChangePasswordFailureState extends ChangePasswordState {
  final String message;

  const ChangePasswordFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
