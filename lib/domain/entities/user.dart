import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final String company;
  final String? avatarUrl;
  final bool firstLogin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.company,
    this.avatarUrl,
    this.firstLogin = false,
  });

  @override
  List<Object?> get props => [id, name, email, role, company, avatarUrl, firstLogin];
}
