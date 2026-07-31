import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyNotificationModel {
  final String id;
  final String agencyId;
  final String? hostId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  AgencyNotificationModel({
    required this.id,
    required this.agencyId,
    this.hostId,
    required this.title,
    required this.message,
    required this.type,
    this.status = NotificationStatus.unread,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  factory AgencyNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgencyNotificationModel(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      hostId: data['hostId'],
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => NotificationStatus.unread,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null 
          ? (data['readAt'] as Timestamp).toDate()
          : null,
      data: data['data'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyId': agencyId,
      'hostId': hostId,
      'title': title,
      'message': message,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
    };
  }

  AgencyNotificationModel copyWith({
    String? id,
    String? agencyId,
    String? hostId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return AgencyNotificationModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}

enum NotificationType {
  general,
  hostInvitation,
  commissionPayment,
  hostPerformance,
  systemAlert,
  hostRemoval,
}

enum NotificationStatus {
  unread,
  read,
  archived,
}

class HostInvitationModel {
  final String id;
  final String agencyId;
  final String hostUserId;
  final String hostName;
  final String hostEmail;
  final String hostPhone;
  final InvitationStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final String? message;
  final String? agencyName;

  HostInvitationModel({
    required this.id,
    required this.agencyId,
    required this.hostUserId,
    required this.hostName,
    required this.hostEmail,
    required this.hostPhone,
    this.status = InvitationStatus.pending,
    required this.sentAt,
    this.respondedAt,
    this.message,
    this.agencyName,
  });

  factory HostInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HostInvitationModel(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      hostUserId: data['hostUserId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostEmail: data['hostEmail'] ?? '',
      hostPhone: data['hostPhone'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null 
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      message: data['message'],
      agencyName: data['agencyName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agencyId': agencyId,
      'hostUserId': hostUserId,
      'hostName': hostName,
      'hostEmail': hostEmail,
      'hostPhone': hostPhone,
      'status': status.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'message': message,
      'agencyName': agencyName,
    };
  }

  HostInvitationModel copyWith({
    String? id,
    String? agencyId,
    String? hostUserId,
    String? hostName,
    String? hostEmail,
    String? hostPhone,
    InvitationStatus? status,
    DateTime? sentAt,
    DateTime? respondedAt,
    String? message,
    String? agencyName,
  }) {
    return HostInvitationModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      hostUserId: hostUserId ?? this.hostUserId,
      hostName: hostName ?? this.hostName,
      hostEmail: hostEmail ?? this.hostEmail,
      hostPhone: hostPhone ?? this.hostPhone,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
      agencyName: agencyName ?? this.agencyName,
    );
  }
}

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
}
