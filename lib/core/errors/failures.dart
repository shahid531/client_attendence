import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Error Occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Error Occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet Connection']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
