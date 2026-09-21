import 'package:equatable/equatable.dart';

class ClientLocation extends Equatable {
  final int? id;
  final String locationId;
  final String? clientName;
  final String locationName;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final double? allowedRadius;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const ClientLocation({
    this.id,
    required this.locationId,
    this.clientName,
    required this.locationName,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.allowedRadius,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        locationId,
        clientName,
        locationName,
        address,
        city,
        latitude,
        longitude,
        allowedRadius,
        status,
        createdAt,
        updatedAt,
      ];
}
