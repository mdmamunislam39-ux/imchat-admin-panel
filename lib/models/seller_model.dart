import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SellerModel {
  final String id;
  final String userId;
  final String sellerName;
  final String? profilePicture;
  final String idNumber;
  final String profileId;
  final String phone;
  final String email;
  final double accountBalance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalUsersRecharged;
  final double totalSales;
  final List<String> transactionIds;

  SellerModel({
    required this.id,
    required this.userId,
    required this.sellerName,
    this.profilePicture,
    required this.idNumber,
    required this.profileId,
    this.phone = '',
    this.email = '',
    this.accountBalance = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.totalUsersRecharged = 0,
    this.totalSales = 0.0,
    this.transactionIds = const [],
  });

  factory SellerModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return SellerModel(
        id: doc.id,
        userId: data['userId'] ?? '',
        sellerName: data['sellerName'] ?? '',
        profilePicture: data['profilePicture'],
        idNumber: data['idNumber'] ?? '',
        profileId: data['profileId'] ?? '',
        phone: data['phone'] ?? data['number'] ?? '',
        email: data['email'] ?? data['googleEmail'] ?? '',
        accountBalance: (data['accountBalance'] ?? 0.0).toDouble(),
        isActive: data['isActive'] ?? true,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        totalUsersRecharged: data['totalUsersRecharged'] ?? 0,
        totalSales: (data['totalSales'] ?? 0.0).toDouble(),
        transactionIds: List<String>.from(data['transactionIds'] ?? []),
      );
    } catch (e) {
      debugPrint('Error creating SellerModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'userId': userId,
        'sellerName': sellerName,
        'profilePicture': profilePicture,
        'idNumber': idNumber,
        'profileId': profileId,
        'phone': phone,
        'email': email,
        'accountBalance': accountBalance,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'totalUsersRecharged': totalUsersRecharged,
        'totalSales': totalSales,
        'transactionIds': transactionIds,
      };
    } catch (e) {
      debugPrint('Error converting SellerModel to Firestore: $e');
      rethrow;
    }
  }

  SellerModel copyWith({
    String? id,
    String? userId,
    String? sellerName,
    String? profilePicture,
    String? idNumber,
    String? profileId,
    String? phone,
    String? email,
    double? accountBalance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalUsersRecharged,
    double? totalSales,
    List<String>? transactionIds,
  }) {
    return SellerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sellerName: sellerName ?? this.sellerName,
      profilePicture: profilePicture ?? this.profilePicture,
      idNumber: idNumber ?? this.idNumber,
      profileId: profileId ?? this.profileId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      accountBalance: accountBalance ?? this.accountBalance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalUsersRecharged: totalUsersRecharged ?? this.totalUsersRecharged,
      totalSales: totalSales ?? this.totalSales,
      transactionIds: transactionIds ?? this.transactionIds,
    );
  }

  @override
  String toString() {
    return 'SellerModel(id: $id, sellerName: $sellerName, profileId: $profileId, accountBalance: $accountBalance, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class SellerSalesSummary {
  final String sellerId;
  final double totalDaily;
  final double totalWeekly;
  final double totalMonthly;
  final DateTime lastUpdated;

  SellerSalesSummary({
    required this.sellerId,
    this.totalDaily = 0.0,
    this.totalWeekly = 0.0,
    this.totalMonthly = 0.0,
    required this.lastUpdated,
  });

  factory SellerSalesSummary.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return SellerSalesSummary(
        sellerId: doc.id,
        totalDaily: (data['totalDaily'] ?? 0.0).toDouble(),
        totalWeekly: (data['totalWeekly'] ?? 0.0).toDouble(),
        totalMonthly: (data['totalMonthly'] ?? 0.0).toDouble(),
        lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      );
    } catch (e) {
      debugPrint('Error creating SellerSalesSummary from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'totalDaily': totalDaily,
        'totalWeekly': totalWeekly,
        'totalMonthly': totalMonthly,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
    } catch (e) {
      debugPrint('Error converting SellerSalesSummary to Firestore: $e');
      rethrow;
    }
  }

  SellerSalesSummary copyWith({
    String? sellerId,
    double? totalDaily,
    double? totalWeekly,
    double? totalMonthly,
    DateTime? lastUpdated,
  }) {
    return SellerSalesSummary(
      sellerId: sellerId ?? this.sellerId,
      totalDaily: totalDaily ?? this.totalDaily,
      totalWeekly: totalWeekly ?? this.totalWeekly,
      totalMonthly: totalMonthly ?? this.totalMonthly,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
