import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? json['type'] ?? 'USER') as String,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, permissions];
}
