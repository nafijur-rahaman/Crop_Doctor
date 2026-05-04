class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isVerified,
    this.phone,
    this.isActive,
    this.isStaff,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final bool isVerified;
  final String? phone;
  final bool? isActive;
  final bool? isStaff;

  String get roleLabel {
    switch (role) {
      case 'paid':
        return 'Premium';
      case 'expert':
        return 'Expert';
      case 'superadmin':
        return 'Super Admin';
      case 'guest':
      default:
        return 'Guest';
    }
  }

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: (json['id'] as num).toInt(),
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'guest',
      phone: json['phone'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
      isActive: json['is_active'] as bool?,
      isStaff: json['is_staff'] as bool?,
    );
  }
}

