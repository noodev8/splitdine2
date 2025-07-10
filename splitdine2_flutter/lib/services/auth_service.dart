import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      
      // Create user document if it doesn't exist
      if (result.user != null) {
        await _createUserDocument(result.user!);
      }
      
      return result;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last active time
      if (result.user != null) {
        await _updateLastActiveTime(result.user!.uid);
      }
      
      return result;
    } catch (e) {
      print('Error signing in with email: $e');
      return null;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase Auth
      await result.user?.updateDisplayName(displayName);

      // Reload user to get updated display name
      await result.user?.reload();

      // Create user document with the provided display name
      if (result.user != null) {
        await _createUserDocument(result.user!, displayName: displayName);
      }

      return result;
    } catch (e) {
      debugPrint('Error registering with email: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Convert anonymous account to permanent account
  Future<UserCredential?> linkWithEmailAndPassword(
      String email, String password, String displayName) async {
    try {
      if (_auth.currentUser == null) return null;

      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      UserCredential result = await _auth.currentUser!.linkWithCredential(credential);

      // Update display name and user document
      await result.user?.updateDisplayName(displayName);
      if (result.user != null) {
        await _updateUserDocument(result.user!, displayName: displayName, email: email);
      }

      return result;
    } catch (e) {
      print('Error linking account: $e');
      return null;
    }
  }

  // Get user document
  Future<AppUser?> getUserDocument(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, {String? displayName}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        // Set appropriate display name for anonymous users
        String finalDisplayName;
        if (user.isAnonymous) {
          finalDisplayName = 'Guest';
          // Update the Firebase Auth display name too
          await user.updateDisplayName('Guest');
        } else {
          // For non-anonymous users, prioritize the provided displayName
          finalDisplayName = displayName ?? user.displayName ?? 'User';
          debugPrint('Creating user document with displayName: $finalDisplayName');
          debugPrint('User.displayName: ${user.displayName}');
          debugPrint('Provided displayName: $displayName');
        }

        final appUser = AppUser(
          id: user.uid,
          email: user.email,
          displayName: finalDisplayName,
          isAnonymous: user.isAnonymous,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );

        await userDoc.set(appUser.toMap());
        debugPrint('User document created successfully with name: $finalDisplayName');
      } else {
        debugPrint('User document already exists');
      }
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  // Update user document
  Future<void> _updateUserDocument(User user, {String? displayName, String? email}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      Map<String, dynamic> updateData = {
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      };

      if (displayName != null) {
        updateData['displayName'] = displayName;
        updateData['isAnonymous'] = false;
      }

      if (email != null) {
        updateData['email'] = email;
      }

      await userDoc.update(updateData);
    } catch (e) {
      print('Error updating user document: $e');
    }
  }

  // Update last active time
  Future<void> _updateLastActiveTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating last active time: $e');
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(String uid, UserPreferences preferences) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'preferences': preferences.toMap(),
      });
    } catch (e) {
      print('Error updating user preferences: $e');
    }
  }

  // Delete user account
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        
        // Delete Firebase Auth account
        await user.delete();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
