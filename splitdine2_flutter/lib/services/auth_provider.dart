import 'package:flutter/widgets.dart';
import 'package:splitdine2_flutter/models/user.dart';
import 'package:splitdine2_flutter/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  // Initialize authentication state
  Future<void> initializeAuth() async {
    _setLoading(true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        final userData = await _authService.getStoredUser();
        if (userData != null) {
          _user = User.fromJson(userData);
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication');
    }
    
    _setLoading(false);
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(email, password);
      
      if (result['success']) {
        _user = User.fromJson(result['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Register new user
  Future<bool> register(String email, String displayName, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.register(email, displayName, password);
      
      if (result['success']) {
        _user = User.fromJson(result['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Continue as guest
  Future<bool> continueAsGuest(String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.createAnonymousUser(displayName);
      
      if (result['success']) {
        _user = User.fromJson(result['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Guest login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _user = null;
      _clearError();
    } catch (e) {
      _setError('Logout failed: $e');
    }
    
    _setLoading(false);
  }

  // Update user profile
  Future<bool> updateProfile(String displayName) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.updateProfile(displayName);

      if (result['success']) {
        _user = User.fromJson(result['user']);
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Update profile failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.deleteAccount();

      if (result['success']) {
        _user = null;
        _setLoading(false);
        return true;
      } else {
        _setError(result['message']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Delete account failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Handle token invalidation (called when token is invalid)
  Future<void> handleTokenInvalidation() async {
    await logout();
    // The UI will automatically redirect to login when user becomes null
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _clearError() {
    _errorMessage = null;
    if (!_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
