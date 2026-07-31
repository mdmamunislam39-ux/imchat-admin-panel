import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/withdrawal_model.dart';
import '../models/agency_notification_model.dart';
import 'notification_service.dart';

class WithdrawalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a withdrawal request — deducts beans immediately (escrow)
  static Future<bool> createWithdrawalRequest({
    required String userId,
    required String username,
    required String userType,
    required double amount,
    required String accountNumber,
    String? note,
  }) async {
    try {
      // Check if user already has a pending withdrawal
      final canWithdraw = await canUserWithdraw(userId);
      if (!canWithdraw) {
        debugPrint('User $userId already has a pending withdrawal');
        return false;
      }

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('Users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw Exception('User not found');

        final currentBeans = (userDoc.data()?['beans'] ?? 0.0).toDouble();
        if (currentBeans < amount) throw Exception('Insufficient beans');

        // Deduct beans (escrow)
        transaction.update(userRef, {
          'beans': FieldValue.increment(-amount),
        });

        // Create pending withdrawal doc
        final withdrawalRef = _firestore.collection('withdrawals').doc();
        transaction.set(withdrawalRef, {
          'userId': userId,
          'username': username,
          'userType': userType,
          'amount': amount,
          'accountNumber': accountNumber,
          'note': note,
          'status': WithdrawalStatus.pending.name,
          'createdAt': Timestamp.now(),
          'reviewedAt': null,
          'reviewedBy': null,
          'rejectionReason': null,
        });
      });

      debugPrint('Withdrawal request created for $username: $amount beans');
      return true;
    } catch (e) {
      debugPrint('Error creating withdrawal request: $e');
      return false;
    }
  }

  /// Approve a withdrawal (= complete, one step)
  static Future<bool> approveWithdrawal({
    required String withdrawalId,
    required String adminId,
  }) async {
    try {
      final withdrawalRef = _firestore.collection('withdrawals').doc(withdrawalId);
      final doc = await withdrawalRef.get();

      if (!doc.exists) return false;

      final withdrawal = WithdrawalModel.fromFirestore(doc);
      if (withdrawal.status != WithdrawalStatus.pending) return false;

      await withdrawalRef.update({
        'status': WithdrawalStatus.approved.name,
        'reviewedAt': Timestamp.now(),
        'reviewedBy': adminId,
      });

      // Send notification
      await NotificationService.sendNotificationToHost(
        hostId: withdrawal.userId,
        title: 'Withdrawal Approved',
        message: 'Your withdrawal request of ${withdrawal.amount.toStringAsFixed(0)} beans has been approved.',
        type: NotificationType.general,
        data: {
          'withdrawalId': withdrawalId,
          'amount': withdrawal.amount,
          'action': 'view_withdrawal',
        },
      );

      debugPrint('Withdrawal $withdrawalId approved by $adminId');
      return true;
    } catch (e) {
      debugPrint('Error approving withdrawal: $e');
      return false;
    }
  }

  /// Reject a withdrawal — refunds beans atomically
  static Future<bool> rejectWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final withdrawalRef = _firestore.collection('withdrawals').doc(withdrawalId);
        final doc = await transaction.get(withdrawalRef);

        if (!doc.exists) throw Exception('Withdrawal not found');

        final withdrawal = WithdrawalModel.fromFirestore(doc);
        if (withdrawal.status != WithdrawalStatus.pending) {
          throw Exception('Withdrawal is not pending');
        }

        // Refund beans
        final userRef = _firestore.collection('Users').doc(withdrawal.userId);
        transaction.update(userRef, {
          'beans': FieldValue.increment(withdrawal.amount),
        });

        // Update withdrawal status
        transaction.update(withdrawalRef, {
          'status': WithdrawalStatus.rejected.name,
          'reviewedAt': Timestamp.now(),
          'reviewedBy': adminId,
          'rejectionReason': reason,
        });
      });

      // Send notification (outside transaction)
      final doc = await _firestore.collection('withdrawals').doc(withdrawalId).get();
      final withdrawal = WithdrawalModel.fromFirestore(doc);

      await NotificationService.sendNotificationToHost(
        hostId: withdrawal.userId,
        title: 'Withdrawal Rejected',
        message: 'Your withdrawal request of ${withdrawal.amount.toStringAsFixed(0)} beans has been rejected. Reason: $reason',
        type: NotificationType.general,
        data: {
          'withdrawalId': withdrawalId,
          'amount': withdrawal.amount,
          'reason': reason,
          'action': 'view_withdrawal',
        },
      );

      debugPrint('Withdrawal $withdrawalId rejected by $adminId: $reason');
      return true;
    } catch (e) {
      debugPrint('Error rejecting withdrawal: $e');
      return false;
    }
  }

  /// Admin query: get withdrawals with optional status filter
  static Future<List<WithdrawalModel>> getWithdrawals({
    WithdrawalStatus? status,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('withdrawals')
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting withdrawals: $e');
      return [];
    }
  }

  /// Admin: withdrawal statistics for stat cards
  static Future<Map<String, dynamic>> getWithdrawalStatistics() async {
    try {
      final snapshot = await _firestore.collection('withdrawals').get();

      int totalRequests = snapshot.docs.length;
      int pendingCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      double totalAmount = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final amount = (data['amount'] ?? 0.0).toDouble();

        totalAmount += amount;

        if (status == WithdrawalStatus.pending.name) {
          pendingCount++;
        } else if (status == WithdrawalStatus.approved.name) {
          approvedCount++;
        } else if (status == WithdrawalStatus.rejected.name) {
          rejectedCount++;
        }
      }

      return {
        'totalRequests': totalRequests,
        'pendingCount': pendingCount,
        'approvedCount': approvedCount,
        'rejectedCount': rejectedCount,
        'totalAmount': totalAmount,
      };
    } catch (e) {
      debugPrint('Error getting withdrawal statistics: $e');
      return {};
    }
  }

  /// Check if user can withdraw (no pending withdrawal exists)
  static Future<bool> canUserWithdraw(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('withdrawals')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: WithdrawalStatus.pending.name)
          .limit(1)
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking withdrawal eligibility: $e');
      return false;
    }
  }
}
