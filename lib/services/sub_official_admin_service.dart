import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sub_official_admin_model.dart';
import 'admin_auth_service.dart';

class SubOfficialAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'web_admins';
  static const String _logsCollection = 'sub_admin_audit_logs';

  // Master list of all available modules in the IMChat Admin Panel
  static const List<Map<String, dynamic>> moduleCategories = [
    {
      'category': '👥 User & Community Management',
      'modules': [
        'Users Management',
        'User Profiles',
        'User Positions',
        'Hosts & Agencies',
        'Blocked Users',
        'Ban Management',
        'Room Ban Management',
        'Family Management',
        'Family Levels',
        'User History & Stats',
      ],
    },
    {
      'category': '💰 Economy, Gifts & Store',
      'modules': [
        'Diamonds Management',
        'Gifts Management',
        'Gift Transactions',
        'Official Items',
        'Official Store',
        'Store Management',
        'Market Management',
        'Emojis Management',
        'Daily Check-in',
        'Withdrawal Management',
        'Commission Management',
        'Seller Management',
      ],
    },
    {
      'category': '🎙️ Rooms, Levels & Agencies',
      'modules': [
        'Rooms Management',
        'Custom Room IDs',
        'Host Agency Management',
        'Agency Management',
        'VIP Management',
        'SVIP Management',
        'Level System',
        'Intimacy Levels',
        'Couple Levels',
      ],
    },
    {
      'category': '🎮 Games & Events',
      'modules': [
        'Game Management',
        'Game Profit Analysis',
        'Event Management',
        'Room Event Portal',
        'Grab the Top',
      ],
    },
    {
      'category': '📢 Content, Branding & System',
      'modules': [
        'Banner Management',
        'imChat Moment Management',
        'Official Channels',
        'Official Notifications',
        'Reports & Analytics',
        'Feedback Management',
        'Settings',
        'Invitation Referral Reward',
        'Website Landing',
      ],
    },
  ];

  static List<String> getAllModules() {
    List<String> all = [];
    for (var cat in moduleCategories) {
      all.addAll(List<String>.from(cat['modules'] ?? []));
    }
    return all;
  }

  // Stream of all sub official admins (excludes main_admin)
  static Stream<List<SubOfficialAdminModel>> getSubAdminsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SubOfficialAdminModel.fromFirestore(doc))
              .where((admin) => admin.role != 'main_admin')
              .toList();
        });
  }

  // Create a new Sub Official Admin
  static Future<void> createSubAdmin({
    required String name,
    required String email,
    required String password,
    String phone = '',
    required Map<String, String> permissions,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Email and Password cannot be empty.');
    }

    // Check if email already exists
    final check = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (check.docs.isNotEmpty) {
      throw Exception('An admin account with this email ($cleanEmail) already exists.');
    }

    final currentAdmin = AdminAuthService.getUserInfo();
    final createdBy = currentAdmin['displayName'] ?? currentAdmin['email'] ?? 'Super Admin';

    final newSubAdmin = SubOfficialAdminModel(
      id: '',
      name: name.trim().isEmpty ? cleanEmail.split('@').first : name.trim(),
      email: cleanEmail,
      password: cleanPassword,
      phone: phone.trim(),
      role: 'sub_official_admin',
      isActive: true,
      permissions: permissions,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );

    await _firestore.collection(_collection).add(newSubAdmin.toFirestore());

    // Log action
    await logAudit(
      action: 'Created Sub Official Admin',
      targetEmail: cleanEmail,
      targetName: newSubAdmin.name,
      details: 'Assigned ${newSubAdmin.totalAssignedModules} modules (${newSubAdmin.totalEditModules} Edit, ${newSubAdmin.totalViewModules} View).',
    );
  }

  // Update existing Sub Official Admin
  static Future<void> updateSubAdmin({
    required String id,
    required String name,
    required String email,
    required String password,
    String phone = '',
    required bool isActive,
    required Map<String, String> permissions,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      throw Exception('Email and Password cannot be empty.');
    }

    // Check if email is used by another doc
    final check = await _firestore
        .collection(_collection)
        .where('email', isEqualTo: cleanEmail)
        .get();

    for (var doc in check.docs) {
      if (doc.id != id) {
        throw Exception('Another admin is already using this email ($cleanEmail).');
      }
    }

    await _firestore.collection(_collection).doc(id).update({
      'name': name.trim().isEmpty ? cleanEmail.split('@').first : name.trim(),
      'email': cleanEmail,
      'password': cleanPassword,
      'phone': phone.trim(),
      'isActive': isActive,
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Log action
    await logAudit(
      action: 'Updated Sub Official Admin',
      targetEmail: cleanEmail,
      targetName: name,
      details: 'Updated credentials & permissions (Status: ${isActive ? 'Active' : 'Inactive'}).',
    );
  }

  // Toggle status (Active / Deactivated)
  static Future<void> toggleSubAdminStatus(String id, String email, String name, bool currentStatus) async {
    final newStatus = !currentStatus;
    await _firestore.collection(_collection).doc(id).update({
      'isActive': newStatus,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });

    await logAudit(
      action: newStatus ? 'Activated Sub Admin' : 'Deactivated Sub Admin',
      targetEmail: email,
      targetName: name,
      details: 'Status changed to ${newStatus ? 'Active ✅' : 'Deactivated ❌'}.',
    );
  }

  // Delete Sub Admin
  static Future<void> deleteSubAdmin(String id, String email, String name) async {
    await _firestore.collection(_collection).doc(id).delete();

    await logAudit(
      action: 'Deleted Sub Official Admin',
      targetEmail: email,
      targetName: name,
      details: 'Permanently removed sub admin account.',
    );
  }

  // Audit Logging
  static Future<void> logAudit({
    required String action,
    required String targetEmail,
    required String targetName,
    required String details,
  }) async {
    try {
      final currentAdmin = AdminAuthService.getUserInfo();
      await _firestore.collection(_logsCollection).add({
        'action': action,
        'performedBy': currentAdmin['displayName'] ?? currentAdmin['email'] ?? 'Super Admin',
        'performedByEmail': currentAdmin['email'] ?? '',
        'targetEmail': targetEmail,
        'targetName': targetName,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging audit: $e');
    }
  }
}
