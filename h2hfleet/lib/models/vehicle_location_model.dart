class VehicleLocationModel {
  final String id;
  final String vehicleId;
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final DateTime updatedAt;

  VehicleLocationModel({
    required this.id,
    required this.vehicleId,
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    required this.updatedAt,
  });

  factory VehicleLocationModel.fromJson(Map<String, dynamic> json) {
    return VehicleLocationModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
