import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUserIdModel {
  final String id;
  final String userId; // Document ID of the user
  final String originalUserId; // Original numeric searchId / ID
  final String customUserId; // The new assigned short ID
  final String userName;
  final String userImageUrl;
  final DateTime assignedAt;
  final DateTime expiresAt;
  final bool isActive;

  CustomUserIdModel({
    required this.id,
    required this.userId,
    required this.originalUserId,
    required this.customUserId,
    required this.userName,
    required this.userImageUrl,
    required this.assignedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  factory CustomUserIdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CustomUserIdModel(
      id: doc.id,
      userId: (data['userId'] ?? data['id'] ?? doc.id).toString(),
      originalUserId: (data['originalUserId'] ?? data['originalSearchId'] ?? data['searchId'] ?? '').toString(),
      customUserId: (data['customId'] ?? data['customUserId'] ?? data['customSearchId'] ?? '').toString(),
      userName: (data['userName'] ?? data['fullname'] ?? data['name'] ?? 'User').toString(),
      userImageUrl: (data['userImageUrl'] ?? data['photoUrl'] ?? data['avatar'] ?? '').toString(),
      assignedAt: data['assignedAt'] != null && data['assignedAt'] is Timestamp
          ? (data['assignedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null && data['expiresAt'] is Timestamp
          ? (data['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      isActive: (data['isActive'] == true || data['status'] == 'active') &&
          (data['isActive'] != false && data['status'] != 'deactivated' && data['status'] != 'inactive'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalUserId': originalUserId,
      'originalSearchId': originalUserId,
      'customId': customUserId,
      'customUserId': customUserId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'status': isActive ? 'active' : 'deactivated',
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get styleCategory {
    final length = customUserId.length;
    if (length == 1) return '1-Digit';
    if (length == 2) return '2-Digit';
    if (length >= 3 && length <= 4) return '3-4-Digit';
    if (length >= 5 && length <= 6) return '5-6-Digit';
    return 'Default';
  }
}
