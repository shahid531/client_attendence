import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/app_version_info.dart';

abstract class AppConfigRepository {
  Future<Either<Failure, AppVersionInfo>> checkAppVersion();
}
