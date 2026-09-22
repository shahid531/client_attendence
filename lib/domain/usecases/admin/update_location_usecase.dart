import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/client_location.dart';
import '../../repositories/admin_repository.dart';

class UpdateLocationUseCase
    implements UseCase<ClientLocation, UpdateLocationParams> {
  final AdminRepository repository;

  UpdateLocationUseCase(this.repository);

  @override
  Future<Either<Failure, ClientLocation>> call(
      UpdateLocationParams params) async {
    return await repository.updateLocation(
      id: params.id,
      clientName: params.clientName,
      locationName: params.locationName,
      address: params.address,
      city: params.city,
      latitude: params.latitude,
      longitude: params.longitude,
      allowedRadius: params.allowedRadius,
      halfDayHrs: params.halfDayHrs,
      fullDayHrs: params.fullDayHrs,
      status: params.status,
    );
  }
}

class UpdateLocationParams extends Equatable {
  final dynamic id;
  final String clientName;
  final String locationName;
  final String address;
  final String? city;
  final double latitude;
  final double longitude;
  final double allowedRadius;
  final double? halfDayHrs;
  final double? fullDayHrs;
  final String? status;

  const UpdateLocationParams({
    required this.id,
    required this.clientName,
    required this.locationName,
    required this.address,
    this.city,
    required this.latitude,
    required this.longitude,
    required this.allowedRadius,
    this.halfDayHrs,
    this.fullDayHrs,
    this.status,
  });

  @override
  List<Object?> get props => [
        id,
        clientName,
        locationName,
        address,
        city,
        latitude,
        longitude,
        allowedRadius,
        halfDayHrs,
        fullDayHrs,
        status,
      ];
}
