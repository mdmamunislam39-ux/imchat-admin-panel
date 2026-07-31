import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceSessionModel {
  final String deviceId;
  final String userId;
  final String deviceName;
  final String deviceType;
  final DateTime loginTime;
  final DateTime lastActiveTime;
  final bool isActive;
  final String? location;

  DeviceSessionModel({
    required this.deviceId,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.loginTime,
    required this.lastActiveTime,
    required this.isActive,
    this.location,
  });

  factory DeviceSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeviceSessionModel(
      deviceId: doc.id,
      userId: data['userId'] ?? '',
      deviceName: data['deviceName'] ?? 'Unknown Device',
      deviceType: data['deviceType'] ?? 'Unknown Type',
      loginTime: (data['loginTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveTime: (data['lastActiveTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      location: data['location'],
    );
  }
}
