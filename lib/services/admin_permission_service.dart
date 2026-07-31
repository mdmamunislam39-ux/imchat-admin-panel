import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_permission_model.dart';

class AdminPermissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'super_admins';
  static const String _usersCollection = 'Users';

  // Available Modules
  static const List<String> availableModules = [
    'Users Management',
    'User Profiles',
    'Hosts & Agencies',
    'Blocked Users',
    'Family Management',
    'Banner Management',
    'Event Management',
    'Official Channels',
    'Market Management',
    'Gifts Management',
    'Emojis Management',
    'Level System',
    'User History & Stats',
    'SVIP Management',
    'Agency Management',
    'Seller Management',
    'Commission Management',
    'Official Items',
    'Gift Economy',
    'Withdrawal Management',
    'Diamonds Management',
    'Daily Check-in',
    'Reports & Analytics',
    'Game Management',
    'Rooms Management',
    'Custom Room IDs',
    'Settings',
  ];

  // Get stream of all super admins
  static Stream<List<AdminPermissionModel>> getSuperAdminsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AdminPermissionModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get specific user permissions
  static Future<AdminPermissionModel?> getAdminPermissions(
    String userId,
  ) async {
    // If it's the root/master admin, return full permissions
    if (userId == 'umxTV509JJMQ9iQAQ7z1Tlfn4n32') {
      // In a real app, you would check if they are the hardcoded root admin.
      final allPerms = {for (var m in availableModules) m: true};
      return AdminPermissionModel(
        id: 'root',
        userId: userId,
        userName: 'Root Admin',
        userImageUrl: '',
        permissions: allPerms,
        assignedAt: DateTime.now(),
      );
    }

    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return AdminPermissionModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting admin permissions: $e');
      return null;
    }
  }

  // Get stream of specific user permissions
  static Stream<AdminPermissionModel?> getAdminPermissionsStream(
    String userId,
  ) {
    if (userId == 'umxTV509JJMQ9iQAQ7z1Tlfn4n32') {
      final allPerms = {for (var m in availableModules) m: true};
      return Stream.value(
        AdminPermissionModel(
          id: 'root',
          userId: userId,
          userName: 'Root Admin',
          userImageUrl: '',
          permissions: allPerms,
          assignedAt: DateTime.now(),
        ),
      );
    }

    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return AdminPermissionModel.fromFirestore(snapshot.docs.first);
          }
          return null;
        });
  }

  // Search user by profile ID (searchId)
  static Future<Map<String, dynamic>?> searchUserByProfileId(
    String profileId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('searchId', isEqualTo: profileId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullname'] ?? 'Unknown',
          'profileId': data['searchId'] ?? '',
          'imageUrl': data['profileImage'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Assign or Update Super Admin
  static Future<void> assignOrUpdateAdmin(AdminPermissionModel admin) async {
    try {
      if (admin.id.isEmpty) {
        // Create new
        await _firestore.collection(_collectionName).add(admin.toFirestore());
      } else {
        // Update existing
        await _firestore
            .collection(_collectionName)
            .doc(admin.id)
            .update(admin.toFirestore());
      }

      // Update User profile to grant/revoke admin access instantly
      await _firestore.collection(_usersCollection).doc(admin.userId).update({
        'userType': admin.isActive ? 'admin' : 'regular',
      });
    } catch (e) {
      debugPrint('Error saving admin: $e');
      rethrow;
    }
  }

  // Delete Super Admin
  static Future<void> deleteAdmin(String docId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (doc.exists) {
        final userId = doc.data()?['userId'];
        if (userId != null) {
          await _firestore.collection(_usersCollection).doc(userId).update({
            'userType': 'regular',
          });
        }
      }
      await _firestore.collection(_collectionName).doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting admin: $e');
      rethrow;
    }
  }

  // Toggle Admin Status
  static Future<void> toggleAdminStatus(String docId, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(docId).update({
        'isActive': isActive,
      });

      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (doc.exists) {
        final userId = doc.data()?['userId'];
        if (userId != null) {
          await _firestore.collection(_usersCollection).doc(userId).update({
            'userType': isActive ? 'admin' : 'regular',
          });
        }
      }
    } catch (e) {
      debugPrint('Error toggling admin status: $e');
      rethrow;
    }
  }
}
