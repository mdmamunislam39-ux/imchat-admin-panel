import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/recharge_wallet_model.dart';

/// Comprehensive service for Recharge Wallet management in Admin Panel
class RechargeWalletService {
  static final RechargeWalletService instance = RechargeWalletService._internal();
  RechargeWalletService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String packagesCollection = 'rechargePackages';
  static const String paymentMethodsCollection = 'paymentMethods';
  static const String ordersCollection = 'rechargeOrders';
  static const String usersCollection = 'Users';
  static const String transactionsCollection = 'wallet_transactions';
  static const String configDocPath = 'app_settings/recharge_config';
  static const String weeklyBenefitsCollection = 'weekly_recharge_benefits';
  static const String incomingTransactionsCollection = 'incoming_transactions';
  static const String autoApproveConfigDocPath = 'app_settings/auto_approve_config';

  // Default initial packages
  static final List<RechargePackageModel> defaultPackages = [
    RechargePackageModel(id: 'pkg_5000', amount: 150, diamondAmount: 5000, sortOrder: 1),
    RechargePackageModel(id: 'pkg_25000', amount: 700, diamondAmount: 25000, sortOrder: 2),
    RechargePackageModel(id: 'pkg_50000', amount: 1400, diamondAmount: 50000, sortOrder: 3),
    RechargePackageModel(id: 'pkg_90000', amount: 2500, diamondAmount: 90000, sortOrder: 4),
    RechargePackageModel(id: 'pkg_200000', amount: 5000, diamondAmount: 200000, sortOrder: 5),
  ];

  // Default initial payment methods
  static final List<PaymentMethodModel> defaultPaymentMethods = [
    PaymentMethodModel(
      id: 'pm_bkash',
      name: 'bKash',
      number: '01609738735',
      type: 'Personal',
      iconUrl: '',
      status: 'ON',
      instructions: "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
    ),
    PaymentMethodModel(
      id: 'pm_nagad',
      name: 'Nagad',
      number: '01609738735',
      type: 'Personal',
      iconUrl: '',
      status: 'ON',
      instructions: "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
    ),
    PaymentMethodModel(
      id: 'pm_rocket',
      name: 'Rocket',
      number: '01609738735',
      type: 'Personal',
      iconUrl: '',
      status: 'ON',
      instructions: "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
    ),
  ];

  // ==========================================
  // PACKAGES MANAGEMENT
  // ==========================================

  Stream<List<RechargePackageModel>> getPackagesStream() {
    return _firestore
        .collection(packagesCollection)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultPackages;
      }
      final list = snapshot.docs
          .map((doc) => RechargePackageModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.sortOrder != b.sortOrder
          ? a.sortOrder.compareTo(b.sortOrder)
          : a.amount.compareTo(b.amount));
      return list;
    });
  }

  Future<void> addPackage({
    required num amount,
    required int diamondAmount,
    int bonusDiamonds = 0,
    int sortOrder = 0,
    String status = 'active',
  }) async {
    final docRef = _firestore.collection(packagesCollection).doc();
    final pkg = RechargePackageModel(
      id: docRef.id,
      amount: amount,
      diamondAmount: diamondAmount,
      bonusDiamonds: bonusDiamonds,
      sortOrder: sortOrder,
      status: status,
    );
    await docRef.set(pkg.toMap());
  }

  Future<void> updatePackage({
    required String packageId,
    required num amount,
    required int diamondAmount,
    int bonusDiamonds = 0,
    required int sortOrder,
    required String status,
  }) async {
    await _firestore.collection(packagesCollection).doc(packageId).set({
      'amount': amount,
      'diamondAmount': diamondAmount,
      'bonusDiamonds': bonusDiamonds,
      'sortOrder': sortOrder,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> togglePackageStatus(String packageId, bool currentlyActive) async {
    await _firestore.collection(packagesCollection).doc(packageId).set({
      'status': currentlyActive ? 'inactive' : 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePackage(String packageId) async {
    await _firestore.collection(packagesCollection).doc(packageId).delete();
  }

  Future<void> seedDefaultPackagesIfEmpty() async {
    try {
      final snap = await _firestore.collection(packagesCollection).limit(1).get();
      if (snap.docs.isEmpty) {
        for (final pkg in defaultPackages) {
          await _firestore.collection(packagesCollection).doc(pkg.id).set(pkg.toMap());
        }
      }
    } catch (e) {
      debugPrint('Error seeding default recharge packages: $e');
    }
  }

  // ==========================================
  // PAYMENT METHODS MANAGEMENT
  // ==========================================

  Stream<List<PaymentMethodModel>> getPaymentMethodsStream() {
    return _firestore
        .collection(paymentMethodsCollection)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultPaymentMethods;
      }
      return snapshot.docs
          .map((doc) => PaymentMethodModel.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> addPaymentMethod({
    required String name,
    required String number,
    String type = 'Personal',
    String iconUrl = '',
    String status = 'ON',
    String instructions = "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
  }) async {
    final docRef = _firestore.collection(paymentMethodsCollection).doc();
    final model = PaymentMethodModel(
      id: docRef.id,
      name: name.trim(),
      number: number.trim(),
      type: type.trim(),
      iconUrl: iconUrl.trim(),
      status: status.toUpperCase(),
      instructions: instructions.trim(),
    );
    await docRef.set(model.toMap());
  }

  Future<void> updatePaymentMethod({
    required String methodId,
    required String name,
    required String number,
    required String type,
    String? iconUrl,
    String? status,
    String? instructions,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'number': number.trim(),
      'type': type.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (iconUrl != null) data['iconUrl'] = iconUrl.trim();
    if (status != null) data['status'] = status.toUpperCase();
    if (instructions != null) data['instructions'] = instructions.trim();

    await _firestore.collection(paymentMethodsCollection).doc(methodId).set(data, SetOptions(merge: true));
  }

  Future<void> togglePaymentMethodStatus(String methodId, bool currentlyOn) async {
    await _firestore.collection(paymentMethodsCollection).doc(methodId).set({
      'status': currentlyOn ? 'OFF' : 'ON',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePaymentMethod(String methodId) async {
    await _firestore.collection(paymentMethodsCollection).doc(methodId).delete();
  }

  Future<void> seedDefaultPaymentMethodsIfEmpty() async {
    try {
      final snap = await _firestore.collection(paymentMethodsCollection).limit(1).get();
      if (snap.docs.isEmpty) {
        for (final method in defaultPaymentMethods) {
          await _firestore.collection(paymentMethodsCollection).doc(method.id).set(method.toMap());
        }
      }
    } catch (e) {
      debugPrint('Error seeding default payment methods: $e');
    }
  }

  // ==========================================
  // RECHARGE ORDERS & TRXID MANAGEMENT
  // ==========================================

  Stream<List<RechargeOrderModel>> getOrdersStream({String? statusFilter}) {
    Query query = _firestore.collection(ordersCollection);
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter.toLowerCase() != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RechargeOrderModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2000);
        final dateB = b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
      return list;
    });
  }

  Stream<int> getPendingOrdersCountStream() {
    return _firestore
        .collection(ordersCollection)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Approve order and atomically credit user diamonds
  Future<bool> approveOrder({
    required String orderId,
    required String adminId,
  }) async {
    final orderRef = _firestore.collection(ordersCollection).doc(orderId);

    return await _firestore.runTransaction<bool>((transaction) async {
      final orderSnap = await transaction.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Recharge order not found.');
      }

      final orderData = orderSnap.data() as Map<String, dynamic>;
      final currentStatus = (orderData['status'] ?? '').toString();

      if (currentStatus.toLowerCase() == 'approved') {
        throw Exception('This recharge order has already been approved.');
      }
      if (currentStatus.toLowerCase() == 'rejected') {
        throw Exception('Cannot approve an already rejected order.');
      }

      final userId = orderData['userId'] as String? ?? '';
      final diamondAmount = (orderData['diamondAmount'] as num?)?.toInt() ?? 0;
      final bonusDiamonds = (orderData['bonusDiamonds'] as num?)?.toInt() ?? 0;
      final totalCreditDiamonds = diamondAmount + bonusDiamonds;
      final bdtAmount = orderData['amount'] ?? 0;
      final paymentMethod = orderData['paymentMethod'] ?? 'Online';
      final trxId = orderData['transactionId'] ?? '';

      if (userId.isEmpty || totalCreditDiamonds <= 0) {
        throw Exception('Invalid order details or user ID missing.');
      }

      final userRef = _firestore.collection(usersCollection).doc(userId);
      final userSnap = await transaction.get(userRef);
      if (!userSnap.exists) {
        throw Exception('User account not found: $userId');
      }

      // 1. Update Order Status
      transaction.update(orderRef, {
        'status': 'Approved',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': adminId,
      });

      // 2. Increment User Diamond Balance with Total Diamonds (Base + Bonus)
      transaction.update(userRef, {
        'diamonds': FieldValue.increment(totalCreditDiamonds),
        'totalDiamonds': FieldValue.increment(totalCreditDiamonds),
        'monthlyRechargeAmount': FieldValue.increment(totalCreditDiamonds),
        'weeklyRechargeAmount': FieldValue.increment(totalCreditDiamonds),
        'lastRechargeWeek': '${DateTime.now().year}_W${((DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).difference(DateTime(DateTime.now().year, 1, 1)).inDays) / 7).ceil()}',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3. Log to wallet_transactions
      final txId = 'tx_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final txRef = _firestore.collection(transactionsCollection).doc(txId);
      final txDesc = bonusDiamonds > 0
          ? 'Online Diamond Recharge (+$totalCreditDiamonds Diamonds [+$diamondAmount Base +$bonusDiamonds Bonus] via $paymentMethod)'
          : 'Online Diamond Recharge (+$diamondAmount Diamonds via $paymentMethod)';
      transaction.set(txRef, {
        'id': txId,
        'userId': userId,
        'type': 'online_recharge',
        'diamonds': totalCreditDiamonds,
        'baseDiamonds': diamondAmount,
        'bonusDiamonds': bonusDiamonds,
        'beans': 0,
        'amountBdt': bdtAmount,
        'paymentMethod': paymentMethod,
        'transactionId': trxId,
        'orderId': orderId,
        'description': txDesc,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  /// Reject order with admin reason
  Future<void> rejectOrder({
    required String orderId,
    required String adminId,
    required String reason,
  }) async {
    final orderRef = _firestore.collection(ordersCollection).doc(orderId);
    final snap = await orderRef.get();
    if (!snap.exists) {
      throw Exception('Order not found.');
    }
    final status = (snap.data()?['status'] ?? '').toString();
    if (status.toLowerCase() == 'approved') {
      throw Exception('Cannot reject an approved order.');
    }

    await orderRef.update({
      'status': 'Rejected',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': adminId,
      'rejectionReason': reason.trim(),
    });
  }

  // ==========================================
  // GLOBAL WALLET CONFIG
  // ==========================================

  Stream<RechargeConfigModel> getConfigStream() {
    return _firestore.doc(configDocPath).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return RechargeConfigModel();
      }
      return RechargeConfigModel.fromMap(snapshot.data()!);
    });
  }

  Future<void> updateConfig({
    required bool isOnlineRechargeEnabled,
    required String noticeText,
    required String supportContact,
    required num minAmount,
    required num maxAmount,
  }) async {
    await _firestore.doc(configDocPath).set({
      'isOnlineRechargeEnabled': isOnlineRechargeEnabled,
      'noticeText': noticeText.trim(),
      'supportContact': supportContact.trim(),
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // WEEKLY RECHARGE BENEFITS MANAGEMENT
  // ==========================================

  Stream<List<WeeklyRechargeBenefitModel>> getWeeklyBenefitsStream() {
    return _firestore
        .collection(weeklyBenefitsCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return WeeklyRechargeBenefitModel.fromMap(doc.data(), doc.id);
      }).toList();
      list.sort((a, b) {
        if (a.targetDiamonds != b.targetDiamonds) {
          return a.targetDiamonds.compareTo(b.targetDiamonds);
        }
        return a.order.compareTo(b.order);
      });
      return list;
    });
  }

  Future<void> addWeeklyBenefit({
    required String tierName,
    required int targetDiamonds,
    required String itemId,
    required String itemName,
    required String itemIcon,
    required String itemType,
    required int validityDays,
    int bonusDiamonds = 0,
    DateTime? endDate,
    required int order,
    bool isActive = true,
  }) async {
    final docId = 'wb_${DateTime.now().millisecondsSinceEpoch}';
    await _firestore.collection(weeklyBenefitsCollection).doc(docId).set({
      'tierName': tierName.trim(),
      'targetDiamonds': targetDiamonds,
      'itemId': itemId.trim(),
      'itemName': itemName.trim(),
      'itemIcon': itemIcon.trim(),
      'itemType': itemType.trim(),
      'validityDays': validityDays,
      'bonusDiamonds': bonusDiamonds,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'order': order,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateWeeklyBenefit({
    required String id,
    required String tierName,
    required int targetDiamonds,
    required String itemId,
    required String itemName,
    required String itemIcon,
    required String itemType,
    required int validityDays,
    int bonusDiamonds = 0,
    DateTime? endDate,
    required int order,
    required bool isActive,
  }) async {
    await _firestore.collection(weeklyBenefitsCollection).doc(id).set({
      'tierName': tierName.trim(),
      'targetDiamonds': targetDiamonds,
      'itemId': itemId.trim(),
      'itemName': itemName.trim(),
      'itemIcon': itemIcon.trim(),
      'itemType': itemType.trim(),
      'validityDays': validityDays,
      'bonusDiamonds': bonusDiamonds,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      'order': order,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleWeeklyBenefitStatus(String id, bool currentlyActive) async {
    await _firestore.collection(weeklyBenefitsCollection).doc(id).set({
      'isActive': !currentlyActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteWeeklyBenefit(String id) async {
    await _firestore.collection(weeklyBenefitsCollection).doc(id).delete();
  }

  // ==========================================
  // AUTO PAYMENT APPROVAL & SMS WEBHOOK SERVICE
  // ==========================================

  Stream<AutoApproveConfigModel> getAutoApproveConfigStream() {
    return _firestore.doc(autoApproveConfigDocPath).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return AutoApproveConfigModel();
      }
      return AutoApproveConfigModel.fromMap(snap.data()!);
    });
  }

  Future<void> updateAutoApproveConfig({
    required bool isAutoApproveEnabled,
    String? webhookSecret,
    String? webhookUrl,
    int? autoMatchWindowHours,
  }) async {
    final Map<String, dynamic> data = {
      'isAutoApproveEnabled': isAutoApproveEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (webhookSecret != null && webhookSecret.trim().isNotEmpty) {
      data['webhookSecret'] = webhookSecret.trim();
    }
    if (webhookUrl != null && webhookUrl.trim().isNotEmpty) {
      data['webhookUrl'] = webhookUrl.trim();
    }
    if (autoMatchWindowHours != null) {
      data['autoMatchWindowHours'] = autoMatchWindowHours;
    }

    await _firestore.doc(autoApproveConfigDocPath).set(data, SetOptions(merge: true));
  }

  Future<String> generateNewWebhookSecret() async {
    final newSecret = 'imchat_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    await _firestore.doc(autoApproveConfigDocPath).set({
      'webhookSecret': newSecret,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return newSecret;
  }

  Stream<List<IncomingTransactionModel>> getIncomingTransactionsStream({
    String? statusFilter,
    String? searchQuery,
  }) {
    Query query = _firestore.collection(incomingTransactionsCollection);

    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter.toLowerCase() != 'all') {
      if (statusFilter.toLowerCase() == 'claimed' ||
          statusFilter.toLowerCase() == 'auto_approved') {
        query = query.where('status', whereIn: ['claimed', 'auto_approved']);
      } else {
        query = query.where('status', isEqualTo: statusFilter);
      }
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => IncomingTransactionModel.fromFirestore(doc))
          .toList();

      list.sort((a, b) {
        final dateA = a.createdAt ?? DateTime(2000);
        final dateB = b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toUpperCase();
        return list.where((item) {
          final matchesTrx = item.trxId.contains(q);
          final matchesSender = item.sender.toUpperCase().contains(q);
          final matchesUser = (item.claimedByUserId ?? '').toUpperCase().contains(q) ||
              (item.claimedByUserName ?? '').toUpperCase().contains(q);
          final matchesOrder = (item.claimedOrderId ?? '').toUpperCase().contains(q);
          return matchesTrx || matchesSender || matchesUser || matchesOrder;
        }).toList();
      }

      return list;
    });
  }

  Future<void> deleteIncomingTransaction(String trxId) async {
    await _firestore.collection(incomingTransactionsCollection).doc(trxId.toUpperCase().trim()).delete();
  }

  /// Parse bKash/Nagad/Rocket SMS text to extract TrxID and Amount
  Map<String, dynamic> parseSmsText(String rawMessage, [String fallbackSender = 'SMS']) {
    final text = rawMessage.trim();

    // 1. Detect Operator
    String detectedSender = fallbackSender;
    final lower = text.toLowerCase();
    if (lower.contains('bkash') || lower.contains('বিকাশ')) {
      detectedSender = 'bKash';
    } else if (lower.contains('nagad') || lower.contains('নগদ')) {
      detectedSender = 'Nagad';
    } else if (lower.contains('rocket') || lower.contains('রকেট')) {
      detectedSender = 'Rocket';
    } else if (lower.contains('upay') || lower.contains('উপায়')) {
      detectedSender = 'Upay';
    }

    // 2. Extract TrxID / TxnID
    // Examples: "TrxID 9ABC1234", "TxnID: 7XYZ5678", "TrxID: BCL456", "TxID 123"
    final trxRegex = RegExp(
      r'(?:TrxID|TxnID|TxID|Transaction ID|TID|ট্রানজেকশন আইডি)[:\s]+([A-Za-z0-9]+)',
      caseSensitive: false,
    );
    final trxMatch = trxRegex.firstMatch(text);
    final trxId = trxMatch?.group(1)?.trim().toUpperCase();

    // 3. Extract Amount
    // Examples: "Tk 500.00", "Tk. 500", "BDT 1,500.00", "টাকা ৫০০"
    final amountRegex = RegExp(
      r'(?:Tk\.?|BDT|টাকা|Amount:?\s*Tk\.?)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );
    final amountMatch = amountRegex.firstMatch(text);
    num? parsedAmount;
    if (amountMatch != null) {
      final rawNum = amountMatch.group(1)?.replaceAll(',', '');
      if (rawNum != null) {
        parsedAmount = num.tryParse(rawNum);
      }
    }

    return {
      'trxId': trxId,
      'amount': parsedAmount,
      'sender': detectedSender,
    };
  }

  /// Process incoming SMS message (called by Webhook or in-panel simulation)
  Future<Map<String, dynamic>> processIncomingSms({
    required String rawMessage,
    required String sender,
    String? secretKey,
  }) async {
    final parsed = parseSmsText(rawMessage, sender);
    final trxId = parsed['trxId'] as String?;
    final amount = parsed['amount'] as num?;
    final detectedSender = (parsed['sender'] as String?) ?? sender;

    if (trxId == null || trxId.isEmpty) {
      return {
        'success': false,
        'message': 'No Transaction ID (TrxID) found in the provided SMS text.',
      };
    }

    if (amount == null || amount <= 0) {
      return {
        'success': false,
        'trxId': trxId,
        'message': 'No valid amount found in the provided SMS text.',
      };
    }

    final upperTrxId = trxId.toUpperCase().trim();
    final trxRef = _firestore.collection(incomingTransactionsCollection).doc(upperTrxId);
    final existingSnap = await trxRef.get();

    // Fetch Auto Approve Settings
    final configSnap = await _firestore.doc(autoApproveConfigDocPath).get();
    final isAutoApproveEnabled = configSnap.exists
        ? (configSnap.data()?['isAutoApproveEnabled'] ?? true)
        : true;

    // 1. Save or Update Incoming Transaction Document
    if (!existingSnap.exists) {
      await trxRef.set({
        'trxId': upperTrxId,
        'amount': amount,
        'sender': detectedSender,
        'rawMessage': rawMessage.trim(),
        'status': 'unclaimed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Auto-Approval Matching: Look for a matching Pending Recharge Order
    bool autoApproved = false;
    String? matchedOrderId;
    String? matchedUserId;
    String? matchedUserName;
    int? creditedDiamonds;

    if (isAutoApproveEnabled) {
      final pendingOrdersQuery = await _firestore
          .collection(ordersCollection)
          .where('transactionId', isEqualTo: upperTrxId)
          .where('status', isEqualTo: 'Pending')
          .limit(1)
          .get();

      if (pendingOrdersQuery.docs.isNotEmpty) {
        final orderDoc = pendingOrdersQuery.docs.first;
        final orderData = orderDoc.data();
        final orderAmount = (orderData['amount'] as num?) ?? 0;

        // Check amount match with small tolerance for float precision
        if ((orderAmount - amount).abs() < 1) {
          try {
            await approveOrder(
              orderId: orderDoc.id,
              adminId: 'SYSTEM_AUTO_APPROVE',
            );

            matchedOrderId = orderDoc.id;
            matchedUserId = orderData['userId']?.toString();
            matchedUserName = orderData['userName']?.toString();
            final diamondAmount = (orderData['diamondAmount'] as num?)?.toInt() ?? 0;
            final bonusDiamonds = (orderData['bonusDiamonds'] as num?)?.toInt() ?? 0;
            creditedDiamonds = diamondAmount + bonusDiamonds;

            // Mark transaction as claimed & auto_approved
            await trxRef.set({
              'status': 'auto_approved',
              'claimedByUserId': matchedUserId,
              'claimedByUserName': matchedUserName,
              'claimedOrderId': matchedOrderId,
              'claimedDiamonds': creditedDiamonds,
              'claimedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            autoApproved = true;
          } catch (e) {
            debugPrint('Auto approve error for order ${orderDoc.id}: $e');
          }
        }
      }
    }

    return {
      'success': true,
      'trxId': upperTrxId,
      'amount': amount,
      'sender': detectedSender,
      'autoApproved': autoApproved,
      'matchedOrderId': matchedOrderId,
      'matchedUserId': matchedUserId,
      'matchedUserName': matchedUserName,
      'creditedDiamonds': creditedDiamonds,
      'message': autoApproved
          ? 'Matched & Auto-Approved! Order #$matchedOrderId credited with $creditedDiamonds diamonds.'
          : 'Transaction recorded successfully (Unclaimed - Waiting for user recharge order).',
    };
  }

  /// Manually link an unclaimed transaction to a pending order and approve it
  Future<bool> manualMatchTransaction({
    required String trxId,
    required String orderId,
    required String adminId,
  }) async {
    final upperTrxId = trxId.toUpperCase().trim();
    final trxRef = _firestore.collection(incomingTransactionsCollection).doc(upperTrxId);
    final trxSnap = await trxRef.get();
    if (!trxSnap.exists) {
      throw Exception('Incoming transaction $upperTrxId not found.');
    }

    final orderRef = _firestore.collection(ordersCollection).doc(orderId);
    final orderSnap = await orderRef.get();
    if (!orderSnap.exists) {
      throw Exception('Recharge order $orderId not found.');
    }

    final orderData = orderSnap.data()!;
    final userId = orderData['userId']?.toString();
    final userName = orderData['userName']?.toString();
    final diamondAmount = (orderData['diamondAmount'] as num?)?.toInt() ?? 0;
    final bonusDiamonds = (orderData['bonusDiamonds'] as num?)?.toInt() ?? 0;

    // Approve the order
    await approveOrder(orderId: orderId, adminId: adminId);

    // Update the incoming transaction
    await trxRef.set({
      'status': 'claimed',
      'claimedByUserId': userId,
      'claimedByUserName': userName,
      'claimedOrderId': orderId,
      'claimedDiamonds': diamondAmount + bonusDiamonds,
      'claimedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return true;
  }
}

