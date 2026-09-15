import 'package:cloud_firestore/cloud_firestore.dart';

class GrabTheTopRuleModel {
  final String id;
  final String giftId;
  final String giftName;
  final String? giftImageUrl;
  final int minGiftCount; // Koyta gift korle (gift quantity)
  final int showingTimeSeconds; // Showing time (seconds)
  final bool isActive;
  final String bannerTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  GrabTheTopRuleModel({
    required this.id,
    required this.giftId,
    required this.giftName,
    this.giftImageUrl,
    required this.minGiftCount,
    required this.showingTimeSeconds,
    this.isActive = true,
    this.bannerTitle = '👑 {sender} sent {count}x {gift} to {receiver} and Grabbed the Top! 🪑',
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrabTheTopRuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GrabTheTopRuleModel(
      id: doc.id,
      giftId: data['giftId']?.toString() ?? '',
      giftName: data['giftName']?.toString() ?? 'Gift',
      giftImageUrl: data['giftImageUrl']?.toString(),
      minGiftCount: (data['minGiftCount'] ?? data['giftQuantity'] ?? 1) as int,
      showingTimeSeconds: (data['showingTimeSeconds'] ?? data['showingTime'] ?? 10) as int,
      isActive: data['isActive'] ?? true,
      bannerTitle: data['bannerTitle']?.toString() ?? '👑 {sender} sent {count}x {gift} to {receiver} and Grabbed the Top! 🪑',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'giftId': giftId,
      'giftName': giftName,
      'giftImageUrl': giftImageUrl,
      'minGiftCount': minGiftCount,
      'giftQuantity': minGiftCount,
      'showingTimeSeconds': showingTimeSeconds,
      'showingTime': showingTimeSeconds,
      'isActive': isActive,
      'bannerTitle': bannerTitle,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
