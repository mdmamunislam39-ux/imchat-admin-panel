import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_permission_model.dart';
import 'admin_auth_service.dart';
import 'simple_auth_service.dart';

class AdminPermissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'super_admins';
  static const String _usersCollection = 'Users';

  // Available Modules
  static const List<String> availableModules = [
    'Users Management',
    'User Profiles',
    'User Positions',
    'Hosts & Agencies',
    'Blocked Users',
    'Family Management',
    'imChat Moment Management',
    'Banner Management',
    'Event Management',
    'Official Channels',
    'Market Management',
    'Gifts Management',
    'Emojis Management',
    'Level System',
    'Intimacy Levels',
    'Couple Levels',
    'User History & Stats',
    'VIP Management',
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
  static Future<void> assignOrUpdateAdmin(
    AdminPermissionModel admin, {
    String superAdminName = 'Super Admin',
    String superAdminId = 'root',
  }) async {
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

      // Log to Assign History
      final activePermissions = admin.permissions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await logAssignHistory(
        superAdminName: superAdminName,
        superAdminId: superAdminId,
        targetUserName: admin.userName,
        targetUserId: admin.userId,
        actionType: admin.id.isEmpty
            ? 'Assigned Admin Rights'
            : 'Updated Admin Rights',
        assignedItems: activePermissions,
        details:
            'Assigned ${activePermissions.length} modules to ${admin.userName}',
      );
    } catch (e) {
      debugPrint('Error saving admin: $e');
      rethrow;
    }
  }

  // Delete Super Admin
  static Future<void> deleteAdmin(
    String docId, {
    String superAdminName = 'Super Admin',
    String superAdminId = 'root',
  }) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final userId = data['userId'];
        final userName = data['userName'] ?? 'Admin';
        if (userId != null) {
          await _firestore.collection(_usersCollection).doc(userId).update({
            'userType': 'regular',
          });
        }

        await logAssignHistory(
          superAdminName: superAdminName,
          superAdminId: superAdminId,
          targetUserName: userName,
          targetUserId: userId ?? '',
          actionType: 'Removed Super Admin',
          assignedItems: [],
          details: 'Removed $userName from Super Admin privileges',
        );
      }
      await _firestore.collection(_collectionName).doc(docId).delete();
    } catch (e) {
      debugPrint('Error deleting admin: $e');
      rethrow;
    }
  }

  // Toggle Admin Status
  static Future<void> toggleAdminStatus(
    String docId,
    bool isActive, {
    String superAdminName = 'Super Admin',
    String superAdminId = 'root',
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(docId).update({
        'isActive': isActive,
      });

      final doc = await _firestore.collection(_collectionName).doc(docId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final userId = data['userId'];
        final userName = data['userName'] ?? 'Admin';
        if (userId != null) {
          await _firestore.collection(_usersCollection).doc(userId).update({
            'userType': isActive ? 'admin' : 'regular',
          });
        }

        await logAssignHistory(
          superAdminName: superAdminName,
          superAdminId: superAdminId,
          targetUserName: userName,
          targetUserId: userId ?? '',
          actionType: isActive ? 'Activated Admin' : 'Deactivated Admin',
          assignedItems: [],
          details:
              'Toggled $userName status to ${isActive ? 'Active ✅' : 'Deactivated ❌'}',
        );
      }
    } catch (e) {
      debugPrint('Error toggling admin status: $e');
      rethrow;
    }
  }

  // Log Assign History Entry
  static Future<void> logAssignHistory({
    String superAdminName = 'Super Admin',
    String superAdminId = '',
    required String targetUserName,
    required String targetUserId,
    String targetPhone = '',
    required String actionType,
    required List<String> assignedItems,
    required String details,
  }) async {
    try {
      final now = DateTime.now();
      final dateFormatted =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // Resolve exact current logged in admin UID
      String currentAdminUid = superAdminId;
      String currentAdminName = superAdminName;

      if (currentAdminUid.isEmpty ||
          currentAdminUid == 'root' ||
          currentAdminUid == 'admin' ||
          currentAdminUid == 'unknown_admin') {
        currentAdminUid =
            AdminAuthService.currentUserId ??
            SimpleAuthService.currentUserId ??
            '';
      }

      if (currentAdminName.isEmpty || currentAdminName == 'Super Admin') {
        final email =
            AdminAuthService.currentUserEmail ??
            SimpleAuthService.currentUserEmail ??
            '';
        currentAdminName = email.isNotEmpty
            ? email.split('@').first
            : 'Super Admin';
      }

      // If currentAdminUid exists, fetch name from Users collection if missing
      if (currentAdminUid.isNotEmpty &&
          (currentAdminName == 'Super Admin' || currentAdminName.isEmpty)) {
        try {
          final userDoc = await _firestore
              .collection('Users')
              .doc(currentAdminUid)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            currentAdminName =
                (data['fullname'] ??
                        data['name'] ??
                        data['username'] ??
                        currentAdminName)
                    .toString();
          }
        } catch (_) {}
      }

      await _firestore.collection('super_admin_assign_history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'dateString': dateFormatted,
        'assignedByAdminName': currentAdminName,
        'assignedByAdminId': currentAdminUid,
        'targetUserName': targetUserName,
        'targetUserId': targetUserId,
        'targetPhone': targetPhone,
        'actionType': actionType,
        'assignedItems': assignedItems,
        'details': details,
      });
    } catch (e) {
      debugPrint('Error logging assign history: $e');
    }
  }
}
