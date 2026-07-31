import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:imchat_adminpanel/services/simple_auth_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // The specific user ID that is allowed to access the admin panel (Root Admin)
  static const String _allowedUserId = 'umxTV509JJMQ9iQAQ7z1Tlfn4n32';

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is authenticated and authorized (checks if they are root or have an active super_admin document)
  static bool get isAuthenticated => SimpleAuthService.isUserAuthorized();

  // Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  static Future<bool?> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('🔐 Attempting sign in for: $email');
      
      // 1. Try hardcoded check first (for backward compatibility / quick test login)
      if (email == 'admin@imchat.com' && password == 'test1234') {
        final success = await SimpleAuthService.signInWithEmailAndPassword(email, password);
        if (success == true) {
          try {
            // Also sign in the Firebase Auth root admin user if credentials exist in Firebase
            await _auth.signInWithEmailAndPassword(email: email, password: password);
          } catch (_) {
            // Ignore if actual root account is not in Firebase Auth, we still allow local simulation login
          }
        }
        return success;
      }

      // 2. Otherwise, authenticate via actual Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Check if this user is a super admin in Firestore
        bool isSuperAdmin = user.uid == _allowedUserId;
        if (!isSuperAdmin) {
          final adminDoc = await FirebaseFirestore.instance
              .collection('super_admins')
              .where('userId', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (adminDoc.docs.isNotEmpty) {
            final data = adminDoc.docs.first.data();
            isSuperAdmin = data['isActive'] ?? true;
          }
        }

        if (isSuperAdmin) {
          // Authorized! Set simple auth service properties to match
          SimpleAuthService.setAuthenticatedUser(
            userId: user.uid,
            email: email,
          );
          return true;
        }
      }
      
      // Not authorized or user is null
      await _auth.signOut();
      return false;
    } catch (e) {
      debugPrint('💥 Auth Error: $e');
      throw 'Authentication failed: ${e.toString()}';
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await SimpleAuthService.signOut();
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Check if current user is authorized (for use in widgets)
  static bool isUserAuthorized() {
    return SimpleAuthService.isUserAuthorized();
  }

  // Get user info for display
  static Map<String, String> getUserInfo() {
    return SimpleAuthService.getUserInfo();
  }
}
