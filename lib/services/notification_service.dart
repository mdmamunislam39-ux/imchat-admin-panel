import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/agency_notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Send notification to a specific host
  static Future<String> sendNotificationToHost({
    required String hostId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': hostId,
        'title': title,
        'message': message,
        'type': type.name,
        'data': data,
        'createdAt': Timestamp.now(),
        'isRead': false,
        'readAt': null,
      });
      
      debugPrint('Notification sent to host $hostId: $title');
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending notification to host: $e');
      rethrow;
    }
  }

  /// Send notification to all hosts in an agency
  static Future<List<String>> sendNotificationToAgencyHosts({
    required String agencyId,
    required String title,
    required String message,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all hosts in the agency
      final hostsQuery = await _firestore
          .collection('hosts')
          .where('agencyId', isEqualTo: agencyId)
          .where('isActive', isEqualTo: true)
          .get();
      
      final notificationIds = <String>[];
      
      for (final hostDoc in hostsQuery.docs) {
        final hostId = hostDoc.id;
        final notificationId = await sendNotificationToHost(
          hostId: hostId,
          title: title,
          message: message,
          type: type,
          data: data,
        );
        notificationIds.add(notificationId);
      }
      
      debugPrint('Notifications sent to ${notificationIds.length} hosts in agency $agencyId');
      return notificationIds;
    } catch (e) {
      debugPrint('Error sending notifications to agency hosts: $e');
      rethrow;
    }
  }

  /// Get notifications for a specific user
  static Future<List<AgencyNotificationModel>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data();
        return AgencyNotificationModel(
          id: doc.id,
          agencyId: '', // Not applicable for user notifications
          hostId: userId,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: NotificationType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => NotificationType.general,
          ),
          status: data['isRead'] == true ? NotificationStatus.read : NotificationStatus.unread,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
          data: data['data'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      
      debugPrint('Notification $notificationId marked as read');
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllNotificationsAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.now(),
        });
      }
      
      await batch.commit();
      
      debugPrint('Marked ${query.docs.length} notifications as read for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      return query.docs.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Send host invitation notification
  static Future<String> sendHostInvitationNotification({
    required String hostId,
    required String agencyName,
    required String invitationId,
  }) async {
    return await sendNotificationToHost(
      hostId: hostId,
      title: 'Agency Invitation',
      message: 'You have been invited to join $agencyName agency. Tap to view details.',
      type: NotificationType.hostInvitation,
      data: {
        'invitationId': invitationId,
        'agencyName': agencyName,
        'action': 'view_invitation',
      },
    );
  }

  /// Send commission payment notification
  static Future<String> sendCommissionPaymentNotification({
    required String hostId,
    required String agencyName,
    required double amount,
    required DateTime paymentDate,
  }) async {
    return await sendNotificationToHost(
      hostId: hostId,
      title: 'Commission Payment Received',
      message: 'You have received a commission payment of \$${amount.toStringAsFixed(2)} from $agencyName.',
      type: NotificationType.commissionPayment,
      data: {
        'amount': amount,
        'agencyName': agencyName,
        'paymentDate': paymentDate.toIso8601String(),
        'action': 'view_payment',
      },
    );
  }

  /// Send host performance notification
  static Future<String> sendHostPerformanceNotification({
    required String hostId,
    required String agencyName,
    required String performanceType,
    required String message,
  }) async {
    return await sendNotificationToHost(
      hostId: hostId,
      title: 'Performance Update',
      message: message,
      type: NotificationType.hostPerformance,
      data: {
        'agencyName': agencyName,
        'performanceType': performanceType,
        'action': 'view_performance',
      },
    );
  }

  /// Send system alert notification
  static Future<String> sendSystemAlertNotification({
    required String hostId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    return await sendNotificationToHost(
      hostId: hostId,
      title: title,
      message: message,
      type: NotificationType.systemAlert,
      data: data,
    );
  }

  /// Send host removal notification
  static Future<String> sendHostRemovalNotification({
    required String hostId,
    required String agencyName,
    required String reason,
  }) async {
    return await sendNotificationToHost(
      hostId: hostId,
      title: 'Agency Membership Ended',
      message: 'Your membership with $agencyName has been ended. Reason: $reason',
      type: NotificationType.hostRemoval,
      data: {
        'agencyName': agencyName,
        'reason': reason,
        'action': 'view_details',
      },
    );
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      debugPrint('Notification $notificationId deleted');
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all notifications for a user
  static Future<bool> deleteAllNotifications(String userId) async {
    try {
      final query = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      debugPrint('Deleted ${query.docs.length} notifications for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      return false;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStatistics() async {
    try {
      // Get total notifications
      final totalQuery = await _firestore.collection('notifications').get();
      
      // Get unread notifications
      final unreadQuery = await _firestore
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      // Get notifications by type
      final typeStats = <String, int>{};
      for (final doc in totalQuery.docs) {
        final type = doc.data()['type'] ?? 'general';
        typeStats[type] = (typeStats[type] ?? 0) + 1;
      }
      
      return {
        'totalNotifications': totalQuery.docs.length,
        'unreadNotifications': unreadQuery.docs.length,
        'typeStatistics': typeStats,
      };
    } catch (e) {
      debugPrint('Error getting notification statistics: $e');
      return {};
    }
  }

  /// Stream notifications for real-time updates
  static Stream<List<AgencyNotificationModel>> streamUserNotifications(String userId, {int limit = 50}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AgencyNotificationModel(
          id: doc.id,
          agencyId: '', // Not applicable for user notifications
          hostId: userId,
          title: data['title'] ?? '',
          message: data['message'] ?? '',
          type: NotificationType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => NotificationType.general,
          ),
          status: data['isRead'] == true ? NotificationStatus.read : NotificationStatus.unread,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
          data: data['data'],
        );
      }).toList();
    });
  }
}
