import '../../domain/entities/client_location.dart';

class ClientLocationModel extends ClientLocation {
  const ClientLocationModel({
    super.id,
    required super.locationId,
    super.clientName,
    super.city,
    required super.locationName,
    super.address,
    super.latitude,
    super.longitude,
    super.allowedRadius,
    super.halfDayHrs,
    super.fullDayHrs,
    super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory ClientLocationModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return ClientLocationModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      locationId: json['locationId']?.toString() ?? '',
      clientName: json['clientName']?.toString(),
      city: json['city']?.toString() ?? json['cityName']?.toString(),
      locationName: json['locationName']?.toString() ?? json['clientName']?.toString() ?? '',
      address: json['address']?.toString(),
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng'] ?? json['log']),
      allowedRadius: parseDouble(json['allowedRadius']),
      halfDayHrs: parseDouble(json['halfDayHrs']),
      fullDayHrs: parseDouble(json['fullDayHrs']),
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'locationId': locationId,
      'clientName': clientName,
      'city': city,
      'locationName': locationName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'allowedRadius': allowedRadius,
      if (halfDayHrs != null) 'halfDayHrs': halfDayHrs,
      if (fullDayHrs != null) 'fullDayHrs': fullDayHrs,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}
