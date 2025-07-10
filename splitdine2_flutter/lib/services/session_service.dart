import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session.dart';
import '../models/receipt_item.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a random 6-digit join code
  String _generateJoinCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Get user display name
  String _getUserDisplayName(User user) {
    if (user.isAnonymous) return 'Guest';
    // Prioritize displayName over email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email?.split('@').first ?? 'User';
  }

  // Create a new session
  Future<Session?> createSession({String? restaurantName}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final sessionId = _firestore.collection('sessions').doc().id;
      final joinCode = _generateJoinCode();
      final now = DateTime.now();

      final session = Session(
        id: sessionId,
        organizerId: user.uid,
        joinCode: joinCode,
        status: SessionStatus.active,
        createdAt: now,
        updatedAt: now,
        restaurantName: restaurantName,
        participants: {
          user.uid: Participant(
            name: _getUserDisplayName(user),
            joinedAt: now,
            role: 'organizer',
            confirmed: true,
          ),
        },
      );

      await _firestore.collection('sessions').doc(sessionId).set(session.toMap());
      return session;
    } catch (e) {
      print('Error creating session: $e');
      return null;
    }
  }

  // Join a session by join code
  Future<Session?> joinSession(String joinCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Find session by join code
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('joinCode', isEqualTo: joinCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // Session not found
      }

      final sessionDoc = querySnapshot.docs.first;
      final session = Session.fromMap(sessionDoc.data(), sessionDoc.id);

      // Check if user is already a participant
      if (session.participants.containsKey(user.uid)) {
        return session; // Already joined
      }

      // Add user as participant
      final participant = Participant(
        name: _getUserDisplayName(user),
        joinedAt: DateTime.now(),
        role: 'participant',
        confirmed: false,
      );

      await _firestore.collection('sessions').doc(session.id).update({
        'participants.${user.uid}': participant.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return session.copyWith(
        participants: {...session.participants, user.uid: participant},
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error joining session: $e');
      return null;
    }
  }

  // Get session by ID
  Future<Session?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();
      if (doc.exists) {
        return Session.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // Stream session updates
  Stream<Session?> sessionStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return Session.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Update session
  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('sessions').doc(sessionId).update(updates);
    } catch (e) {
      print('Error updating session: $e');
    }
  }

  // Update receipt data
  Future<void> updateReceiptData(String sessionId, ReceiptData receiptData) async {
    try {
      await updateSession(sessionId, {
        'receiptData': receiptData.toMap(),
      });
    } catch (e) {
      print('Error updating receipt data: $e');
    }
  }

  // Assign item to participants
  Future<void> assignItem(String sessionId, String itemId, List<String> userIds, {String splitType = 'equal'}) async {
    try {
      final assignment = ItemAssignment(
        assignedTo: userIds,
        splitType: splitType,
      );

      await updateSession(sessionId, {
        'assignments.$itemId': assignment.toMap(),
      });
    } catch (e) {
      print('Error assigning item: $e');
    }
  }

  // Confirm participant
  Future<void> confirmParticipant(String sessionId, String userId) async {
    try {
      await updateSession(sessionId, {
        'participants.$userId.confirmed': true,
      });
    } catch (e) {
      print('Error confirming participant: $e');
    }
  }

  // Complete session
  Future<void> completeSession(String sessionId) async {
    try {
      await updateSession(sessionId, {
        'status': 'completed',
      });
    } catch (e) {
      print('Error completing session: $e');
    }
  }

  // Cancel session
  Future<void> cancelSession(String sessionId) async {
    try {
      await updateSession(sessionId, {
        'status': 'cancelled',
      });
    } catch (e) {
      print('Error cancelling session: $e');
    }
  }

  // Get user's sessions
  Stream<List<Session>> getUserSessions(String userId) {
    return _firestore
        .collection('sessions')
        .where('participants.$userId', isNotEqualTo: null)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Session.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Leave session
  Future<void> leaveSession(String sessionId, String userId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'participants.$userId': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error leaving session: $e');
    }
  }

  // Update final split
  Future<void> updateFinalSplit(String sessionId, String userId, FinalSplit finalSplit) async {
    try {
      await updateSession(sessionId, {
        'finalSplit.$userId': finalSplit.toMap(),
      });
    } catch (e) {
      print('Error updating final split: $e');
    }
  }

  // Calculate split amounts for a session
  Future<Map<String, double>> calculateSplitAmounts(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) return {};

      final items = await getReceiptItems(sessionId);
      final splitAmounts = <String, double>{};

      // Initialize amounts for all participants
      for (final userId in session.participants.keys) {
        splitAmounts[userId] = 0.0;
      }

      // Calculate item splits
      for (final item in items) {
        final assignment = session.assignments[item.id];
        if (assignment != null && assignment.assignedTo.isNotEmpty) {
          final splitAmount = item.totalPrice / assignment.assignedTo.length;
          for (final userId in assignment.assignedTo) {
            splitAmounts[userId] = (splitAmounts[userId] ?? 0.0) + splitAmount;
          }
        }
      }

      // Add tax, tip, and service charges proportionally
      final totalItemAmount = items.fold(0.0, (total, item) => total + item.totalPrice);
      if (totalItemAmount > 0) {
        final totalExtras = session.receiptData.tax +
                           session.receiptData.tip +
                           session.receiptData.serviceCharge;

        for (final userId in splitAmounts.keys) {
          final userItemAmount = splitAmounts[userId] ?? 0.0;
          final proportion = userItemAmount / totalItemAmount;
          splitAmounts[userId] = userItemAmount + (totalExtras * proportion);
        }
      }

      return splitAmounts;
    } catch (e) {
      print('Error calculating split amounts: $e');
      return {};
    }
  }

  // Get receipt items for a session
  Future<List<ReceiptItem>> getReceiptItems(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection('receiptItems')
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt')
          .get();

      return querySnapshot.docs
          .map((doc) => ReceiptItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting receipt items: $e');
      return [];
    }
  }
}
