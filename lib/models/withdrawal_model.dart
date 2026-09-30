import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum WithdrawalStatus {
  pending, // Waiting for seller payment
  pendingAdminApproval, // Seller uploaded proof screenshot, waiting for admin approval
  approved, // Admin verified screenshot and approved (+90% diamonds to seller)
  rejected, // Admin rejected (beans refunded to user)
}

class WithdrawalModel {
  final String id;
  final String userId;
  final String username;
  final String? userSearchId;
  final String userType;
  final double amount;
  final int beanAmount;
  final double usdAmount;
  final String accountNumber;
  final String? accountName;
  final String? withdrawalBkash;
  final String? withdrawalName;
  final String? sellerId;
  final String? sellerName;
  final String? sellerSearchId;
  final String? note;
  final String? sellerNote;
  final List<String> paymentScreenshots;
  final bool proofSubmitted;
  final DateTime? proofSubmittedAt;
  final int diamondReward;
  final int sellerDiamondPercent;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userSearchId,
    required this.userType,
    required this.amount,
    int? beanAmount,
    this.usdAmount = 0.0,
    required this.accountNumber,
    this.accountName,
    this.withdrawalBkash,
    this.withdrawalName,
    this.sellerId,
    this.sellerName,
    this.sellerSearchId,
    this.note,
    this.sellerNote,
    this.paymentScreenshots = const [],
    this.proofSubmitted = false,
    this.proofSubmittedAt,
    int? diamondReward,
    this.sellerDiamondPercent = 90,
    this.status = WithdrawalStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  })  : beanAmount = beanAmount ?? amount.toInt(),
        diamondReward = diamondReward ??
            ((amount > 0 ? amount : (beanAmount?.toDouble() ?? 0.0)) *
                    (sellerDiamondPercent / 100.0))
                .round();

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final id = doc.id;

    final rawAmount = (data['amount'] ?? data['beanAmount'] ?? 0.0);
    final double amount = rawAmount is num ? rawAmount.toDouble() : 0.0;
    final int beanAmount = (data['beanAmount'] is num)
        ? (data['beanAmount'] as num).toInt()
        : amount.toInt();
    final double usdAmount = (data['usdAmount'] is num)
        ? (data['usdAmount'] as num).toDouble()
        : 0.0;

    final rawScreenshots = data['paymentScreenshots'] as List?;
    final List<String> paymentScreenshots = rawScreenshots != null
        ? rawScreenshots.map((e) => e.toString()).toList()
        : (data['screenshot'] != null ? [data['screenshot'].toString()] : []);

    final bool proofSubmitted = data['proofSubmitted'] == true ||
        paymentScreenshots.isNotEmpty ||
        (data['status']?.toString().toLowerCase() == 'pending_admin_approval');

    // Parse status
    final rawStatus = (data['status']?.toString().toLowerCase() ?? 'pending');
    WithdrawalStatus status;
    if (rawStatus == 'approved' || rawStatus == 'completed') {
      status = WithdrawalStatus.approved;
    } else if (rawStatus == 'rejected') {
      status = WithdrawalStatus.rejected;
    } else if (rawStatus == 'pending_admin_approval' ||
        rawStatus == 'pendingadminapproval' ||
        proofSubmitted) {
      status = WithdrawalStatus.pendingAdminApproval;
    } else {
      status = WithdrawalStatus.pending;
    }

    DateTime createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      createdAt = DateTime.now();
    }

    DateTime? reviewedAt;
    if (data['reviewedAt'] is Timestamp) {
      reviewedAt = (data['reviewedAt'] as Timestamp).toDate();
    }

    DateTime? proofSubmittedAt;
    if (data['proofSubmittedAt'] is Timestamp) {
      proofSubmittedAt = (data['proofSubmittedAt'] as Timestamp).toDate();
    }

    final int sellerDiamondPercent =
        (data['sellerDiamondPercent'] as num?)?.toInt() ?? 90;

    final int calculatedReward = (data['diamondReward'] is num)
        ? (data['diamondReward'] as num).toInt()
        : (beanAmount * (sellerDiamondPercent / 100.0)).round();

    final accountNumber = data['withdrawalBkash']?.toString() ??
        data['accountNumber']?.toString() ??
        '';

    final username = data['withdrawalName']?.toString() ??
        data['accountName']?.toString() ??
        data['username']?.toString() ??
        'Unknown User';

    return WithdrawalModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      username: username,
      userSearchId: data['userSearchId']?.toString() ??
          data['searchId']?.toString() ??
          data['profileId']?.toString(),
      userType: data['userType']?.toString() ?? 'User',
      amount: amount > 0 ? amount : beanAmount.toDouble(),
      beanAmount: beanAmount,
      usdAmount: usdAmount,
      accountNumber: accountNumber,
      accountName: data['accountName']?.toString() ?? data['withdrawalName']?.toString(),
      withdrawalBkash: data['withdrawalBkash']?.toString() ?? accountNumber,
      withdrawalName: data['withdrawalName']?.toString() ?? username,
      sellerId: data['sellerId']?.toString() ?? data['dealerId']?.toString(),
      sellerName: data['sellerName']?.toString() ?? data['dealerName']?.toString(),
      sellerSearchId: data['sellerSearchId']?.toString() ?? data['dealerSearchId']?.toString(),
      note: data['note']?.toString(),
      sellerNote: data['sellerNote']?.toString() ?? data['transactionId']?.toString() ?? data['trxId']?.toString(),
      paymentScreenshots: paymentScreenshots,
      proofSubmitted: proofSubmitted,
      proofSubmittedAt: proofSubmittedAt,
      diamondReward: calculatedReward,
      sellerDiamondPercent: sellerDiamondPercent,
      status: status,
      createdAt: createdAt,
      reviewedAt: reviewedAt,
      reviewedBy: data['reviewedBy']?.toString(),
      rejectionReason: data['rejectionReason']?.toString() ?? data['rejectedReason']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userSearchId': userSearchId,
      'userType': userType,
      'amount': amount,
      'beanAmount': beanAmount,
      'usdAmount': usdAmount,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'withdrawalBkash': withdrawalBkash ?? accountNumber,
      'withdrawalName': withdrawalName ?? username,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerSearchId': sellerSearchId,
      'note': note,
      'sellerNote': sellerNote,
      'paymentScreenshots': paymentScreenshots,
      'proofSubmitted': proofSubmitted,
      'proofSubmittedAt': proofSubmittedAt != null ? Timestamp.fromDate(proofSubmittedAt!) : null,
      'diamondReward': diamondReward,
      'sellerDiamondPercent': sellerDiamondPercent,
      'status': statusString,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  String get statusString {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'pending';
      case WithdrawalStatus.pendingAdminApproval:
        return 'pending_admin_approval';
      case WithdrawalStatus.approved:
        return 'approved';
      case WithdrawalStatus.rejected:
        return 'rejected';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Waiting Seller Payment';
      case WithdrawalStatus.pendingAdminApproval:
        return 'Proof Submitted (Review)';
      case WithdrawalStatus.approved:
        return 'Approved (+90% 💎)';
      case WithdrawalStatus.rejected:
        return 'Rejected (Refunded)';
    }
  }

  Color get statusColor {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.pendingAdminApproval:
        return const Color(0xFF00B0FF);
      case WithdrawalStatus.approved:
        return const Color(0xFF00E676);
      case WithdrawalStatus.rejected:
        return const Color(0xFFFF5252);
    }
  }
}

