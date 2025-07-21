import 'dart:convert';
import 'api_service.dart';

class RawScanService extends ApiService {
  static const String _basePath = '/api/raw_scan';

  /// Save OCR detections from Vision API
  /// [sessionId] - The session ID
  /// [detections] - List of individual OCR detections
  /// [replace] - Whether to replace existing scan or add to it
  Future<Map<String, dynamic>> saveRawScanDetections({
    required String sessionId,
    required List<Map<String, dynamic>> detections,
    bool replace = false,
  }) async {
    try {
      final response = await post(
        '$_basePath/save',
        body: {
          'session_id': sessionId,
          'detections': detections,
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
  /// Helper method to get all raw scan detections and combine their text
  Future<String> getCombinedRawScanText(String sessionId) async {
    try {
      final rawScans = await getRawScans(sessionId);
      
      if (rawScans.isEmpty) {
        return '';
      }
      
      // Combine all detection texts with spaces between them
      return rawScans
          .map((scan) => scan['detection_text'] ?? '')
          .where((text) => text.isNotEmpty)
          .join(' ');
    } catch (e) {
      print('Error getting combined raw scan text: $e');
      return '';
    }
  }
  
  /// Get raw scan detections with metadata for analysis
  /// Returns list of detections with text, confidence, and bounding box
  Future<List<Map<String, dynamic>>> getRawScanDetections(String sessionId) async {
    try {
      final rawScans = await getRawScans(sessionId);
      
      return rawScans.map((scan) => {
        'text': scan['detection_text'] ?? '',
        'confidence': scan['confidence'],
        'bounding_box': scan['bounding_box'],
        'created_at': scan['created_at'],
      }).toList();
    } catch (e) {
      print('Error getting raw scan detections: $e');
      return [];
    }
  }
}