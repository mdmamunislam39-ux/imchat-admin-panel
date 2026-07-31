import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType {
  add,    // Admin adds balance to seller
  minus,  // Admin deducts balance from seller
  sell,   // Seller recharges user
  recharge, // User gets recharged by seller
}

class TransactionModel {
  final String id;
  final String sellerId;
  final String? userId; // null for admin transactions
  final double amount;
  final TransactionType type;
  final String description;
  final DateTime createdAt;
  final String? adminId; // for admin transactions
  final String? userProfileId; // for user recharge transactions
  final String? userPhoneNumber; // for user recharge transactions

  TransactionModel({
    required this.id,
    required this.sellerId,
    this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.adminId,
    this.userProfileId,
    this.userPhoneNumber,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return TransactionModel(
        id: doc.id,
        sellerId: data['sellerId'] ?? '',
        userId: data['userId'],
        amount: (data['amount'] ?? 0.0).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.toString() == 'TransactionType.${data['type']}',
          orElse: () => TransactionType.sell,
        ),
        description: data['description'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        adminId: data['adminId'],
        userProfileId: data['userProfileId'],
        userPhoneNumber: data['userPhoneNumber'],
      );
    } catch (e) {
      debugPrint('Error creating TransactionModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'sellerId': sellerId,
        'userId': userId,
        'amount': amount,
        'type': type.toString().split('.').last,
        'description': description,
        'createdAt': Timestamp.fromDate(createdAt),
        'adminId': adminId,
        'userProfileId': userProfileId,
        'userPhoneNumber': userPhoneNumber,
      };
    } catch (e) {
      debugPrint('Error converting TransactionModel to Firestore: $e');
      rethrow;
    }
  }

  TransactionModel copyWith({
    String? id,
    String? sellerId,
    String? userId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? createdAt,
    String? adminId,
    String? userProfileId,
    String? userPhoneNumber,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      userProfileId: userProfileId ?? this.userProfileId,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.add:
        return 'Balance Added';
      case TransactionType.minus:
        return 'Balance Deducted';
      case TransactionType.sell:
        return 'User Recharge';
      case TransactionType.recharge:
        return 'Received Recharge';
    }
  }

  String get typeIcon {
    switch (type) {
      case TransactionType.add:
        return '➕';
      case TransactionType.minus:
        return '➖';
      case TransactionType.sell:
        return '💎';
      case TransactionType.recharge:
        return '💰';
    }
  }

  Color get typeColor {
    switch (type) {
      case TransactionType.add:
        return Colors.green;
      case TransactionType.minus:
        return Colors.red;
      case TransactionType.sell:
        return Colors.blue;
      case TransactionType.recharge:
        return Colors.purple;
    }
  }

  @override
  String toString() {
    return 'TransactionModel(id: $id, sellerId: $sellerId, amount: $amount, type: $type, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class RechargeHistoryModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String userId;
  final String userProfileId;
  final String userPhoneNumber;
  final String userName;
  final double amount;
  final DateTime createdAt;
  final String status; // 'completed', 'failed', 'pending'

  RechargeHistoryModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.userId,
    required this.userProfileId,
    required this.userPhoneNumber,
    required this.userName,
    required this.amount,
    required this.createdAt,
    this.status = 'completed',
  });

  factory RechargeHistoryModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return RechargeHistoryModel(
        id: doc.id,
        sellerId: data['sellerId'] ?? '',
        sellerName: data['sellerName'] ?? '',
        userId: data['userId'] ?? '',
        userProfileId: data['userProfileId'] ?? '',
        userPhoneNumber: data['userPhoneNumber'] ?? '',
        userName: data['userName'] ?? '',
        amount: (data['amount'] ?? 0.0).toDouble(),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        status: data['status'] ?? 'completed',
      );
    } catch (e) {
      debugPrint('Error creating RechargeHistoryModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'userId': userId,
        'userProfileId': userProfileId,
        'userPhoneNumber': userPhoneNumber,
        'userName': userName,
        'amount': amount,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };
    } catch (e) {
      debugPrint('Error converting RechargeHistoryModel to Firestore: $e');
      rethrow;
    }
  }

  RechargeHistoryModel copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? userId,
    String? userProfileId,
    String? userPhoneNumber,
    String? userName,
    double? amount,
    DateTime? createdAt,
    String? status,
  }) {
    return RechargeHistoryModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      userId: userId ?? this.userId,
      userProfileId: userProfileId ?? this.userProfileId,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userName: userName ?? this.userName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'RechargeHistoryModel(id: $id, sellerId: $sellerId, userName: $userName, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RechargeHistoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
