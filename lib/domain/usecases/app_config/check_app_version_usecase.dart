import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/app_version_info.dart';
import '../../repositories/app_config_repository.dart';

class CheckAppVersionUseCase implements UseCase<AppVersionInfo, NoParams> {
  final AppConfigRepository repository;

  CheckAppVersionUseCase(this.repository);

  @override
  Future<Either<Failure, AppVersionInfo>> call(NoParams params) async {
    return await repository.checkAppVersion();
  }
}
