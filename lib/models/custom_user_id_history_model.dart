import 'package:cloud_firestore/cloud_firestore.dart';

enum UserIdHistoryAction { assign, update, remove }

class CustomUserIdHistoryModel {
  final String id;
  final String userId;
  final String currentOwnerId;
  final String customUserId;
  final UserIdHistoryAction action;
  final String actionByAdminId;
  final DateTime timestamp;
  final String? notes;

  CustomUserIdHistoryModel({
    required this.id,
    required this.userId,
    required this.currentOwnerId,
    required this.customUserId,
    required this.action,
    required this.actionByAdminId,
    required this.timestamp,
    this.notes,
  });

  factory CustomUserIdHistoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomUserIdHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      currentOwnerId: map['currentOwnerId'] ?? '',
      customUserId: map['customUserId'] ?? map['customId'] ?? '',
      action: _parseAction(map['action']),
      actionByAdminId: map['actionByAdminId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentOwnerId': currentOwnerId,
      'customUserId': customUserId,
      'customId': customUserId,
      'action': action.name,
      'actionByAdminId': actionByAdminId,
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes,
    };
  }

  static UserIdHistoryAction _parseAction(String? actionStr) {
    switch (actionStr) {
      case 'assign':
        return UserIdHistoryAction.assign;
      case 'update':
        return UserIdHistoryAction.update;
      case 'remove':
        return UserIdHistoryAction.remove;
      default:
        return UserIdHistoryAction.assign;
    }
  }
}
