import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/client_location.dart';
import '../../repositories/admin_repository.dart';

class GetLocationsUseCase implements UseCase<List<ClientLocation>, NoParams> {
  final AdminRepository repository;

  GetLocationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ClientLocation>>> call(NoParams params) async {
    return await repository.getLocations();
  }
}
