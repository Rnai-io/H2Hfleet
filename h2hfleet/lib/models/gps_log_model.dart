class GpsLogModel {
  final String id;
  final String vehicleId;
  final double lat;
  final double lng;
  final double speed;
  final DateTime recordedAt;

  GpsLogModel({
    required this.id,
    required this.vehicleId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.recordedAt,
  });

  factory GpsLogModel.fromJson(Map<String, dynamic> json) {
    return GpsLogModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num? ?? 0).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String).toLocal(),
    );
  }
}
