class DriverLocationModel {
  final String id;
  final String vehicleId;
  final String userId;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final DateTime updatedAt;

  DriverLocationModel({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.updatedAt,
  });

  factory DriverLocationModel.fromJson(Map<String, dynamic> json) {
    return DriverLocationModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      userId: json['user_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num? ?? 0).toDouble(),
      heading: (json['heading'] as num? ?? 0).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
