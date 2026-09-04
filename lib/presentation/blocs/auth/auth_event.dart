import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStartedEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String username;
  final String password;
  final String deviceId;
  final String deviceModel;
  final String operatingSystem;

  const LoginSubmittedEvent({
    required this.username,
    required this.password,
    this.deviceId = 'flutter_app_01',
    this.deviceModel = 'Mobile',
    this.operatingSystem = 'Android',
  });

  @override
  List<Object?> get props => [username, password, deviceId, deviceModel, operatingSystem];
}

class LogoutRequestedEvent extends AuthEvent {}

class LoadUserProfileEvent extends AuthEvent {}
