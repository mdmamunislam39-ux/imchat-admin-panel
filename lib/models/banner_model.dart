import 'package:cloud_firestore/cloud_firestore.dart';



class BannerModel {
  final String id;
  final String imageUrl;
  final String? redirectUrl;
  final String? eventId;

  final bool isActive;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.redirectUrl,
    this.eventId,

    this.isActive = true,
    this.orderIndex = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      redirectUrl: data['redirectUrl'],
      eventId: data['eventId'],

      isActive: data['isActive'] ?? true,
      orderIndex: data['orderIndex'] ?? 0,
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
      'imageUrl': imageUrl,
      'redirectUrl': redirectUrl,
      'eventId': eventId,

      'isActive': isActive,
      'orderIndex': orderIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BannerModel copyWith({
    String? id,
    String? imageUrl,
    String? redirectUrl,
    String? eventId,

    bool? isActive,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      eventId: eventId ?? this.eventId,

      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
