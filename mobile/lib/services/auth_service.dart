import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

/// Handles auth token + guest ID persistence, login, register, logout.
class AuthService {
  static const _kToken = 'auth_token';
  static const _kRole = 'user_role';
  static const _kGuestId = 'guest_id';

  /// In-memory cache so every request doesn't hit SharedPreferences.
  static String? cachedToken;
  static String? cachedRole;

  /// Call once at app startup to restore persisted session.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    cachedToken = prefs.getString(_kToken);
    cachedRole = prefs.getString(_kRole);
  }

  static bool get isAuthenticated => cachedToken != null;

  static bool get isPremiumUser =>
      ['paid', 'expert', 'superadmin'].contains(cachedRole);

  static String get role => cachedRole ?? 'guest';

  // ── Auth ────────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> login(
    String username,
    String password,
  ) async {
    final data = await ApiClient.post(
      kLoginUrl,
      {'username': username, 'password': password},
      withAuth: false,
    );
    await _saveAuth(data['token'] as String, data['role'] as String);
    return {'token': data['token'] as String, 'role': data['role'] as String};
  }

  static Future<Map<String, String>> register({
    required String username,
    required String email,
    String? phone,
    required String password,
    required String confirmPassword,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    };
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();

    final data = await ApiClient.post(kRegisterUrl, body, withAuth: false);
    await _saveAuth(data['token'] as String, data['role'] as String);
    return {'token': data['token'] as String, 'role': data['role'] as String};
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post(kLogoutUrl, {});
    } catch (_) {}
    await _clearAuth();
  }

  static Future<UserProfile> getProfile() async {
    final data = await ApiClient.get(kProfileUrl);
    return UserProfile.fromJson(data);
  }

  /// Fetches the latest profile and persists the latest server-side role locally.
  /// This is important after subscription payment, when backend upgrades role
  /// from `guest` to `paid` asynchronously (IPN/success callback).
  static Future<UserProfile> refreshProfileAndRole() async {
    final profile = await getProfile();
    cachedRole = profile.role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, profile.role);
    return profile;
  }

  static Future<UserProfile> updateProfile({
    required String username,
    required String email,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
    };
    if (phone != null) body['phone'] = phone;

    final data = await ApiClient.patch(kProfileUrl, body);
    return UserProfile.fromJson(data);
  }

  // ── Guest ID ────────────────────────────────────────────────────────────────

  /// Returns a persistent UUID v4 for unauthenticated guest scanning.
  static Future<String> getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_kGuestId);
    if (id == null) {
      id = _generateUuid();
      await prefs.setString(_kGuestId, id);
    }
    return id;
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  static Future<void> _saveAuth(String token, String role) async {
    cachedToken = token;
    cachedRole = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kRole, role);
  }

  static Future<void> _clearAuth() async {
    cachedToken = null;
    cachedRole = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
  }

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    return [
      bytes.sublist(0, 4).map(hex).join(),
      bytes.sublist(4, 6).map(hex).join(),
      bytes.sublist(6, 8).map(hex).join(),
      bytes.sublist(8, 10).map(hex).join(),
      bytes.sublist(10, 16).map(hex).join(),
    ].join('-');
  }
}
