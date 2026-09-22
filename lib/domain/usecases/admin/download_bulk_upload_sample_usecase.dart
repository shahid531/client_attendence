import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/admin_repository.dart';

class DownloadBulkUploadSampleUseCase implements UseCase<String, NoParams> {
  final AdminRepository repository;

  DownloadBulkUploadSampleUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) async {
    return await repository.downloadBulkUploadSample();
  }
}
