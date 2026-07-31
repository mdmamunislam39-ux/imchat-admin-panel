import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  static const String _collection = 'web_admins';
  static const String _defaultMainEmail = 'admin@imchat.com';
  static const String _defaultMainPassword = 'test1234';

  static bool _isAuthenticated = false;
  static String? _currentUserId;
  static String? _currentUserEmail;
  static String? _currentUserRole; // 'main_admin' or 'master_admin'
  static List<String> _currentPermissions = [];

  static bool get isAuthenticated => _isAuthenticated;
  static String? get currentUserId => _currentUserId;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUserRole => _currentUserRole;
  static List<String> get currentPermissions => _currentPermissions;

  static bool isMainAdmin() => _currentUserRole == 'main_admin';

  static bool hasPermission(String module) {
    if (isMainAdmin()) return true;
    return _currentPermissions.contains(module);
  }

  static Future<void> checkPersistedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('admin_uid');
      if (uid != null && uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection(_collection).doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _isAuthenticated = true;
          _currentUserId = doc.id;
          _currentUserEmail = data['email'];
          _currentUserRole = data['role'];
          _currentPermissions = List<String>.from(data['permissions'] ?? []);
          debugPrint('✅ Admin Auth: Restored session for $_currentUserEmail');
        } else {
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('💥 Error checking persisted login: $e');
    }
  }

  static Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('🔐 Admin Auth: Attempting sign in for: $email');
      
      final query = await FirebaseFirestore.instance
          .collection(_collection)
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();

        _isAuthenticated = true;
        _currentUserId = doc.id;
        _currentUserEmail = data['email'];
        _currentUserRole = data['role'];
        _currentPermissions = List<String>.from(data['permissions'] ?? []);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_uid', doc.id);

        debugPrint('✅ Admin Auth: Login successful for $email as $_currentUserRole');
        return true;
      } else {
        // Fallback for first time setup
        if (email == _defaultMainEmail && password == _defaultMainPassword) {
          debugPrint('⚠️ Admin Auth: Using default Main Admin credentials. Setting up DB...');
          final newDoc = await FirebaseFirestore.instance.collection(_collection).add({
            'email': email,
            'password': password,
            'role': 'main_admin',
            'permissions': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          _isAuthenticated = true;
          _currentUserId = newDoc.id;
          _currentUserEmail = email;
          _currentUserRole = 'main_admin';
          _currentPermissions = [];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('admin_uid', newDoc.id);

          return true;
        }

        final checkEmail = await FirebaseFirestore.instance
            .collection(_collection)
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (checkEmail.docs.isNotEmpty) {
          throw Exception('Password does not match for this email. (Or case sensitivity issue)');
        }

        throw Exception('Email not found in the database. Please use the exact correct email, or test1234 if it is your first time.');
      }
    } catch (e) {
      debugPrint('💥 Admin Auth Error: $e');
      throw Exception(e.toString());
    }
  }

  static Future<void> signOut() async {
    try {
      _isAuthenticated = false;
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserRole = null;
      _currentPermissions = [];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_uid');

      debugPrint('🚪 Admin Auth: User signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  static Map<String, String> getUserInfo() {
    if (_isAuthenticated && _currentUserId != null) {
      return {
        'email': _currentUserEmail ?? 'Unknown',
        'uid': _currentUserId ?? 'Unknown',
        'role': _currentUserRole ?? 'Unknown',
        'displayName': _currentUserRole == 'main_admin' ? 'Main Admin' : 'Master Admin',
      };
    }
    return {};
  }
}
