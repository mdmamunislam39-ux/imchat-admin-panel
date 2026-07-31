import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isVerified;
  final int subscriberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChannelModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.isVerified = false,
    this.subscriberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChannelModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isVerified: data['isVerified'] ?? false,
      subscriberCount: data['subscriberCount'] ?? 0,
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
      'name': name,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'subscriberCount': subscriberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ChannelModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isVerified,
    int? subscriberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
