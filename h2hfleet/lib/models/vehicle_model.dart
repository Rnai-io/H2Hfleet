class VehicleModel {
  final String id;
  final String companyId;
  final String plateNumber;
  final String? nickName;  // ชื่อเล่นของรถ
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final String fuelType;
  final String status;
  final String? remark;

  VehicleModel({
    required this.id,
    required this.companyId,
    required this.plateNumber,
    this.nickName,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.status,
    this.remark,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      plateNumber: json['plate_number'] as String,
      nickName: json['nick_name'] as String?,
      vehicleType: json['vehicle_type'] as String,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? 2024,
      fuelType: json['fuel_type'] as String? ?? 'diesel',
      status: json['status'] as String? ?? 'active',
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company_id': companyId,
      'plate_number': plateNumber,
      if (nickName != null && nickName!.isNotEmpty) 'nick_name': nickName,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'fuel_type': fuelType,
      'status': status,
      if (remark != null && remark!.isNotEmpty) 'remark': remark,
    };
  }
}
