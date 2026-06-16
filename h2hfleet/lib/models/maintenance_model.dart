class MaintenanceModel {
  final String id;
  final String vehicleId;
  final String type;
  final String partCategory;
  final String? partName;
  final String? description;
  final double cost;
  final String? photoUrl;
  final DateTime? dueDate;
  final int? dueKm;
  final DateTime? completedDate;
  final String status; // pending, completed, overdue

  MaintenanceModel({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.partCategory,
    this.partName,
    this.description,
    required this.cost,
    this.photoUrl,
    this.dueDate,
    this.dueKm,
    this.completedDate,
    required this.status,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      type: json['type'] as String? ?? '',
      partCategory: json['part_category'] as String? ?? 'other',
      partName: json['part_name'] as String?,
      description: json['description'] as String?,
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photo_url'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      dueKm: json['due_km'] as int?,
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'type': type,
      'part_category': partCategory,
      if (partName != null && partName!.isNotEmpty) 'part_name': partName,
      if (description != null && description!.isNotEmpty) 'description': description,
      'cost': cost,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T').first,
      if (dueKm != null) 'due_km': dueKm,
      if (completedDate != null)
        'completed_date': completedDate!.toIso8601String().split('T').first,
      'status': status,
    };
  }
}
