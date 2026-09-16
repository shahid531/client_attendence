import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/app_version_info.dart';
import '../../domain/repositories/app_config_repository.dart';
import '../datasources/app_config_remote_datasource.dart';

class AppConfigRepositoryImpl implements AppConfigRepository {
  final AppConfigRemoteDataSource remoteDataSource;

  AppConfigRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, AppVersionInfo>> checkAppVersion() async {
    try {
      final versionInfo = await remoteDataSource.checkAppVersion();
      return Right(versionInfo);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
