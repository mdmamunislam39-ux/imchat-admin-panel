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
    String? accountName,
    String? withdrawalBkash,
    String? sellerId,
    String? sellerName,
    double usdAmount = 0.0,
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
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create pending withdrawal doc
        final withdrawalRef = _firestore.collection('withdrawals').doc();
        transaction.set(withdrawalRef, {
          'id': withdrawalRef.id,
          'userId': userId,
          'username': username,
          'userType': userType,
          'amount': amount,
          'beanAmount': amount.toInt(),
          'usdAmount': usdAmount,
          'accountNumber': accountNumber,
          'accountName': accountName ?? username,
          'withdrawalBkash': withdrawalBkash ?? accountNumber,
          'withdrawalName': accountName ?? username,
          'sellerId': sellerId,
          'sellerName': sellerName,
          'note': note,
          'status': 'pending',
          'proofSubmitted': false,
          'paymentScreenshots': [],
          'diamondReward': (amount * 0.90).round(),
          'createdAt': FieldValue.serverTimestamp(),
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

  /// Approve a withdrawal — updates status, credits Diamonds to seller (dynamic % from config/model), notifies both
  static Future<bool> approveWithdrawal({
    required String withdrawalId,
    required String adminId,
  }) async {
    try {
      final withdrawalRef = _firestore.collection('withdrawals').doc(withdrawalId);
      final doc = await withdrawalRef.get();

      if (!doc.exists) {
        debugPrint('Withdrawal doc $withdrawalId does not exist');
        return false;
      }

      final data = doc.data() ?? {};
      final rawStatus = (data['status']?.toString().toLowerCase() ?? '');
      if (rawStatus == 'approved' || rawStatus == 'rejected') {
        debugPrint('Withdrawal $withdrawalId is already $rawStatus');
        return false;
      }

      final withdrawal = WithdrawalModel.fromFirestore(doc);
      final sellerId = withdrawal.sellerId;

      // Determine seller diamond percent: from model, or doc, or live settings
      int sellerPercent = withdrawal.sellerDiamondPercent;
      if (sellerPercent <= 0) {
        final settings = await getWithdrawalSettings();
        sellerPercent = (settings['sellerDiamondPercent'] as num?)?.toInt() ?? 90;
      }

      final double beanAmount = withdrawal.amount > 0 ? withdrawal.amount : withdrawal.beanAmount.toDouble();
      final int diamondReward = withdrawal.diamondReward > 0
          ? withdrawal.diamondReward
          : (beanAmount * (sellerPercent / 100.0)).round();

      // Execute transaction with ALL READS BEFORE WRITES
      await _firestore.runTransaction((transaction) async {
        // 1. ALL READS FIRST
        DocumentReference? sellerRef;
        DocumentSnapshot? sellerDoc;
        if (sellerId != null && sellerId.isNotEmpty) {
          sellerRef = _firestore.collection('Users').doc(sellerId);
          sellerDoc = await transaction.get(sellerRef);
        }

        // 2. ALL WRITES AFTER READS
        // Update withdrawal doc
        transaction.update(withdrawalRef, {
          'status': 'approved',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
          'diamondReward': diamondReward,
          'sellerDiamondPercent': sellerPercent,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // If seller exists, credit diamonds to seller wallet
        if (sellerRef != null && sellerDoc != null && sellerDoc.exists) {
          transaction.update(sellerRef, {
            'diamonds': FieldValue.increment(diamondReward),
            'totalDiamonds': FieldValue.increment(diamondReward),
            'diamondBalance': FieldValue.increment(diamondReward),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      // 3. Log diamond transaction record for seller history
      if (sellerId != null && sellerId.isNotEmpty) {
        try {
          await _firestore.collection('diamond_transactions').add({
            'userId': sellerId,
            'type': 'seller_withdrawal_commission',
            'amount': diamondReward,
            'description':
                '$sellerPercent% Diamond reward (+$diamondReward Diamonds) for fulfilling withdrawal #${withdrawal.id}',
            'withdrawalId': withdrawal.id,
            'beansConverted': withdrawal.amount,
            'targetUsername': withdrawal.username,
            'targetUserId': withdrawal.userId,
            'sellerDiamondPercent': sellerPercent,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Note: Could not add diamond transaction doc: $e');
        }

        // Send confirmation notification to Seller
        try {
          await NotificationService.sendNotificationToHost(
            hostId: sellerId,
            title: 'Diamond Reward Credited 💎',
            message:
                'Your payment proof was approved! +$diamondReward Diamonds ($sellerPercent%) have been credited to your wallet for fulfilling withdrawal #${withdrawal.id}.',
            type: NotificationType.general,
            data: {
              'withdrawalId': withdrawalId,
              'diamondReward': diamondReward,
              'sellerDiamondPercent': sellerPercent,
              'action': 'view_wallet',
            },
          );
        } catch (e) {
          debugPrint('Note: Could not notify seller: $e');
        }
      }

      // 4. Send confirmation notification to User
      try {
        await NotificationService.sendNotificationToHost(
          hostId: withdrawal.userId,
          title: 'Withdrawal Approved & Completed ✅',
          message:
              'Your withdrawal request of ${withdrawal.amount.toStringAsFixed(0)} beans has been verified and approved.',
          type: NotificationType.general,
          data: {
            'withdrawalId': withdrawalId,
            'amount': withdrawal.amount,
            'action': 'view_withdrawal',
          },
        );
      } catch (e) {
        debugPrint('Note: Could not notify user: $e');
      }

      debugPrint(
          'Withdrawal $withdrawalId approved by $adminId. Credited $diamondReward diamonds ($sellerPercent%) to seller $sellerId');
      return true;
    } catch (e, stack) {
      debugPrint('Error approving withdrawal: $e\n$stack');
      return false;
    }
  }

  /// Reject a withdrawal — refunds beans to user atomically, records reason, notifies both
  static Future<bool> rejectWithdrawal({
    required String withdrawalId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final withdrawalRef = _firestore.collection('withdrawals').doc(withdrawalId);
      final doc = await withdrawalRef.get();

      if (!doc.exists) {
        debugPrint('Withdrawal doc $withdrawalId does not exist');
        return false;
      }

      final data = doc.data() ?? {};
      final rawStatus = (data['status']?.toString().toLowerCase() ?? '');
      if (rawStatus == 'approved' || rawStatus == 'rejected') {
        debugPrint('Withdrawal $withdrawalId is already $rawStatus');
        return false;
      }

      final withdrawal = WithdrawalModel.fromFirestore(doc);
      final double refundBeans =
          withdrawal.amount > 0 ? withdrawal.amount : withdrawal.beanAmount.toDouble();

      await _firestore.runTransaction((transaction) async {
        // 1. Refund beans to user's wallet
        final userRef = _firestore.collection('Users').doc(withdrawal.userId);
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          transaction.update(userRef, {
            'beans': FieldValue.increment(refundBeans),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 2. Update withdrawal status in Firestore
        transaction.update(withdrawalRef, {
          'status': 'rejected',
          'rejectionReason': reason,
          'rejectedReason': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': adminId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // 3. Send notification to User about refund
      try {
        await NotificationService.sendNotificationToHost(
          hostId: withdrawal.userId,
          title: 'Withdrawal Rejected & Refunded 🔄',
          message:
              'Your withdrawal request of ${refundBeans.toStringAsFixed(0)} beans was rejected. Reason: $reason. The beans have been refunded to your wallet.',
          type: NotificationType.general,
          data: {
            'withdrawalId': withdrawalId,
            'amount': refundBeans,
            'reason': reason,
            'action': 'view_wallet',
          },
        );
      } catch (e) {
        debugPrint('Note: Could not notify user: $e');
      }

      // 4. Send notification to Seller (if assigned)
      if (withdrawal.sellerId != null && withdrawal.sellerId!.isNotEmpty) {
        try {
          await NotificationService.sendNotificationToHost(
            hostId: withdrawal.sellerId!,
            title: 'Withdrawal Proof Rejected ❌',
            message:
                'The payment proof for withdrawal request #${withdrawal.id} (${withdrawal.username}) was rejected by Admin. Reason: $reason',
            type: NotificationType.general,
            data: {
              'withdrawalId': withdrawalId,
              'reason': reason,
              'action': 'view_withdrawals',
            },
          );
        } catch (e) {
          debugPrint('Note: Could not notify seller: $e');
        }
      }

      debugPrint(
          'Withdrawal $withdrawalId rejected by $adminId: $reason. Refunded $refundBeans beans to user ${withdrawal.userId}');
      return true;
    } catch (e) {
      debugPrint('Error rejecting withdrawal: $e');
      return false;
    }
  }

  /// Admin query: get withdrawals with optional status filter
  static Future<List<WithdrawalModel>> getWithdrawals({
    WithdrawalStatus? status,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection('withdrawals')
          .orderBy('createdAt', descending: true);

      final snapshot = await query.limit(limit).get();
      final all = snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc))
          .toList();

      if (status != null) {
        return all.where((w) => w.status == status).toList();
      }
      return all;
    } catch (e) {
      debugPrint('Error getting withdrawals: $e');
      return [];
    }
  }

  /// Real-time stream of withdrawals
  static Stream<List<WithdrawalModel>> streamWithdrawals({int limit = 100}) {
    return _firestore
        .collection('withdrawals')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WithdrawalModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Admin: withdrawal statistics for stat cards
  static Future<Map<String, dynamic>> getWithdrawalStatistics() async {
    try {
      final snapshot = await _firestore.collection('withdrawals').get();

      int totalRequests = snapshot.docs.length;
      int pendingSellerCount = 0;
      int pendingAdminApprovalCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      double totalAmount = 0.0;
      double totalUsd = 0.0;
      int totalDiamondsRewarded = 0;

      for (final doc in snapshot.docs) {
        final model = WithdrawalModel.fromFirestore(doc);

        totalAmount += model.amount;
        totalUsd += model.usdAmount;

        switch (model.status) {
          case WithdrawalStatus.pending:
            pendingSellerCount++;
            break;
          case WithdrawalStatus.pendingAdminApproval:
            pendingAdminApprovalCount++;
            break;
          case WithdrawalStatus.approved:
            approvedCount++;
            totalDiamondsRewarded += model.diamondReward;
            break;
          case WithdrawalStatus.rejected:
            rejectedCount++;
            break;
        }
      }

      return {
        'totalRequests': totalRequests,
        'pendingSellerCount': pendingSellerCount,
        'pendingAdminApprovalCount': pendingAdminApprovalCount,
        'pendingCount': pendingSellerCount + pendingAdminApprovalCount,
        'approvedCount': approvedCount,
        'rejectedCount': rejectedCount,
        'totalAmount': totalAmount,
        'totalUsd': totalUsd,
        'totalDiamondsRewarded': totalDiamondsRewarded,
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
          .limit(10)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status']?.toString().toLowerCase() ?? '');
        if (status == 'pending' || status == 'pending_admin_approval') {
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error checking withdrawal eligibility: $e');
      return false;
    }
  }

  /// Get current withdrawal settings from Firestore
  static Future<Map<String, dynamic>> getWithdrawalSettings() async {
    try {
      final doc = await _firestore
          .collection('platform_config')
          .doc('gift_conversion')
          .get();

      final defaults = {
        'beansPerUsd': 10000,
        'minWithdrawUsd': 20,
        'sellerDiamondPercent': 90,
        'isWithdrawalEnabled': true,
        'withdrawPackages': [20, 75, 100, 200, 500, 800, 1000, 3000],
      };

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'beansPerUsd': (data['beansPerUsd'] as num?)?.toInt() ?? 10000,
          'minWithdrawUsd': (data['minWithdrawUsd'] as num?)?.toInt() ?? 20,
          'sellerDiamondPercent': (data['sellerDiamondPercent'] as num?)?.toInt() ?? 90,
          'isWithdrawalEnabled': data['isWithdrawalEnabled'] as bool? ?? true,
          'withdrawPackages': (data['withdrawPackages'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [20, 75, 100, 200, 500, 800, 1000, 3000],
        };
      }
      return defaults;
    } catch (e) {
      debugPrint('Error getting withdrawal settings: $e');
      return {
        'beansPerUsd': 10000,
        'minWithdrawUsd': 20,
        'sellerDiamondPercent': 90,
        'isWithdrawalEnabled': true,
        'withdrawPackages': [20, 75, 100, 200, 500, 800, 1000, 3000],
      };
    }
  }

  /// Stream live withdrawal settings for real-time reactive UI
  static Stream<Map<String, dynamic>> streamWithdrawalSettings() {
    return _firestore
        .collection('platform_config')
        .doc('gift_conversion')
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return {
          'beansPerUsd': (data['beansPerUsd'] as num?)?.toInt() ?? 10000,
          'minWithdrawUsd': (data['minWithdrawUsd'] as num?)?.toInt() ?? 20,
          'sellerDiamondPercent': (data['sellerDiamondPercent'] as num?)?.toInt() ?? 90,
          'isWithdrawalEnabled': data['isWithdrawalEnabled'] as bool? ?? true,
          'withdrawPackages': (data['withdrawPackages'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [20, 75, 100, 200, 500, 800, 1000, 3000],
        };
      }
      return {
        'beansPerUsd': 10000,
        'minWithdrawUsd': 20,
        'sellerDiamondPercent': 90,
        'isWithdrawalEnabled': true,
        'withdrawPackages': [20, 75, 100, 200, 500, 800, 1000, 3000],
      };
    });
  }

  /// Update withdrawal settings in Firestore (syncs in real-time with app)
  static Future<bool> updateWithdrawalSettings({
    required int beansPerUsd,
    required int minWithdrawUsd,
    required int sellerDiamondPercent,
    required bool isWithdrawalEnabled,
    required List<int> withdrawPackages,
  }) async {
    try {
      final payload = {
        'beansPerUsd': beansPerUsd,
        'minWithdrawUsd': minWithdrawUsd,
        'sellerDiamondPercent': sellerDiamondPercent,
        'isWithdrawalEnabled': isWithdrawalEnabled,
        'withdrawPackages': withdrawPackages,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('platform_config')
          .doc('gift_conversion')
          .set(payload, SetOptions(merge: true));

      // Also mirror to withdrawal_settings for redundancy
      await _firestore
          .collection('platform_config')
          .doc('withdrawal_settings')
          .set(payload, SetOptions(merge: true));

      debugPrint(
          'Withdrawal settings updated: 1 USD = $beansPerUsd beans, min: $minWithdrawUsd, sellerDiamond%: $sellerDiamondPercent%, enabled: $isWithdrawalEnabled, packages: $withdrawPackages');
      return true;
    } catch (e) {
      debugPrint('Error updating withdrawal settings: $e');
      return false;
    }
  }

  // =========================================================================
  // AUTHORIZED WITHDRAWAL SELLERS MANAGEMENT (withdrawal_sellers)
  // =========================================================================

  /// Stream authorized withdrawal sellers in real-time
  static Stream<List<Map<String, dynamic>>> streamWithdrawalSellers() {
    return _firestore
        .collection('withdrawal_sellers')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Get authorized withdrawal sellers list
  static Future<List<Map<String, dynamic>>> getWithdrawalSellers() async {
    try {
      final snap = await _firestore
          .collection('withdrawal_sellers')
          .orderBy('addedAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting withdrawal sellers: $e');
      return [];
    }
  }

  /// Add a user as an authorized withdrawal seller
  static Future<bool> addWithdrawalSeller({
    required String userId,
    required String username,
    required String searchId,
    String? photoUrl,
    String? userType,
  }) async {
    try {
      await _firestore.collection('withdrawal_sellers').doc(userId).set({
        'userId': userId,
        'name': username,
        'username': username,
        'searchId': searchId,
        'photoUrl': photoUrl ?? '',
        'userType': userType ?? 'Seller',
        'isActive': true,
        'addedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Added user $userId ($username, searchId: $searchId) to withdrawal_sellers');
      return true;
    } catch (e) {
      debugPrint('Error adding withdrawal seller: $e');
      return false;
    }
  }

  /// Toggle active/inactive status of a withdrawal seller
  static Future<bool> toggleWithdrawalSellerStatus(String sellerDocId, bool isActive) async {
    try {
      await _firestore
          .collection('withdrawal_sellers')
          .doc(sellerDocId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error toggling withdrawal seller status: $e');
      return false;
    }
  }

  /// Remove an authorized withdrawal seller
  static Future<bool> removeWithdrawalSeller(String sellerDocId) async {
    try {
      await _firestore
          .collection('withdrawal_sellers')
          .doc(sellerDocId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting withdrawal seller: $e');
      return false;
    }
  }
}

