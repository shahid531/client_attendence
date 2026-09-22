import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/client_location.dart';
import '../../repositories/admin_repository.dart';

class GetLocationsUseCase implements UseCase<List<ClientLocation>, GetLocationsParams> {
  final AdminRepository repository;

  GetLocationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ClientLocation>>> call(GetLocationsParams params) async {
    return await repository.getLocations(
      clientName: params.clientName,
      city: params.city,
    );
  }
}

class GetLocationsParams extends Equatable {
  final String? clientName;
  final String? city;

  const GetLocationsParams({
    this.clientName,
    this.city,
  });

  @override
  List<Object?> get props => [clientName, city];
}
