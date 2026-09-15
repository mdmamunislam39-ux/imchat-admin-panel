import 'package:cloud_firestore/cloud_firestore.dart';

class RoomGameModel {
  final String id;
  final String gameCode; // e.g. ludo, carrom, youtube, or custom code
  final String name;
  final String thumbnailUrl;
  final String gameUrl;
  final String category; // 'mode' (Room Mode) or 'game' (Room Game)
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomGameModel({
    required this.id,
    this.gameCode = '',
    required this.name,
    required this.thumbnailUrl,
    this.gameUrl = '',
    this.category = 'game',
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomGameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomGameModel(
      id: doc.id,
      gameCode: (data['gameCode'] ?? data['gameId'] ?? doc.id).toString(),
      name: (data['name'] ?? data['title'] ?? '').toString(),
      thumbnailUrl: (data['thumbnailUrl'] ?? data['icon'] ?? data['image'] ?? '').toString(),
      gameUrl: (data['gameUrl'] ?? data['url'] ?? data['link'] ?? data['webViewUrl'] ?? '').toString(),
      category: (data['category'] ?? 'game').toString(),
      isActive: (data['isActive'] != false && data['isEnabled'] != false && data['status'] != 'inactive'),
      sortOrder: (data['sortOrder'] ?? data['order'] ?? 0) is int ? (data['sortOrder'] ?? data['order'] ?? 0) : 0,
      createdAt: data['createdAt'] != null && data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final effectiveCode = gameCode.isNotEmpty ? gameCode : id;
    return {
      'id': id.isNotEmpty ? id : effectiveCode,
      'gameCode': effectiveCode,
      'gameId': effectiveCode,
      'name': name,
      'title': name,
      'thumbnailUrl': thumbnailUrl,
      'icon': thumbnailUrl,
      'image': thumbnailUrl,
      'gameUrl': gameUrl,
      'url': gameUrl,
      'link': gameUrl,
      'webViewUrl': gameUrl,
      'category': category,
      'isActive': isActive,
      'isEnabled': isActive,
      'status': isActive ? 'active' : 'inactive',
      'sortOrder': sortOrder,
      'type': 'room_game',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RoomGameModel copyWith({
    String? id,
    String? gameCode,
    String? name,
    String? thumbnailUrl,
    String? gameUrl,
    String? category,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomGameModel(
      id: id ?? this.id,
      gameCode: gameCode ?? this.gameCode,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gameUrl: gameUrl ?? this.gameUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
