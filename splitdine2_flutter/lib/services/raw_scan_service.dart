import 'dart:convert';
import 'api_service.dart';

class RawScanService extends ApiService {
  static const String _basePath = '/api/raw_scan';

  /// Save raw scan text from Vision API
  /// [sessionId] - The session ID
  /// [scanText] - Raw OCR text from Vision API
  /// [replace] - Whether to replace existing scan or add to it
  Future<Map<String, dynamic>> saveRawScan({
    required String sessionId,
    required String scanText,
    bool replace = false,
  }) async {
    try {
      final response = await post(
        '$_basePath/save',
        body: {
          'session_id': sessionId,
          'scan_text': scanText,
          'replace': replace,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all raw scans for a session
  /// [sessionId] - The session ID to fetch scans for
  Future<List<Map<String, dynamic>>> getRawScans(String sessionId) async {
    try {
      final response = await get('$_basePath/$sessionId');
      
      if (response['return_code'] == 200 && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Delete all raw scans for a session
  /// [sessionId] - The session ID to delete scans for
  Future<Map<String, dynamic>> deleteRawScans(String sessionId) async {
    try {
      final response = await delete('$_basePath/$sessionId');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get combined raw scan text for a session
  /// Helper method to get all raw scans and combine their text
  Future<String> getCombinedRawScanText(String sessionId) async {
    try {
      final rawScans = await getRawScans(sessionId);
      
      if (rawScans.isEmpty) {
        return '';
      }
      
      // Combine all scan texts with newlines between them
      return rawScans
          .map((scan) => scan['scan_text'] ?? '')
          .where((text) => text.isNotEmpty)
          .join('\n\n');
    } catch (e) {
      print('Error getting combined raw scan text: $e');
      return '';
    }
  }
}