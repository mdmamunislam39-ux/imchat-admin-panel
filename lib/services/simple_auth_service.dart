import 'package:flutter/foundation.dart';

class SimpleAuthService {
  // Hardcoded credentials
  static const String _hardcodedEmail = 'admin@imchat.com';
  static const String _hardcodedPassword = 'test1234';
  static const String _allowedUserId = 'umxTV509JJMQ9iQAQ7z1Tlfn4n32';
  
  // Simple in-memory auth state
  static bool _isAuthenticated = false;
  static String? _currentUserId;
  static String? _currentUserEmail;
  
  // Sign in with hardcoded credentials
  static Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('🔐 Simple Auth: Attempting sign in for: $email');
      
      // Add a small delay to simulate network request
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check hardcoded credentials
      if (email == _hardcodedEmail && password == _hardcodedPassword) {
        _isAuthenticated = true;
        _currentUserId = _allowedUserId;
        _currentUserEmail = email;
        
        debugPrint('✅ Simple Auth: Login successful for $email');
        return true;
      } else {
        debugPrint('❌ Simple Auth: Invalid credentials for $email');
        return false;
      }
    } catch (e) {
      debugPrint('💥 Simple Auth Error: $e');
      return false;
    }
  }
  
  // Sign out
  static Future<void> signOut() async {
    try {
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      debugPrint('🚪 Simple Auth: User signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
  
  // Check if user is authenticated
  static bool get isAuthenticated => _isAuthenticated;
  
  // Get current user ID
  static String? get currentUserId => _currentUserId;
  
  // Get current user email
  static String? get currentUserEmail => _currentUserEmail;
  
  // Check if current user is authorized
  static bool isUserAuthorized() {
    return _isAuthenticated && _currentUserId != null && _currentUserId!.isNotEmpty;
  }
  
  // Set authenticated user properties programmatically
  static void setAuthenticatedUser({required String userId, required String email}) {
    _isAuthenticated = true;
    _currentUserId = userId;
    _currentUserEmail = email;
  }

  // Get user info for display
  static Map<String, String> getUserInfo() {
    if (_isAuthenticated && _currentUserId != null) {
      return {
        'email': _currentUserEmail ?? 'Unknown',
        'uid': _currentUserId ?? 'Unknown',
        'displayName': _currentUserId == _allowedUserId ? 'Root Admin' : 'Admin User',
      };
    }
    return {};
  }
}
