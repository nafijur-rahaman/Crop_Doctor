import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
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
}
