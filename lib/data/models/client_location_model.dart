import '../../domain/entities/client_location.dart';

class ClientLocationModel extends ClientLocation {
  const ClientLocationModel({
    super.id,
    required super.locationId,
    super.clientName,
    required super.locationName,
    super.address,
    super.city,
    super.latitude,
    super.longitude,
    super.allowedRadius,
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
      locationName: json['locationName']?.toString() ?? '',
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      latitude: parseDouble(json['latitude'] ?? json['lat']),
      longitude: parseDouble(json['longitude'] ?? json['lng'] ?? json['log']),
      allowedRadius: parseDouble(json['allowedRadius']),
      status: json['status']?.toString() ?? 'Active',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'clientName': clientName,
      'locationName': locationName,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'allowedRadius': allowedRadius,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
