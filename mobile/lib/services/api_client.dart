import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/constants/api_constants.dart';
import 'auth_service.dart';

/// Central HTTP client. All API calls go through here.
class ApiClient {
  static Uri _uri(String path) => Uri.parse('$kBaseUrl$path');

  static Map<String, String> _headers({
    bool withAuth = true,
    String? overrideToken,
  }) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    
    // Add global API Key if configured in AppConfig
    if (AppConfig.apiKey.isNotEmpty) {
      headers['X-API-Key'] = AppConfig.apiKey;
    }

    final token = overrideToken ?? AuthService.cachedToken;
    if (withAuth && token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    return _requestWithRetry(() => http.get(_uri(path), headers: _headers()));
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    return _requestWithRetry(() => http.post(
          _uri(path),
          headers: _headers(withAuth: withAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _requestWithRetry(() => http.patch(
          _uri(path),
          headers: _headers(),
          body: jsonEncode(body),
        ));
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    return _requestWithRetry(() => http.put(
          _uri(path),
          headers: _headers(withAuth: withAuth),
          body: jsonEncode(body),
        ));
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    return _requestWithRetry(() => http.delete(_uri(path), headers: _headers()));
  }

  static Future<Map<String, dynamic>> _requestWithRetry(
    Future<http.Response> Function() fn, {
    int maxRetries = 2,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        final res = await fn().timeout(const Duration(seconds: 30));
        return _parse(res);
      } catch (e) {
        if (attempts >= maxRetries + 1 || e is ApiException) rethrow;
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: attempts));
      }
    }
  }

  /// Sends a multipart/form-data POST (used for image uploads).
  static Future<Map<String, dynamic>> multipartPost(
    String path, {
    required Map<String, String> fields,
    required List<http.MultipartFile> files,
    bool withAuth = true,
    Set<int> allowStatusCodes = const {},
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
    
    // Add global API Key if configured in AppConfig
    if (AppConfig.apiKey.isNotEmpty) {
      req.headers['X-API-Key'] = AppConfig.apiKey;
    }

    final token = AuthService.cachedToken;
    if (withAuth && token != null) {
      req.headers['Authorization'] = 'Token $token';
    }
    req.fields.addAll(fields);
    req.files.addAll(files);

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);
    if (allowStatusCodes.contains(res.statusCode)) {
      final body = utf8.decode(res.bodyBytes);
      dynamic decoded;
      try {
        decoded = jsonDecode(body);
      } catch (_) {
        throw ApiException('Server returned an invalid response.', res.statusCode);
      }
      if (decoded is Map<String, dynamic>) return decoded;
      return {'_data': decoded};
    }
    return _parse(res);
  }

  static Map<String, dynamic> _parse(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw ApiException('Server returned an invalid response.', res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      return {'_data': decoded};
    }

    throw ApiException(_extractError(decoded), res.statusCode);
  }

  static String _extractError(dynamic decoded) {
    if (decoded is Map) {
      for (final key in ['error', 'detail', 'message', 'non_field_errors']) {
        if (decoded.containsKey(key)) {
          final v = decoded[key];
          if (v is List && v.isNotEmpty) return v.first.toString();
          return v.toString();
        }
      }
      // Validation field errors
      for (final entry in (decoded).entries) {
        final v = entry.value;
        if (v is List && v.isNotEmpty) return '${entry.key}: ${v.first}';
        if (v is String) return '${entry.key}: $v';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}
