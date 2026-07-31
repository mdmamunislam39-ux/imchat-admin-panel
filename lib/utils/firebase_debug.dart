import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseDebug {
  static void printConfiguration() {
    try {
      final app = Firebase.app();
      final options = app.options;
      
      debugPrint('🔧 Firebase Configuration Debug:');
      debugPrint('📱 Platform: ${defaultTargetPlatform.name}');
      debugPrint('🌐 Current URL: ${Uri.base}');
      debugPrint('🔑 API Key: ${options.apiKey}');
      debugPrint('🏗️ Project ID: ${options.projectId}');
      debugPrint('🔐 Auth Domain: ${options.authDomain}');
      debugPrint('💾 Storage Bucket: ${options.storageBucket}');
      debugPrint('📊 Messaging Sender ID: ${options.messagingSenderId}');
      debugPrint('📈 App ID: ${options.appId}');
      debugPrint('📊 Measurement ID: ${options.measurementId}');
      
      // Check if we're in web environment
      if (kIsWeb) {
        debugPrint('🌐 Web Environment Detected');
        debugPrint('🌐 Current Host: ${Uri.base.host}');
        debugPrint('🌐 Current Origin: ${Uri.base.origin}');
      }
      
    } catch (e) {
      debugPrint('❌ Error getting Firebase configuration: $e');
    }
  }
  
  static bool isConfigurationValid() {
    try {
      final app = Firebase.app();
      final options = app.options;
      
      // Check required fields
      if (options.apiKey.isEmpty) {
        debugPrint('❌ API Key is empty');
        return false;
      }
      
      if (options.projectId.isEmpty) {
        debugPrint('❌ Project ID is empty');
        return false;
      }
      
      if (options.authDomain?.isEmpty ?? true) {
        debugPrint('❌ Auth Domain is empty');
        return false;
      }
      
      debugPrint('✅ Firebase configuration appears valid');
      return true;
    } catch (e) {
      debugPrint('❌ Firebase configuration error: $e');
      return false;
    }
  }
}
