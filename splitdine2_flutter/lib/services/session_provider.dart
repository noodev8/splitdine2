import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/participant.dart';
import 'session_service.dart';

class SessionProvider with ChangeNotifier {
  final SessionService _sessionService = SessionService();
  
  List<Session> _sessions = [];
  List<Participant> _participants = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _requiredAppVersion;

  List<Session> get sessions => _sessions;
  List<Participant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get requiredAppVersion => _requiredAppVersion;

  // Get upcoming sessions (date >= today)
  List<Session> get upcomingSessions {
    return _sessions.where((session) => session.isUpcoming).toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));
  }

  // Get past sessions (date < today)
  List<Session> get pastSessions {
    return _sessions.where((session) => !session.isUpcoming).toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate)); // Most recent first
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load user's sessions
  Future<void> loadSessions() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.getMySessions();
      
      if (result['success']) {
        _sessions = result['sessions'] as List<Session>;
        _requiredAppVersion = result['required_version'];
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load sessions: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new session
  Future<bool> createSession({
    String? sessionName,
    required String location,
    required DateTime sessionDate,
    String? sessionTime,
    String? description,
    String? foodType,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.createSession(
        sessionName: sessionName,
        location: location,
        sessionDate: sessionDate,
        sessionTime: sessionTime,
        description: description,
        foodType: foodType,
      );

      if (result['success']) {
        final newSession = result['session'] as Session;
        _sessions.add(newSession);
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to create session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Join session by code
  Future<bool> joinSession(String sessionCode) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.joinSession(sessionCode);

      if (result['success']) {
        final session = result['session'] as Session;
        
        // Check if session already exists in our list
        final existingIndex = _sessions.indexWhere((s) => s.id == session.id);
        if (existingIndex >= 0) {
          _sessions[existingIndex] = session;
        } else {
          _sessions.add(session);
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to join session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get session by ID
  Session? getSessionById(int sessionId) {
    try {
      return _sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  // Refresh sessions
  Future<void> refreshSessions() async {
    await loadSessions();
  }

  // Clear sessions (for logout)
  void clearSessions() {
    _sessions.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // Update session in local list
  void updateSession(Session updatedSession) {
    final index = _sessions.indexWhere((session) => session.id == updatedSession.id);
    if (index >= 0) {
      _sessions[index] = updatedSession;
      notifyListeners();
    }
  }

  // Alias for updateSession for clarity
  void updateCurrentSession(Session updatedSession) {
    updateSession(updatedSession);
  }

  // Remove session from local list
  void removeSession(int sessionId) {
    _sessions.removeWhere((session) => session.id == sessionId);
    notifyListeners();
  }

  // Leave session
  Future<bool> leaveSession(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.leaveSession(sessionId);

      if (result['success']) {
        // Remove session from local list
        removeSession(sessionId);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to leave session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove participant from session (organizer only)
  Future<bool> removeParticipant(int sessionId, int userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.removeParticipant(sessionId, userId);

      if (result['success']) {
        // Optionally refresh sessions to get updated participant list
        await refreshSessions();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to remove participant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Transfer host privileges to another participant
  Future<bool> transferHost(int sessionId, int newHostUserId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.transferHost(sessionId, newHostUserId);

      if (result['success']) {
        // Refresh sessions to get updated host status
        await refreshSessions();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to transfer host privileges: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete/cancel session (host only)
  Future<bool> deleteSession(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.deleteSession(sessionId);

      if (result['success']) {
        // Remove session from local list
        removeSession(sessionId);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load participants for a session
  Future<void> loadParticipants(int sessionId) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.getSessionParticipants(sessionId);

      if (result['success']) {
        _participants = result['participants'] as List<Participant>;
        notifyListeners();
      } else {
        _setError(result['message']);
      }
    } catch (e) {
      _setError('Failed to load participants: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update session bill totals
  Future<({bool success, String? errorMessage})> updateSessionBillTotals({
    required int sessionId,
    required double itemAmount,
    required double taxAmount,
    required double serviceCharge,
    required double extraCharge,
    required double totalAmount,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await _sessionService.updateBillTotals(
        sessionId: sessionId,
        itemAmount: itemAmount,
        taxAmount: taxAmount,
        serviceCharge: serviceCharge,
        extraCharge: extraCharge,
        totalAmount: totalAmount,
      );

      if (result['success']) {
        final updatedSession = result['session'] as Session;
        updateSession(updatedSession);
        return (success: true, errorMessage: null);
      } else {
        _setError(result['message']);
        return (success: false, errorMessage: result['message'] as String?);
      }
    } catch (e) {
      final errorMsg = 'Failed to update bill totals: $e';
      _setError(errorMsg);
      return (success: false, errorMessage: errorMsg);
    } finally {
      _setLoading(false);
    }
  }
}
