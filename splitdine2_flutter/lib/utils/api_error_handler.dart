import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../screens/login_screen.dart';

class ApiErrorHandler {
  /// Handles API responses and checks for authentication errors
  /// Returns true if the response should be processed normally
  /// Returns false if an authentication error was handled
  static Future<bool> handleResponse(
    BuildContext context,
    http.Response response, {
    bool showErrorDialog = true,
  }) async {
    // Parse response body
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      if (showErrorDialog) {
        _showErrorDialog(context, 'Invalid server response');
      }
      return false;
    }

    // Check for authentication errors
    if (response.statusCode == 401) {
      final returnCode = data['return_code'];
      
      if (returnCode == 'INVALID_TOKEN' || 
          returnCode == 'TOKEN_EXPIRED' || 
          returnCode == 'MISSING_TOKEN') {
        
        // Clear authentication and navigate to login
        await _handleAuthenticationError(context);
        return false;
      }
    }

    // Check for other error responses
    if (data['return_code'] != 'SUCCESS' && showErrorDialog) {
      _showErrorDialog(context, data['message'] ?? 'An error occurred');
      return false;
    }

    return true;
  }

  /// Handles authentication errors by logging out and navigating to login
  static Future<void> _handleAuthenticationError(BuildContext context) async {
    if (!context.mounted) return;

    // Clear authentication state
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    // Navigate to login screen and clear navigation stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          backgroundColor: Color(0xFFF04438), // Tomato Red
        ),
      );
    }
  }

  /// Shows an error dialog to the user
  static void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(
            fontFamily: 'GoogleSans',
            fontWeight: FontWeight.bold,
            color: Color(0xFF4E4B47),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            color: Color(0xFF4E4B47),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFC629), // Sunshine Yellow
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Utility method to check if a response indicates an authentication error
  static bool isAuthenticationError(http.Response response) {
    if (response.statusCode != 401) return false;

    try {
      final data = jsonDecode(response.body);
      final returnCode = data['return_code'];

      return returnCode == 'INVALID_TOKEN' ||
             returnCode == 'TOKEN_EXPIRED' ||
             returnCode == 'MISSING_TOKEN';
    } catch (e) {
      return false;
    }
  }

  /// Simple method to check if response is successful or handle auth errors
  /// Returns null if authentication error (token invalid), otherwise returns the response data
  static Map<String, dynamic>? checkResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      // Check for authentication errors - return null to indicate auth failure
      if (response.statusCode == 401) {
        final returnCode = data['return_code'];
        if (returnCode == 'INVALID_TOKEN' ||
            returnCode == 'TOKEN_EXPIRED' ||
            returnCode == 'MISSING_TOKEN') {
          return null; // Indicates authentication error
        }
      }

      return data;
    } catch (e) {
      return {'return_code': 'ERROR', 'message': 'Invalid server response'};
    }
  }
}
