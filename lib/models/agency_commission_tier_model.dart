import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyCommissionTierModel {
  final String id;
  final int tierLevel;
  final String tierName;
  final int minTargetDiamonds;
  final double commissionPercentage;
  final int bonusRewardDiamonds;
  final String badgeColorHex;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgencyCommissionTierModel({
    required this.id,
    required this.tierLevel,
    required this.tierName,
    required this.minTargetDiamonds,
    required this.commissionPercentage,
    required this.bonusRewardDiamonds,
    this.badgeColorHex = '#FFB300',
    this.description = '',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AgencyCommissionTierModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AgencyCommissionTierModel.fromMap(data, doc.id);
  }

  factory AgencyCommissionTierModel.fromMap(Map<String, dynamic> data, [String id = '']) {
    return AgencyCommissionTierModel(
      id: id.isNotEmpty ? id : (data['id'] ?? ''),
      tierLevel: (data['tierLevel'] as num?)?.toInt() ?? 1,
      tierName: data['tierName'] ?? 'Tier 1',
      minTargetDiamonds: (data['minTargetDiamonds'] as num?)?.toInt() ?? 0,
      commissionPercentage: (data['commissionPercentage'] as num?)?.toDouble() ?? 0.0,
      bonusRewardDiamonds: (data['bonusRewardDiamonds'] as num?)?.toInt() ?? 0,
      badgeColorHex: data['badgeColorHex'] ?? '#FFB300',
      description: data['description'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'tierLevel': tierLevel,
      'tierName': tierName,
      'minTargetDiamonds': minTargetDiamonds,
      'commissionPercentage': commissionPercentage,
      'bonusRewardDiamonds': bonusRewardDiamonds,
      'badgeColorHex': badgeColorHex,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AgencyCommissionTierModel copyWith({
    String? id,
    int? tierLevel,
    String? tierName,
    int? minTargetDiamonds,
    double? commissionPercentage,
    int? bonusRewardDiamonds,
    String? badgeColorHex,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgencyCommissionTierModel(
      id: id ?? this.id,
      tierLevel: tierLevel ?? this.tierLevel,
      tierName: tierName ?? this.tierName,
      minTargetDiamonds: minTargetDiamonds ?? this.minTargetDiamonds,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      bonusRewardDiamonds: bonusRewardDiamonds ?? this.bonusRewardDiamonds,
      badgeColorHex: badgeColorHex ?? this.badgeColorHex,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
