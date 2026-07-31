import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum WithdrawalStatus { pending, approved, rejected }

class WithdrawalModel {
  final String id;
  final String userId;
  final String username;
  final String userType;
  final double amount;
  final String accountNumber;
  final String? note;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  WithdrawalModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userType,
    required this.amount,
    required this.accountNumber,
    this.note,
    this.status = WithdrawalStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory WithdrawalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WithdrawalModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userType: data['userType'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      accountNumber: data['accountNumber'] ?? '',
      note: data['note'],
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userType': userType,
      'amount': amount,
      'accountNumber': accountNumber,
      'note': note,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  WithdrawalModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userType,
    double? amount,
    String? accountNumber,
    String? note,
    WithdrawalStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return WithdrawalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      amount: amount ?? this.amount,
      accountNumber: accountNumber ?? this.accountNumber,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.approved:
        return Colors.green;
      case WithdrawalStatus.rejected:
        return Colors.red;
    }
  }
}
