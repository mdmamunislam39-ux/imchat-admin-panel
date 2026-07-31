import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthDebug {
  static void printAuthState() {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      debugPrint('🔍 Auth State Debug:');
      debugPrint('👤 Current User: ${user?.uid}');
      debugPrint('📧 User Email: ${user?.email}');
      debugPrint('✅ Email Verified: ${user?.emailVerified}');
      debugPrint('🔐 Auth Domain: ${auth.app.options.authDomain}');
      debugPrint('🏗️ Project ID: ${auth.app.options.projectId}');
      debugPrint('🌐 Current URL: ${Uri.base}');
      debugPrint('🌐 Current Host: ${Uri.base.host}');
      debugPrint('🌐 Current Origin: ${Uri.base.origin}');
      
      // Check if we're in production
      final isProduction = !Uri.base.host.contains('localhost') && 
                          !Uri.base.host.contains('127.0.0.1');
      debugPrint('🚀 Production Mode: $isProduction');
      
    } catch (e) {
      debugPrint('❌ Auth Debug Error: $e');
    }
  }
  
  static void printSignInAttempt(String email) {
    debugPrint('🔐 Sign In Attempt Debug:');
    debugPrint('📧 Email: $email');
    debugPrint('🌐 Domain: ${Uri.base.host}');
    debugPrint('🔑 Auth Domain: ${FirebaseAuth.instance.app.options.authDomain}');
    debugPrint('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
  }
  
  static void printSignInResult(User? user, String? error) {
    debugPrint('📊 Sign In Result Debug:');
    debugPrint('👤 User: ${user?.uid}');
    debugPrint('📧 Email: ${user?.email}');
    debugPrint('✅ Email Verified: ${user?.emailVerified}');
    debugPrint('❌ Error: $error');
    debugPrint('🔐 Auth State: ${FirebaseAuth.instance.currentUser?.uid}');
  }
}
