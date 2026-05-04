class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    required this.role,
    this.profileImageUrl,
    required this.isVerified,
  });

  final int id;
  final String username;
  final String email;
  final String? phone;
  final String role;
  final String? profileImageUrl;
  final bool isVerified;

  String get initials {
    final parts = username.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  String get displayRole {
    if (role == 'guest') return 'Guest';
    switch (role) {
      case 'paid':
        return 'Premium User';
      case 'expert':
        return 'Expert';
      case 'superadmin':
        return 'Super Admin';
      default:
        return 'Free User';
    }
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as num).toInt(),
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phone: json['phone'] as String?,
      role: (json['role'] as String?) ?? 'guest',
      profileImageUrl: json['profile_image'] as String?,
      isVerified: (json['is_verified'] as bool?) ?? false,
    );
  }
}
