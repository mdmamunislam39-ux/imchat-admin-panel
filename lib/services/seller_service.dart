import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/seller_model.dart';
import '../models/transaction_model.dart';
import 'svip_service.dart';
import 'user_position_service.dart';

class SellerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _sellersCollection = 'sellers';
  static const String _transactionsCollection = 'seller_transactions';
  static const String _rechargeHistoryCollection = 'recharge_history';
  static const String _usersCollection = 'Users';
  static const String _sellerSalesSummaryCollection = 'seller_sales_summary';

  // Create a new seller
  static Future<String?> createSeller({
    required String userId,
    required String sellerName,
    String? profilePicture,
    required String idNumber,
    required String profileId,
    String? adminId,
  }) async {
    try {
      final sellerId = _firestore.collection(_sellersCollection).doc().id;
      final now = DateTime.now();
      
      final seller = SellerModel(
        id: sellerId,
        userId: userId,
        sellerName: sellerName,
        profilePicture: profilePicture,
        idNumber: idNumber,
        profileId: profileId,
        accountBalance: 0.0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Create seller document
      await _firestore.collection(_sellersCollection).doc(sellerId).set(seller.toFirestore());

      // Update user document to mark as seller
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isSeller': true,
        'sellerId': sellerId,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Create initial sales summary
      await _firestore.collection(_sellerSalesSummaryCollection).doc(sellerId).set({
        'totalDaily': 0.0,
        'totalWeekly': 0.0,
        'totalMonthly': 0.0,
        'lastUpdated': Timestamp.fromDate(now),
      });

      // Automatically apply Seller position items (Frame, Badge, Nameplate)
      try {
        await UserPositionService.applyPositionToUser(
          userId: userId,
          positionKey: 'seller',
          adminId: adminId,
          userProfileId: profileId,
          userName: sellerName,
        );
      } catch (e) {
        debugPrint('⚠️ Error auto-applying seller position items: $e');
      }

      // Log admin action
      if (adminId != null) {
        await _logTransaction(
          sellerId: sellerId,
          amount: 0.0,
          type: TransactionType.add,
          description: 'Seller account created by admin',
          adminId: adminId,
        );
      }

      debugPrint('Seller created successfully: $sellerId');
      return sellerId;
    } catch (e) {
      debugPrint('Error creating seller: $e');
      return null;
    }
  }

  // Get real-time stream of all sellers
  static Stream<List<SellerModel>> getSellersStream() {
    return _firestore
        .collection(_sellersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SellerModel.fromFirestore(doc)).toList());
  }

  // Get all sellers
  static Future<List<SellerModel>> getAllSellers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_sellersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SellerModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all sellers: $e');
      return [];
    }
  }

  // Get seller by ID
  static Future<SellerModel?> getSellerById(String sellerId) async {
    try {
      final doc = await _firestore.collection(_sellersCollection).doc(sellerId).get();
      if (doc.exists) {
        return SellerModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting seller by ID: $e');
      return null;
    }
  }

  // Get seller by user ID
  static Future<SellerModel?> getSellerByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sellersCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SellerModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting seller by user ID: $e');
      return null;
    }
  }

  // Update seller balance
  static Future<bool> updateSellerBalance({
    required String sellerId,
    required double amount,
    required TransactionType type,
    required String description,
    String? adminId,
  }) async {
    try {
      final sellerRef = _firestore.collection(_sellersCollection).doc(sellerId);
      
      await _firestore.runTransaction((transaction) async {
        final sellerDoc = await transaction.get(sellerRef);
        if (!sellerDoc.exists) {
          throw Exception('Seller not found');
        }

        final seller = SellerModel.fromFirestore(sellerDoc);
        double newBalance = seller.accountBalance;
        
        if (type == TransactionType.add) {
          newBalance += amount;
        } else if (type == TransactionType.minus) {
          newBalance -= amount;
          if (newBalance < 0) {
            throw Exception('Insufficient balance');
          }
        }

        final updatedSeller = seller.copyWith(
          accountBalance: newBalance,
          updatedAt: DateTime.now(),
        );

        transaction.update(sellerRef, updatedSeller.toFirestore());
      });

      // Log transaction
      await _logTransaction(
        sellerId: sellerId,
        amount: amount,
        type: type,
        description: description,
        adminId: adminId,
      );

      // Sync balance to Users document in real-time
      try {
        final updatedDoc = await _firestore.collection(_sellersCollection).doc(sellerId).get();
        if (updatedDoc.exists) {
          final sData = updatedDoc.data() ?? {};
          final uId = sData['userId']?.toString();
          final bal = (sData['accountBalance'] ?? 0.0).toDouble();
          if (uId != null && uId.isNotEmpty) {
            await _firestore.collection(_usersCollection).doc(uId).update({
              'diamonds': bal.toInt(),
              'totalDiamonds': bal.toInt(),
              'walletDiamonds': bal.toInt(),
            });
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error syncing seller balance to Users doc: $e');
      }

      debugPrint('Seller balance updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating seller balance: $e');
      return false;
    }
  }

  // Update seller info and sync with Users document in real-time
  static Future<bool> updateSellerInfo({
    required String sellerId,
    required String userId,
    required String sellerName,
    required String idNumber,
    required String profileId,
    String? phone,
    String? email,
  }) async {
    try {
      final now = DateTime.now();
      await _firestore.collection(_sellersCollection).doc(sellerId).update({
        'sellerName': sellerName,
        'idNumber': idNumber,
        'profileId': profileId,
        'updatedAt': Timestamp.fromDate(now),
      });

      if (userId.isNotEmpty) {
        final Map<String, dynamic> userUpdate = {
          'fullname': sellerName,
          'searchId': profileId,
          'updatedAt': Timestamp.fromDate(now),
        };
        if (phone != null && phone.isNotEmpty) {
          userUpdate['number'] = phone;
          userUpdate['phone'] = phone;
        }
        if (email != null && email.isNotEmpty) {
          userUpdate['email'] = email;
          userUpdate['googleEmail'] = email;
        }
        await _firestore.collection(_usersCollection).doc(userId).update(userUpdate);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating seller info: $e');
      return false;
    }
  }

  // Toggle seller status (activate/deactivate)
  static Future<bool> toggleSellerStatus({
    required String sellerId,
    required bool isActive,
    String? adminId,
  }) async {
    try {
      final now = DateTime.now();
      
      await _firestore.collection(_sellersCollection).doc(sellerId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update user document and sync position items
      final seller = await getSellerById(sellerId);
      if (seller != null) {
        await _firestore.collection(_usersCollection).doc(seller.userId).update({
          'isSeller': isActive,
          'updatedAt': Timestamp.fromDate(now),
        });

        try {
          if (isActive) {
            await UserPositionService.applyPositionToUser(
              userId: seller.userId,
              positionKey: 'seller',
              adminId: adminId,
            );
          } else {
            await UserPositionService.removePositionFromUser(
              userId: seller.userId,
              positionKey: 'seller',
              adminId: adminId,
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error updating seller position items on status toggle: $e');
        }
      }

      // Log transaction
      if (adminId != null) {
        await _logTransaction(
          sellerId: sellerId,
          amount: 0.0,
          type: TransactionType.add,
          description: isActive ? 'Seller activated by admin' : 'Seller deactivated by admin',
          adminId: adminId,
        );
      }

      debugPrint('Seller status updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating seller status: $e');
      return false;
    }
  }

  // Recharge user (seller operation)
  static Future<bool> rechargeUser({
    required String sellerId,
    required String userId,
    required String userProfileId,
    required String userPhoneNumber,
    required String userName,
    required double amount,
  }) async {
    try {
      final sellerRef = _firestore.collection('sellers').doc(sellerId);
      final userRef = _firestore.collection('Users').doc(userId);

      // Fetch SVIP levels outside transaction
      final svipLevelsSnap = await _firestore.collection('config').doc('svip_levels').collection('levels').get();
      final svipLevels = svipLevelsSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      await _firestore.runTransaction((transaction) async {
        // Check seller balance
        final sellerDoc = await transaction.get(sellerRef);
        if (!sellerDoc.exists) {
          throw Exception('Seller not found');
        }

        final seller = SellerModel.fromFirestore(sellerDoc);
        if (!seller.isActive) {
          throw Exception('Seller account is inactive');
        }

        if (seller.accountBalance < amount) {
          throw Exception('Insufficient seller balance');
        }

        // Check user exists
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        // Check SVIP monthly reset
        final userData = userDoc.data() ?? {};
        final lastMonth = userData['lastRechargeMonth'] as String? ?? '';
        final now = DateTime.now();
        final currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
        


        // Update seller balance
        final updatedSeller = seller.copyWith(
          accountBalance: seller.accountBalance - amount,
          totalSales: seller.totalSales + amount,
          totalUsersRecharged: seller.totalUsersRecharged + 1,
          updatedAt: DateTime.now(),
        );
        transaction.update(sellerRef, updatedSeller.toFirestore());

        // Update user balance and SVIP tracking
        int previousMonthlyRecharge = (userData['monthlyRechargeAmount'] as num?)?.toInt() ?? 0;
        int newMonthlyRecharge = amount.toInt();

        if (lastMonth != currentMonth) {
          transaction.update(userRef, {
            'diamonds': FieldValue.increment(amount),
            'totalDiamonds': FieldValue.increment(amount),
            'monthlyRechargeAmount': amount.toInt(),
            'lastRechargeMonth': currentMonth,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          newMonthlyRecharge = previousMonthlyRecharge + amount.toInt();
          transaction.update(userRef, {
            'diamonds': FieldValue.increment(amount),
            'totalDiamonds': FieldValue.increment(amount),
            'monthlyRechargeAmount': FieldValue.increment(amount.toInt()),
            'lastRechargeMonth': currentMonth,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // Auto upgrade SVIP
        await SvipService.checkAndAutoUpgradeSvip(
          userId: userId,
          newRechargeAmount: newMonthlyRecharge,
          currentMonth: currentMonth,
          transaction: transaction,
          userRef: userRef,
          userData: userData,
          svipLevels: svipLevels,
        );
      });

      // Log recharge transaction
      await _logRechargeTransaction(
        sellerId: sellerId,
        userId: userId,
        userProfileId: userProfileId,
        userPhoneNumber: userPhoneNumber,
        userName: userName,
        amount: amount,
      );

      // Update sales summary
      await _updateSalesSummary(sellerId, amount);

      debugPrint('User recharged successfully');
      return true;
    } catch (e) {
      debugPrint('Error recharging user: $e');
      return false;
    }
  }

  // Get seller transactions
  static Future<List<TransactionModel>> getSellerTransactions(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting seller transactions: $e');
      return [];
    }
  }

  // Get recharge history
  static Future<List<RechargeHistoryModel>> getRechargeHistory(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_rechargeHistoryCollection)
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => RechargeHistoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting recharge history: $e');
      return [];
    }
  }

  // Search user by profile ID, phone number, email or UID
  static Future<Map<String, dynamic>?> searchUser(String query) async {
    try {
      final clean = query.trim();
      if (clean.isEmpty) return null;

      // 1. Search by searchId (profile ID) first
      var querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('searchId', isEqualTo: clean)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return {
          'id': querySnapshot.docs.first.id,
          'name': userData['fullname'] ?? userData['name'] ?? userData['username'] ?? '',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? userData['phone'] ?? '',
          'email': userData['email'] ?? userData['googleEmail'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
        };
      }

      // 2. Search by phone number (number or phone)
      querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('number', isEqualTo: clean)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await _firestore
            .collection(_usersCollection)
            .where('phone', isEqualTo: clean)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return {
          'id': querySnapshot.docs.first.id,
          'name': userData['fullname'] ?? userData['name'] ?? userData['username'] ?? '',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? userData['phone'] ?? '',
          'email': userData['email'] ?? userData['googleEmail'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
        };
      }

      // 3. Search by Google / Email
      querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: clean)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return {
          'id': querySnapshot.docs.first.id,
          'name': userData['fullname'] ?? userData['name'] ?? userData['username'] ?? '',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? userData['phone'] ?? '',
          'email': userData['email'] ?? userData['googleEmail'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
        };
      }

      // 4. By Document ID
      final docSnap = await _firestore.collection(_usersCollection).doc(clean).get();
      if (docSnap.exists) {
        final userData = docSnap.data() ?? {};
        return {
          'id': docSnap.id,
          'name': userData['fullname'] ?? userData['name'] ?? userData['username'] ?? '',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? userData['phone'] ?? '',
          'email': userData['email'] ?? userData['googleEmail'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // Get seller sales summary
  static Future<SellerSalesSummary?> getSellerSalesSummary(String sellerId) async {
    try {
      final doc = await _firestore.collection(_sellerSalesSummaryCollection).doc(sellerId).get();
      if (doc.exists) {
        return SellerSalesSummary.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting seller sales summary: $e');
      return null;
    }
  }

  // Private helper methods
  static Future<void> _logTransaction({
    required String sellerId,
    required double amount,
    required TransactionType type,
    required String description,
    String? adminId,
  }) async {
    try {
      final transaction = TransactionModel(
        id: _firestore.collection(_transactionsCollection).doc().id,
        sellerId: sellerId,
        amount: amount,
        type: type,
        description: description,
        createdAt: DateTime.now(),
        adminId: adminId,
      );

      await _firestore.collection(_transactionsCollection).doc(transaction.id).set(transaction.toFirestore());
    } catch (e) {
      debugPrint('Error logging transaction: $e');
    }
  }

  static Future<void> _logRechargeTransaction({
    required String sellerId,
    required String userId,
    required String userProfileId,
    required String userPhoneNumber,
    required String userName,
    required double amount,
  }) async {
    try {
      final seller = await getSellerById(sellerId);
      if (seller == null) return;

      final rechargeHistory = RechargeHistoryModel(
        id: _firestore.collection(_rechargeHistoryCollection).doc().id,
        sellerId: sellerId,
        sellerName: seller.sellerName,
        userId: userId,
        userProfileId: userProfileId,
        userPhoneNumber: userPhoneNumber,
        userName: userName,
        amount: amount,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_rechargeHistoryCollection).doc(rechargeHistory.id).set(rechargeHistory.toFirestore());

      // Also log as transaction
      await _logTransaction(
        sellerId: sellerId,
        amount: amount,
        type: TransactionType.sell,
        description: 'Recharged $userName ($userProfileId) with $amount💎',
      );
    } catch (e) {
      debugPrint('Error logging recharge transaction: $e');
    }
  }

  static Future<void> _updateSalesSummary(String sellerId, double amount) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));

      final summaryRef = _firestore.collection(_sellerSalesSummaryCollection).doc(sellerId);
      
      await _firestore.runTransaction((transaction) async {
        final summaryDoc = await transaction.get(summaryRef);
        SellerSalesSummary summary;
        
        if (summaryDoc.exists) {
          summary = SellerSalesSummary.fromFirestore(summaryDoc);
        } else {
          summary = SellerSalesSummary(
            sellerId: sellerId,
            lastUpdated: now,
          );
        }

        // Update daily total (reset if new day)
        if (summary.lastUpdated.day != now.day) {
          summary = summary.copyWith(totalDaily: amount);
        } else {
          summary = summary.copyWith(totalDaily: summary.totalDaily + amount);
        }

        // Update weekly total (reset if new week)
        if (summary.lastUpdated.isBefore(weekStart)) {
          summary = summary.copyWith(totalWeekly: amount);
        } else {
          summary = summary.copyWith(totalWeekly: summary.totalWeekly + amount);
        }

        // Update monthly total (reset if new month)
        if (summary.lastUpdated.month != now.month) {
          summary = summary.copyWith(totalMonthly: amount);
        } else {
          summary = summary.copyWith(totalMonthly: summary.totalMonthly + amount);
        }

        summary = summary.copyWith(lastUpdated: now);
        transaction.set(summaryRef, summary.toFirestore());
      });
    } catch (e) {
      debugPrint('Error updating sales summary: $e');
    }
  }

  // --- Seller Top-Up Requests Management ---

  /// Stream all seller top-up requests
  static Stream<QuerySnapshot<Map<String, dynamic>>> getSellerRequestsStream() {
    return _firestore
        .collection('seller_diamond_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Approve a seller top-up request
  static Future<bool> approveSellerDiamondRequest({
    required String requestId,
    required String sellerId,
    required String sellerName,
    required String sellerSearchId,
    required int amount,
    required String adminId,
    required String adminName,
    required String adminNote,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      // 1. Locate or create seller document
      final sellerSnap = await _firestore
          .collection(_sellersCollection)
          .where('userId', isEqualTo: sellerId)
          .limit(1)
          .get();

      String sellerDocId = '';
      if (sellerSnap.docs.isNotEmpty) {
        sellerDocId = sellerSnap.docs.first.id;
        await _firestore.collection(_sellersCollection).doc(sellerDocId).update({
          'accountBalance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newDoc = _firestore.collection(_sellersCollection).doc();
        sellerDocId = newDoc.id;
        await newDoc.set({
          'userId': sellerId,
          'sellerName': sellerName,
          'idNumber': sellerSearchId,
          'profileId': sellerSearchId,
          'accountBalance': amount.toDouble(),
          'totalSales': 0.0,
          'totalUsersRecharged': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Add record in seller_admin_credits
      final creditDoc = _firestore.collection('seller_admin_credits').doc();
      await creditDoc.set({
        'id': creditDoc.id,
        'sellerId': sellerId,
        'sellerDocId': sellerDocId,
        'sellerName': sellerName,
        'sellerSearchId': sellerSearchId,
        'amount': amount,
        'note': adminNote,
        'adminNote': adminNote,
        'paymentMethod': paymentMethod ?? '',
        'transactionId': transactionId ?? '',
        'adminId': adminId,
        'adminName': adminName,
        'type': 'request_approved',
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Log transaction
      await _logTransaction(
        sellerId: sellerDocId.isNotEmpty ? sellerDocId : sellerId,
        amount: amount.toDouble(),
        type: TransactionType.add,
        description: 'Approved top-up request #$requestId via ${paymentMethod ?? 'Direct'}. Admin: $adminName. Note: $adminNote',
        adminId: adminId,
      );

      // 4. Update request status in seller_diamond_requests
      await _firestore.collection('seller_diamond_requests').doc(requestId).update({
        'status': 'approved',
        'adminNote': adminNote,
        'processedBy': adminName,
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error approving seller request: $e');
      return false;
    }
  }

  /// Reject a seller top-up request
  static Future<bool> rejectSellerDiamondRequest({
    required String requestId,
    required String adminId,
    required String adminName,
    required String rejectionReason,
  }) async {
    try {
      await _firestore.collection('seller_diamond_requests').doc(requestId).update({
        'status': 'rejected',
        'adminNote': rejectionReason,
        'processedBy': adminName,
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error rejecting seller request: $e');
      return false;
    }
  }

  /// Direct credit seller diamonds
  static Future<bool> directCreditSellerDiamonds({
    required String sellerId,
    required String sellerName,
    required String sellerSearchId,
    required int amount,
    required String adminId,
    required String adminName,
    required String adminNote,
  }) async {
    try {
      // 1. Update or create seller doc
      final sellerSnap = await _firestore
          .collection(_sellersCollection)
          .where('userId', isEqualTo: sellerId)
          .limit(1)
          .get();

      String sellerDocId = '';
      if (sellerSnap.docs.isNotEmpty) {
        sellerDocId = sellerSnap.docs.first.id;
        await _firestore.collection(_sellersCollection).doc(sellerDocId).update({
          'accountBalance': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final newDoc = _firestore.collection(_sellersCollection).doc();
        sellerDocId = newDoc.id;
        await newDoc.set({
          'userId': sellerId,
          'sellerName': sellerName,
          'idNumber': sellerSearchId,
          'profileId': sellerSearchId,
          'accountBalance': amount.toDouble(),
          'totalSales': 0.0,
          'totalUsersRecharged': 0,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Add credit record
      final creditDoc = _firestore.collection('seller_admin_credits').doc();
      await creditDoc.set({
        'id': creditDoc.id,
        'sellerId': sellerId,
        'sellerDocId': sellerDocId,
        'sellerName': sellerName,
        'sellerSearchId': sellerSearchId,
        'amount': amount,
        'note': adminNote,
        'adminNote': adminNote,
        'adminId': adminId,
        'adminName': adminName,
        'type': 'direct_topup',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Log transaction
      await _logTransaction(
        sellerId: sellerDocId.isNotEmpty ? sellerDocId : sellerId,
        amount: amount.toDouble(),
        type: TransactionType.add,
        description: 'Direct top-up of $amount 💎 by Admin $adminName. Note: $adminNote',
        adminId: adminId,
      );

      return true;
    } catch (e) {
      debugPrint('Error direct crediting seller: $e');
      return false;
    }
  }
}

