import 'package:cloud_firestore/cloud_firestore.dart';

class SubOfficialAdminModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role; // 'sub_official_admin'
  final bool isActive;
  final Map<String, String> permissions; // moduleName -> 'edit' | 'view' | 'none'
  final DateTime createdAt;
  final String createdBy;
  final DateTime? lastLogin;

  SubOfficialAdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone = '',
    this.role = 'sub_official_admin',
    this.isActive = true,
    required this.permissions,
    required this.createdAt,
    this.createdBy = 'Super Admin',
    this.lastLogin,
  });

  factory SubOfficialAdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Handle permissions which can be Map<String, dynamic> or legacy List<dynamic>
    Map<String, String> permsMap = {};
    if (data['permissions'] is Map) {
      final rawPerms = data['permissions'] as Map<String, dynamic>;
      rawPerms.forEach((key, value) {
        if (value == true || value == 'edit') {
          permsMap[key] = 'edit';
        } else if (value == 'view') {
          permsMap[key] = 'view';
        } else {
          permsMap[key] = 'none';
        }
      });
    } else if (data['permissions'] is List) {
      final list = List<String>.from(data['permissions'] ?? []);
      for (var item in list) {
        permsMap[item] = 'edit'; // Default legacy list to edit
      }
    }

    return SubOfficialAdminModel(
      id: doc.id,
      name: data['name'] ?? data['fullname'] ?? data['userName'] ?? (data['email'] != null ? (data['email'] as String).split('@').first : 'Sub Admin'),
      email: data['email'] ?? '',
      password: data['password'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'sub_official_admin',
      isActive: data['isActive'] ?? true,
      permissions: permsMap,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now())
          : DateTime.now(),
      createdBy: data['createdBy'] ?? 'Super Admin',
      lastLogin: data['lastLogin'] != null && data['lastLogin'] is Timestamp
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone,
      'role': role,
      'isActive': isActive,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    };
  }

  // Helper checks
  bool hasAccess(String module) {
    if (!isActive) return false;
    final level = permissions[module];
    return level == 'edit' || level == 'view';
  }

  bool canEdit(String module) {
    if (!isActive) return false;
    return permissions[module] == 'edit';
  }

  bool canView(String module) {
    if (!isActive) return false;
    return permissions[module] == 'view' || permissions[module] == 'edit';
  }

  String getPermissionLevel(String module) {
    return permissions[module] ?? 'none';
  }

  int get totalAssignedModules {
    return permissions.values.where((v) => v == 'edit' || v == 'view').length;
  }

  int get totalEditModules {
    return permissions.values.where((v) => v == 'edit').length;
  }

  int get totalViewModules {
    return permissions.values.where((v) => v == 'view').length;
  }
}
