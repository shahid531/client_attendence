import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/client_location.dart';
import '../../repositories/admin_repository.dart';

class CreateLocationUseCase
    implements UseCase<ClientLocation, CreateLocationParams> {
  final AdminRepository repository;

  CreateLocationUseCase(this.repository);

  @override
  Future<Either<Failure, ClientLocation>> call(
      CreateLocationParams params) async {
    return await repository.createLocation(
      clientName: params.clientName,
      locationName: params.locationName,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      allowedRadius: params.allowedRadius,
    );
  }
}

class CreateLocationParams extends Equatable {
  final String clientName;
  final String locationName;
  final String address;
  final double latitude;
  final double longitude;
  final double allowedRadius;

  const CreateLocationParams({
    required this.clientName,
    required this.locationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.allowedRadius,
  });

  @override
  List<Object?> get props => [
        clientName,
        locationName,
        address,
        latitude,
        longitude,
        allowedRadius,
      ];
}
