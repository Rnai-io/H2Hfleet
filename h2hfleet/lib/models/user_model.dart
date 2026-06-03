class UserModel {
  final String id;
  final String email;
  final String name;
  final String companyId;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.companyId,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      companyId: json['company_id'] as String,
      role: json['role'] as String? ?? 'owner',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'company_id': companyId,
      'role': role,
    };
  }
}
