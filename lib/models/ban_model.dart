import 'package:cloud_firestore/cloud_firestore.dart';

enum BanType {
  device,
  login,
  mic,
  chat,
  room,
}

class BanModel {
  final String id;
  final String targetId; // userId, deviceId, or roomId
  final BanType type;
  final String reason;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String issuedBy;
  final bool isPermanent;
  final bool isActive;

  BanModel({
    required this.id,
    required this.targetId,
    required this.type,
    required this.reason,
    required this.issuedAt,
    this.expiresAt,
    required this.issuedBy,
    this.isPermanent = false,
    this.isActive = true,
  });

  factory BanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BanModel(
      id: doc.id,
      targetId: data['targetId'] ?? '',
      type: BanType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BanType.login,
      ),
      reason: data['reason'] ?? '',
      issuedAt: data['issuedAt'] != null 
          ? (data['issuedAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      issuedBy: data['issuedBy'] ?? '',
      isPermanent: data['isPermanent'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetId': targetId,
      'type': type.name,
      'reason': reason,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'issuedBy': issuedBy,
      'isPermanent': isPermanent,
      'isActive': isActive,
    };
  }

  bool get isExpired {
    if (isPermanent) return false;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
