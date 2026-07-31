import 'package:cloud_firestore/cloud_firestore.dart';

enum ReceiverType { host, normalUser }

class GiftTransactionModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final ReceiverType receiverType;
  final double diamondAmount;
  final double beansToReceiver;
  final double beansToAgency;
  final double platformShare;
  final String? agencyId;
  final String giftName;
  final DateTime createdAt;

  GiftTransactionModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.receiverType,
    required this.diamondAmount,
    required this.beansToReceiver,
    this.beansToAgency = 0.0,
    required this.platformShare,
    this.agencyId,
    required this.giftName,
    required this.createdAt,
  });

  factory GiftTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GiftTransactionModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      receiverType: ReceiverType.values.firstWhere(
        (e) => e.name == data['receiverType'],
        orElse: () => ReceiverType.normalUser,
      ),
      diamondAmount: (data['diamondAmount'] ?? 0.0).toDouble(),
      beansToReceiver: (data['beansToReceiver'] ?? 0.0).toDouble(),
      beansToAgency: (data['beansToAgency'] ?? 0.0).toDouble(),
      platformShare: (data['platformShare'] ?? 0.0).toDouble(),
      agencyId: data['agencyId'],
      giftName: data['giftName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverType': receiverType.name,
      'diamondAmount': diamondAmount,
      'beansToReceiver': beansToReceiver,
      'beansToAgency': beansToAgency,
      'platformShare': platformShare,
      'agencyId': agencyId,
      'giftName': giftName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
