import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.company,
    super.avatarUrl,
    required super.firstLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['employeeId']?.toString() ?? json['username']?.toString() ?? json['id']?.toString() ?? '',
      name: json['fullName']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '${json['username'] ?? 'user'}@clientsite.com',
      role: json['role']?.toString() ?? 'Employee',
      company: json['company']?.toString() ?? 'Acme Corp',
      avatarUrl: json['avatarUrl']?.toString(),
      firstLogin: json['firstLogin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'company': company,
      'avatarUrl': avatarUrl,
      'firstLogin': firstLogin,
    };
  }
}
