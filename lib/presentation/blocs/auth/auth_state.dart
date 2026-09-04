import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final User user;

  const AuthenticatedState(this.user);

  @override
  List<Object?> get props => [user];
}

class UnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
