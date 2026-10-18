import '../../domain/models/app_user.dart';

class AuthApiModel {
  const AuthApiModel({
    required this.accessToken,
    required this.expiresAtUtc,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAtUtc;
  final AppUser user;

  factory AuthApiModel.fromJson(Map<String, dynamic> json) => AuthApiModel(
    accessToken: json['accessToken'] as String,
    expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
    user: UserApiModel.fromJson(json['user'] as Map<String, dynamic>)
        .toDomain(),
  );

  AppUserSession toDomain() => AppUserSession(
    accessToken: accessToken,
    expiresAtUtc: expiresAtUtc,
    user: user,
  );
}

class UserApiModel {
  const UserApiModel({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    this.phoneNumber,
  });

  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String? phoneNumber;

  factory UserApiModel.fromJson(Map<String, dynamic> json) => UserApiModel(
    userId: json['userId'] as String,
    email: json['email'] as String,
    fullName: json['fullName'] as String,
    role: json['role'] as String,
    phoneNumber: json['phoneNumber'] as String?,
  );

  AppUser toDomain() => AppUser(
    userId: userId,
    email: email,
    fullName: fullName,
    phoneNumber: phoneNumber,
    role: role,
  );
}
