class AppUser {
  const AppUser({
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

  bool get isAdmin => role.toUpperCase() == 'ADMIN';
}

class AppUserSession {
  const AppUserSession({
    required this.accessToken,
    required this.expiresAtUtc,
    required this.user,
  });

  final String accessToken;
  final DateTime expiresAtUtc;
  final AppUser user;
}
