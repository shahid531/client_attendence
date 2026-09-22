import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/admin_repository.dart';

class BulkUploadEmployeesUseCase
    implements UseCase<Map<String, dynamic>, BulkUploadParams> {
  final AdminRepository repository;

  BulkUploadEmployeesUseCase(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(
      BulkUploadParams params) async {
    return await repository.bulkUploadEmployees(
      filePath: params.filePath,
      fileName: params.fileName,
      fileBytes: params.fileBytes,
    );
  }
}

class BulkUploadParams extends Equatable {
  final String filePath;
  final String fileName;
  final List<int>? fileBytes;

  const BulkUploadParams({
    required this.filePath,
    required this.fileName,
    this.fileBytes,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileBytes];
}
