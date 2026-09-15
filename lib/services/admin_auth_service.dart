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
  static String? _currentUserName;
  static String? _currentUserRole; // 'main_admin' or 'sub_official_admin' or 'master_admin'
  static List<String> _currentPermissions = [];
  static Map<String, String> _permissionsMap = {}; // module -> 'edit' | 'view'

  static bool get isAuthenticated => _isAuthenticated;
  static String? get currentUserId => _currentUserId;
  static String? get currentUserEmail => _currentUserEmail;
  static String? get currentUserName => _currentUserName;
  static String? get currentUserRole => _currentUserRole;
  static List<String> get currentPermissions => _currentPermissions;
  static Map<String, String> get permissionsMap => _permissionsMap;

  static bool isMainAdmin() => _currentUserRole == 'main_admin';

  static bool hasPermission(String module) {
    if (isMainAdmin()) return true;
    if (_permissionsMap.containsKey(module)) {
      final level = _permissionsMap[module];
      return level == 'edit' || level == 'view';
    }
    return _currentPermissions.contains(module);
  }

  static bool canEdit(String module) {
    if (isMainAdmin()) return true;
    if (_permissionsMap.containsKey(module)) {
      return _permissionsMap[module] == 'edit';
    }
    return _currentPermissions.contains(module); // fallback
  }

  static bool canView(String module) {
    if (isMainAdmin()) return true;
    if (_permissionsMap.containsKey(module)) {
      final level = _permissionsMap[module];
      return level == 'view' || level == 'edit';
    }
    return _currentPermissions.contains(module);
  }

  static String getPermissionLevel(String module) {
    if (isMainAdmin()) return 'edit';
    return _permissionsMap[module] ?? (_currentPermissions.contains(module) ? 'edit' : 'none');
  }

  static void _parsePermissions(dynamic permsData) {
    _currentPermissions = [];
    _permissionsMap = {};
    if (permsData is Map) {
      permsData.forEach((key, value) {
        final k = key.toString();
        if (value == true || value == 'edit') {
          _permissionsMap[k] = 'edit';
          _currentPermissions.add(k);
        } else if (value == 'view') {
          _permissionsMap[k] = 'view';
          _currentPermissions.add(k);
        }
      });
    } else if (permsData is List) {
      _currentPermissions = List<String>.from(permsData);
      for (var item in _currentPermissions) {
        _permissionsMap[item] = 'edit';
      }
    }
  }

  static Future<void> checkPersistedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('admin_uid');
      if (uid != null && uid.isNotEmpty) {
        final doc = await FirebaseFirestore.instance.collection(_collection).doc(uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['isActive'] == false) {
            await signOut();
            return;
          }
          _isAuthenticated = true;
          _currentUserId = doc.id;
          _currentUserEmail = data['email'];
          _currentUserName = data['name'] ?? data['fullname'] ?? (data['email'] != null ? (data['email'] as String).split('@').first : 'Admin');
          _currentUserRole = data['role'];
          _parsePermissions(data['permissions']);
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
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('password', isEqualTo: password.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();

        if (data['isActive'] == false) {
          throw Exception('This admin account has been deactivated. Please contact Super Admin.');
        }

        _isAuthenticated = true;
        _currentUserId = doc.id;
        _currentUserEmail = data['email'];
        _currentUserName = data['name'] ?? data['fullname'] ?? (data['email'] != null ? (data['email'] as String).split('@').first : 'Admin');
        _currentUserRole = data['role'];
        _parsePermissions(data['permissions']);

        // Update last login
        await FirebaseFirestore.instance.collection(_collection).doc(doc.id).update({
          'lastLogin': FieldValue.serverTimestamp(),
        }).catchError((_) {});

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_uid', doc.id);

        debugPrint('✅ Admin Auth: Login successful for $email as $_currentUserRole');
        return true;
      } else {
        // Fallback for first time setup
        if (email.trim().toLowerCase() == _defaultMainEmail && password.trim() == _defaultMainPassword) {
          debugPrint('⚠️ Admin Auth: Using default Main Admin credentials. Setting up DB...');
          final newDoc = await FirebaseFirestore.instance.collection(_collection).add({
            'name': 'Main Super Admin',
            'email': email.trim().toLowerCase(),
            'password': password.trim(),
            'role': 'main_admin',
            'isActive': true,
            'permissions': {},
            'createdAt': FieldValue.serverTimestamp(),
          });

          _isAuthenticated = true;
          _currentUserId = newDoc.id;
          _currentUserEmail = email.trim().toLowerCase();
          _currentUserName = 'Main Super Admin';
          _currentUserRole = 'main_admin';
          _currentPermissions = [];
          _permissionsMap = {};

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('admin_uid', newDoc.id);

          return true;
        }

        final checkEmail = await FirebaseFirestore.instance
            .collection(_collection)
            .where('email', isEqualTo: email.trim().toLowerCase())
            .limit(1)
            .get();

        if (checkEmail.docs.isNotEmpty) {
          throw Exception('Incorrect password. Please verify your credentials.');
        }

        throw Exception('Account not found with this email. Please check the email address or contact Super Admin.');
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
      _currentUserName = null;
      _currentUserRole = null;
      _currentPermissions = [];
      _permissionsMap = {};
      
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
        'name': _currentUserName ?? 'Admin',
        'email': _currentUserEmail ?? 'Unknown',
        'uid': _currentUserId ?? 'Unknown',
        'role': _currentUserRole ?? 'Unknown',
        'displayName': _currentUserRole == 'main_admin' ? 'Main Super Admin' : (_currentUserName ?? 'Sub Official Admin'),
      };
    }
    return {};
  }
}
