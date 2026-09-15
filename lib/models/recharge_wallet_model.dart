import 'package:cloud_firestore/cloud_firestore.dart';

/// Diamond Recharge Package Model for App & Admin
class RechargePackageModel {
  final String id;
  final num amount; // In BDT
  final int diamondAmount; // Base Diamonds
  final int bonusDiamonds; // Extra Bonus Diamonds
  final String status; // 'active' or 'inactive'
  final int sortOrder;

  RechargePackageModel({
    required this.id,
    required this.amount,
    required this.diamondAmount,
    this.bonusDiamonds = 0,
    this.status = 'active',
    this.sortOrder = 0,
  });

  bool get isActive => status.toLowerCase() == 'active';
  int get totalDiamonds => diamondAmount + bonusDiamonds;
  double get bonusPercent => diamondAmount > 0 ? (bonusDiamonds / diamondAmount) * 100 : 0;
  String get bonusPercentText => bonusPercent > 0 ? '+${bonusPercent.toStringAsFixed(bonusPercent % 1 == 0 ? 0 : 1)}%' : '';

  factory RechargePackageModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return RechargePackageModel.fromMap(data, doc.id);
  }

  factory RechargePackageModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return RechargePackageModel(
      id: id ?? data['id'] ?? '',
      amount: data['amount'] ?? 0,
      diamondAmount: (data['diamondAmount'] as num?)?.toInt() ?? 0,
      bonusDiamonds: (data['bonusDiamonds'] as num?)?.toInt() ?? 0,
      status: data['status'] ?? 'active',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'diamondAmount': diamondAmount,
      'bonusDiamonds': bonusDiamonds,
      'status': status,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Payment Method Channel Model (e.g. bKash, Nagad, Rocket, Bank)
class PaymentMethodModel {
  final String id;
  final String name;
  final String number;
  final String iconUrl;
  final String status; // 'ON' or 'OFF'
  final String instructions;
  final String type; // 'Personal', 'Agent', 'Merchant'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    required this.number,
    this.iconUrl = '',
    this.status = 'ON',
    this.instructions = "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
    this.type = 'Personal',
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ON';

  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return PaymentMethodModel.fromMap(data, doc.id);
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return PaymentMethodModel(
      id: id ?? data['id'] ?? '',
      name: data['name'] ?? '',
      number: data['number'] ?? '',
      iconUrl: data['iconUrl'] ?? data['icon'] ?? '',
      status: (data['status'] ?? 'ON').toString().toUpperCase(),
      instructions: data['instructions'] ?? "'সেন্ড মানি' দিয়ে পরিশোধ করুন",
      type: data['type'] ?? 'Personal',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'iconUrl': iconUrl,
      'status': status,
      'instructions': instructions,
      'type': type,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Recharge Order / TrxID Verification Model
class RechargeOrderModel {
  final String orderId;
  final String userId;
  final String userName;
  final String userPhoto;
  final String searchId;
  final String userPhone;
  final num amount; // BDT
  final int diamondAmount;
  final int bonusDiamonds;
  final String paymentMethod;
  final String paymentNumber;
  final String transactionId; // TrxID
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;

  RechargeOrderModel({
    required this.orderId,
    required this.userId,
    this.userName = '',
    this.userPhoto = '',
    this.searchId = '',
    this.userPhone = '',
    required this.amount,
    required this.diamondAmount,
    this.bonusDiamonds = 0,
    required this.paymentMethod,
    required this.paymentNumber,
    required this.transactionId,
    this.status = 'Pending',
    this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  int get totalDiamonds => diamondAmount + bonusDiamonds;

  factory RechargeOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return RechargeOrderModel.fromMap(data, doc.id);
  }

  factory RechargeOrderModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return RechargeOrderModel(
      orderId: id ?? data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhoto: data['userPhoto'] ?? '',
      searchId: (data['searchId'] ?? '').toString(),
      userPhone: (data['userPhone'] ?? data['phone'] ?? data['number'] ?? '').toString(),
      amount: data['amount'] ?? 0,
      diamondAmount: (data['diamondAmount'] as num?)?.toInt() ?? 0,
      bonusDiamonds: (data['bonusDiamonds'] as num?)?.toInt() ?? 0,
      paymentMethod: data['paymentMethod'] ?? '',
      paymentNumber: data['paymentNumber'] ?? '',
      transactionId: (data['transactionId'] ?? '').toString().trim(),
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      verifiedAt: (data['verifiedAt'] is Timestamp)
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      verifiedBy: data['verifiedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'searchId': searchId,
      'userPhone': userPhone,
      'amount': amount,
      'diamondAmount': diamondAmount,
      'bonusDiamonds': bonusDiamonds,
      'paymentMethod': paymentMethod,
      'paymentNumber': paymentNumber,
      'transactionId': transactionId,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'verifiedAt':
          verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
    };
  }
}

/// Global Recharge Wallet Config Model
class RechargeConfigModel {
  final bool isOnlineRechargeEnabled;
  final String noticeText;
  final String supportContact;
  final num minAmount;
  final num maxAmount;

  RechargeConfigModel({
    this.isOnlineRechargeEnabled = true,
    this.noticeText = "পেমেন্ট সম্পন্ন করে সঠিক Transaction ID (TrxID) প্রদান করুন। ১-৫ মিনিটের মধ্যে আপনার একাউন্টে ডায়মন্ড যুক্ত হবে।",
    this.supportContact = "+8801609738735",
    this.minAmount = 50,
    this.maxAmount = 50000,
  });

  factory RechargeConfigModel.fromMap(Map<String, dynamic> data) {
    return RechargeConfigModel(
      isOnlineRechargeEnabled: data['isOnlineRechargeEnabled'] ?? true,
      noticeText: data['noticeText'] ??
          "পেমেন্ট সম্পন্ন করে সঠিক Transaction ID (TrxID) প্রদান করুন। ১-৫ মিনিটের মধ্যে আপনার একাউন্টে ডায়মন্ড যুক্ত হবে।",
      supportContact: data['supportContact'] ?? "+8801609738735",
      minAmount: data['minAmount'] ?? 50,
      maxAmount: data['maxAmount'] ?? 50000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOnlineRechargeEnabled': isOnlineRechargeEnabled,
      'noticeText': noticeText,
      'supportContact': supportContact,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Model representing a Weekly Recharge Benefit Tier
class WeeklyRechargeBenefitModel {
  final String id;
  final String tierName;
  final int targetDiamonds;
  final String itemId;
  final String itemName;
  final String itemIcon;
  final String itemType;
  final int validityDays;
  final int bonusDiamonds;
  final DateTime? endDate;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WeeklyRechargeBenefitModel({
    required this.id,
    this.tierName = '',
    required this.targetDiamonds,
    required this.itemId,
    required this.itemName,
    this.itemIcon = '',
    this.itemType = 'avatarFrame',
    this.validityDays = 7,
    this.bonusDiamonds = 0,
    this.endDate,
    this.order = 1,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WeeklyRechargeBenefitModel.fromMap(Map<String, dynamic> data, String id) {
    return WeeklyRechargeBenefitModel(
      id: id,
      tierName: data['tierName'] ?? '',
      targetDiamonds: (data['targetDiamonds'] as num?)?.toInt() ?? 0,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemIcon: data['itemIcon'] ?? '',
      itemType: data['itemType'] ?? 'avatarFrame',
      validityDays: (data['validityDays'] as num?)?.toInt() ?? 7,
      bonusDiamonds: (data['bonusDiamonds'] as num?)?.toInt() ?? 0,
      endDate: (data['endDate'] is Timestamp)
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      order: (data['order'] as num?)?.toInt() ?? 1,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tierName': tierName,
      'targetDiamonds': targetDiamonds,
      'itemId': itemId,
      'itemName': itemName,
      'itemIcon': itemIcon,
      'itemType': itemType,
      'validityDays': validityDays,
      'bonusDiamonds': bonusDiamonds,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'order': order,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Configuration Model for SMS Webhook & Auto Payment Approval
class AutoApproveConfigModel {
  final bool isAutoApproveEnabled;
  final String webhookSecret;
  final String webhookUrl;
  final int autoMatchWindowHours;
  final DateTime? updatedAt;

  AutoApproveConfigModel({
    this.isAutoApproveEnabled = true,
    this.webhookSecret = 'imchat_secret_84519_sms',
    this.webhookUrl = 'https://us-central1-imchat-84519.cloudfunctions.net/smsWebhook',
    this.autoMatchWindowHours = 24,
    this.updatedAt,
  });

  factory AutoApproveConfigModel.fromMap(Map<String, dynamic> data) {
    return AutoApproveConfigModel(
      isAutoApproveEnabled: data['isAutoApproveEnabled'] ?? true,
      webhookSecret: data['webhookSecret'] ?? 'imchat_secret_84519_sms',
      webhookUrl: data['webhookUrl'] ??
          'https://us-central1-imchat-84519.cloudfunctions.net/smsWebhook',
      autoMatchWindowHours: (data['autoMatchWindowHours'] as num?)?.toInt() ?? 24,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAutoApproveEnabled': isAutoApproveEnabled,
      'webhookSecret': webhookSecret,
      'webhookUrl': webhookUrl,
      'autoMatchWindowHours': autoMatchWindowHours,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Incoming SMS Transaction Model from Webhook / SMS Forwarder
class IncomingTransactionModel {
  final String id; // Document ID (Uppercase TrxID)
  final String trxId;
  final num amount;
  final String sender; // e.g. 'bKash', 'Nagad', 'Rocket', phone number
  final String rawMessage;
  final String status; // 'unclaimed', 'claimed', 'auto_approved'
  final String? claimedByUserId;
  final String? claimedByUserName;
  final String? claimedOrderId;
  final int? claimedDiamonds;
  final DateTime? createdAt;
  final DateTime? claimedAt;

  IncomingTransactionModel({
    required this.id,
    required this.trxId,
    required this.amount,
    required this.sender,
    required this.rawMessage,
    this.status = 'unclaimed',
    this.claimedByUserId,
    this.claimedByUserName,
    this.claimedOrderId,
    this.claimedDiamonds,
    this.createdAt,
    this.claimedAt,
  });

  bool get isClaimed =>
      status.toLowerCase() == 'claimed' ||
      status.toLowerCase() == 'auto_approved';
  bool get isUnclaimed => status.toLowerCase() == 'unclaimed';

  factory IncomingTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return IncomingTransactionModel.fromMap(data, doc.id);
  }

  factory IncomingTransactionModel.fromMap(
    Map<String, dynamic> data, [
    String? id,
  ]) {
    final docId = id ?? data['trxId'] ?? data['id'] ?? '';
    return IncomingTransactionModel(
      id: docId,
      trxId: (data['trxId'] ?? docId).toString().toUpperCase().trim(),
      amount: data['amount'] ?? 0,
      sender: data['sender'] ?? 'SMS',
      rawMessage: data['rawMessage'] ?? '',
      status: data['status'] ?? 'unclaimed',
      claimedByUserId: data['claimedByUserId'],
      claimedByUserName: data['claimedByUserName'],
      claimedOrderId: data['claimedOrderId'],
      claimedDiamonds: (data['claimedDiamonds'] as num?)?.toInt(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      claimedAt: (data['claimedAt'] is Timestamp)
          ? (data['claimedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trxId': trxId,
      'amount': amount,
      'sender': sender,
      'rawMessage': rawMessage,
      'status': status,
      if (claimedByUserId != null) 'claimedByUserId': claimedByUserId,
      if (claimedByUserName != null) 'claimedByUserName': claimedByUserName,
      if (claimedOrderId != null) 'claimedOrderId': claimedOrderId,
      if (claimedDiamonds != null) 'claimedDiamonds': claimedDiamonds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
    };
  }
}

