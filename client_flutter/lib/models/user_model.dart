
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;
  final String? phone;
  final String? profile;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
    this.phone,
    this.profile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'],
      phone: json['phone'],
      profile: json['profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'token': token,
      'phone': phone,
      'profile': profile,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory UserModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserModel.fromJson(json);
  }
}