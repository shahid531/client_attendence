import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String username,
    required String password,
    String deviceId,
    String deviceModel,
    String operatingSystem,
  });
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User?>> getCurrentUser();
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
