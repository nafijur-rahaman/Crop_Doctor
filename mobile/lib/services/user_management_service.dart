import '../core/constants/api_constants.dart';
import '../models/managed_user.dart';
import 'api_client.dart';

class UserManagementService {
  static Future<List<ManagedUser>> fetchAdminUsers() async {
    final data = await ApiClient.get(kAdminUsersUrl);
    if (data['_data'] is List) {
      final raw = data['_data'] as List;
      return raw
          .whereType<Map>()
          .map((e) => ManagedUser.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    // DRF typically returns a list for ViewSets; keep a fallback.
    final raw = data['results'] ?? data['users'] ?? data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ManagedUser.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<List<ManagedUser>> fetchExpertUsers() async {
    final data = await ApiClient.get(kExpertUsersUrl);
    if (data['_data'] is List) {
      final raw = data['_data'] as List;
      return raw
          .whereType<Map>()
          .map((e) => ManagedUser.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    final raw = data['results'] ?? data['users'] ?? data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ManagedUser.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<ManagedUser> expertVerifyPaidUser({
    required int userId,
    required bool isVerified,
  }) async {
    final data = await ApiClient.patch(
      '$kExpertUsersUrl$userId/verify/',
      {'is_verified': isVerified},
    );
    return ManagedUser.fromJson(data);
  }

  static Future<ManagedUser> adminVerifyUser({
    required int userId,
    required bool isVerified,
  }) async {
    final data = await ApiClient.patch(
      '$kAdminUsersUrl$userId/verify/',
      {'is_verified': isVerified},
    );
    return ManagedUser.fromJson(data);
  }
}

