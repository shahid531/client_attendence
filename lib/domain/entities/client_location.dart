import 'package:equatable/equatable.dart';

class ClientLocation extends Equatable {
  final int? id;
  final String locationId;
  final String? clientName;
  final String? city;
  final String locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double? allowedRadius;
  final double? halfDayHrs;
  final double? fullDayHrs;
  final String? status;
  final String? createdAt;
  final String? updatedAt;

  const ClientLocation({
    this.id,
    required this.locationId,
    this.clientName,
    this.city,
    required this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    this.allowedRadius,
    this.halfDayHrs,
    this.fullDayHrs,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  ClientLocation copyWith({
    int? id,
    String? locationId,
    String? clientName,
    String? city,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    double? allowedRadius,
    double? halfDayHrs,
    double? fullDayHrs,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ClientLocation(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      clientName: clientName ?? this.clientName,
      city: city ?? this.city,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      allowedRadius: allowedRadius ?? this.allowedRadius,
      halfDayHrs: halfDayHrs ?? this.halfDayHrs,
      fullDayHrs: fullDayHrs ?? this.fullDayHrs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        locationId,
        clientName,
        city,
        locationName,
        address,
        latitude,
        longitude,
        allowedRadius,
        halfDayHrs,
        fullDayHrs,
        status,
        createdAt,
        updatedAt,
      ];
}
