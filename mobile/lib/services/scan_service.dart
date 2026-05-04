import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/history_item.dart';
import '../models/scan_result.dart';
import 'api_client.dart';
import 'auth_service.dart';

class ScanService {

  static Future<ScanResult> submitScan({
    required Uint8List imageBytes,
    required String crop,
  }) async {
    final fields = <String, String>{'crop': crop};

    if (!AuthService.isAuthenticated) {
      final guestId = await AuthService.getOrCreateGuestId();
      fields['guest_id'] = guestId;
    }

    final file = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'leaf_scan.jpg',
    );

    final data = await ApiClient.multipartPost(
      kScanUrl,
      fields: fields,
      files: [file],
      withAuth: AuthService.isAuthenticated,
      allowStatusCodes: {422},
    );

    return ScanResult.fromJson(data);
  }

  /// Fetches scan history from GET /api/scan/history/.
  /// Note: backend currently requires authenticated (premium) access.
  static Future<List<HistoryItem>> fetchHistory() async {
    final data = await ApiClient.get(kScanHistoryUrl);
    final raw = data['history'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => _historyItemFromApi(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static HistoryItem _historyItemFromApi(Map<String, dynamic> json) {
    final String diseaseName = (json['disease_name'] as String?) ?? 'Unknown';
    final String crop = (json['crop'] as String?) ?? '';
    final double confidence =
        ((json['confidence'] as num?) ?? 0).toDouble();
    final Map<String, dynamic>? solution =
        (json['solution'] is Map) ? (json['solution'] as Map).cast<String, dynamic>() : null;

    final String createdAtRaw = (json['created_at'] as String?) ?? '';
    final String createdAt = _formatCreatedAt(createdAtRaw);

    final String title = diseaseName.isNotEmpty ? diseaseName : 'Unknown';
    final String icon =
        crop.isNotEmpty ? crop.trim().characters.first.toUpperCase() : 'T';

    Color color;
    final lower = title.toLowerCase();
    if (lower.contains('not a plant')) {
      color = Colors.orange;
    } else if (lower.contains('healthy')) {
      color = Colors.green;
    } else if (confidence >= 80) {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    final String? imageUrl = _absoluteUrl((json['image'] as String?) ?? '');

    final actions = <RecommendationAction>[];
    if (solution != null) {
      final organic = (solution['organic'] as String?) ??
          (solution['organic_solution'] as String?) ??
          '';
      final chemical = (solution['chemical'] as String?) ??
          (solution['chemical_solution'] as String?) ??
          '';
      final tips = (solution['tips'] as String?) ??
          (solution['prevention_tips'] as String?) ??
          '';

      if (organic.trim().isNotEmpty) {
        actions.add(RecommendationAction(
          icon: Icons.eco_outlined,
          title: 'Organic Treatment',
          description: organic.trim(),
        ));
      }
      if (chemical.trim().isNotEmpty) {
        actions.add(RecommendationAction(
          icon: Icons.science_outlined,
          title: 'Chemical Treatment',
          description: chemical.trim(),
        ));
      }
      if (tips.trim().isNotEmpty) {
        actions.add(RecommendationAction(
          icon: Icons.shield_outlined,
          title: 'Prevention Tips',
          description: tips.trim(),
        ));
      }
    }

    return HistoryItem(
      title: title,
      time: createdAt,
      icon: icon,
      statusColor: color,
      cropName: crop,
      matchPercentage: '${confidence.toStringAsFixed(2)}%',
      imageUrl: imageUrl,
      actions: actions,
    );
  }

  static String? _absoluteUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    final base = kBaseUrl.trim();
    if (base.isEmpty) return p;

    final baseNoSlash = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final pathNoSlash = p.startsWith('/') ? p : '/$p';
    return '$baseNoSlash$pathNoSlash';
  }

  static String _formatCreatedAt(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      String two(int v) => v < 10 ? '0$v' : '$v';
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return iso;
    }
  }
}
