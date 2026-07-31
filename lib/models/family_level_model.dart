import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyLevelModel {
  final String id;
  final int levelNumber;
  final String levelName;
  final int requiredPoints;
  final int bonusAmount;
  final int refreshDays;
  final String frameUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyLevelModel({
    required this.id,
    required this.levelNumber,
    required this.levelName,
    required this.requiredPoints,
    required this.bonusAmount,
    required this.refreshDays,
    required this.frameUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyLevelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FamilyLevelModel(
      id: doc.id,
      levelNumber: data['levelNumber'] ?? 1,
      levelName: data['levelName'] ?? '',
      requiredPoints: data['requiredPoints'] ?? 0,
      bonusAmount: data['bonusAmount'] ?? 0,
      refreshDays: data['refreshDays'] ?? 0,
      frameUrl: data['frameUrl'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'levelNumber': levelNumber,
      'levelName': levelName,
      'requiredPoints': requiredPoints,
      'bonusAmount': bonusAmount,
      'refreshDays': refreshDays,
      'frameUrl': frameUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FamilyLevelModel copyWith({
    String? id,
    int? levelNumber,
    String? levelName,
    int? requiredPoints,
    int? bonusAmount,
    int? refreshDays,
    String? frameUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyLevelModel(
      id: id ?? this.id,
      levelNumber: levelNumber ?? this.levelNumber,
      levelName: levelName ?? this.levelName,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      refreshDays: refreshDays ?? this.refreshDays,
      frameUrl: frameUrl ?? this.frameUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
