import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPermissionModel {
  final String id;
  final String userId; // The regular user's UID or searchId
  final String userName;
  final String userImageUrl;
  final bool isActive;
  final Map<String, bool> permissions;
  final DateTime assignedAt;

  AdminPermissionModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    this.isActive = true,
    required this.permissions,
    required this.assignedAt,
  });

  factory AdminPermissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final permsData = data['permissions'] as Map<String, dynamic>? ?? {};
    
    return AdminPermissionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userImageUrl: data['userImageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      permissions: permsData.map((key, value) => MapEntry(key, value == true)),
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'isActive': isActive,
      'permissions': permissions,
      'assignedAt': Timestamp.fromDate(assignedAt),
    };
  }

  bool hasPermission(String module) {
    if (!isActive) return false;
    if (module == 'Family Management') {
      return permissions['Family Management'] == true ||
             permissions['Users Management'] == true ||
             permissions['User Profiles'] == true;
    }
    return permissions[module] == true;
  }
}
