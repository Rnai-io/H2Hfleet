class ExpenseModel {
  final String id;
  final String vehicleId;
  final String type;
  final double amount;
  final String? note;
  final DateTime expenseDate;

  ExpenseModel({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.amount,
    this.note,
    required this.expenseDate,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      expenseDate: DateTime.parse(json['expense_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'type': type,
      'amount': amount,
      'note': note,
      'expense_date': expenseDate.toIso8601String(),
    };
  }
}
