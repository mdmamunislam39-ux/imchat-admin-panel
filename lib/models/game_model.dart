import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String gameCode; // Unique Game ID (e.g. html5_greedy_market, greedy_market, fruit_wheel)
  final String name;
  final String thumbnailUrl;
  final String gameUrl;
  final double winRatio;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameModel({
    required this.id,
    this.gameCode = '',
    required this.name,
    required this.thumbnailUrl,
    this.gameUrl = '',
    this.winRatio = 0.5,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GameModel(
      id: doc.id,
      gameCode: data['gameCode'] ?? data['gameId'] ?? doc.id,
      name: data['name'] ?? data['title'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? data['icon'] ?? data['image'] ?? '',
      gameUrl: data['gameUrl'] ?? data['url'] ?? data['link'] ?? data['webViewUrl'] ?? '',
      winRatio: (data['winRatio'] ?? 0.5).toDouble(),
      isActive: (data['isActive'] != false && data['isEnabled'] != false && data['status'] != 'inactive'),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final effectiveUrl = gameUrl.isNotEmpty
        ? gameUrl
        : (gameCode.contains('greedy') || gameCode.contains('html5') || gameCode.contains('market')
            ? 'https://greedy-market-game.web.app'
            : '');
    final effectiveCode = gameCode.isNotEmpty ? gameCode : id;

    return {
      'gameCode': effectiveCode,
      'gameId': effectiveCode,
      'id': id.isNotEmpty ? id : effectiveCode,
      'name': name,
      'title': name,
      'thumbnailUrl': thumbnailUrl,
      'icon': thumbnailUrl,
      'image': thumbnailUrl,
      'picture': thumbnailUrl,
      'gameUrl': effectiveUrl,
      'url': effectiveUrl,
      'link': effectiveUrl,
      'webViewUrl': effectiveUrl,
      'type': 'html5',
      'gameType': 'html5',
      'isEnabled': isActive,
      'isHtml5': true,
      'isWebView': true,
      'winRatio': winRatio,
      'isActive': isActive,
      'status': isActive ? 'active' : 'inactive',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GameModel copyWith({
    String? id,
    String? gameCode,
    String? name,
    String? thumbnailUrl,
    String? gameUrl,
    double? winRatio,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      gameCode: gameCode ?? this.gameCode,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      gameUrl: gameUrl ?? this.gameUrl,
      winRatio: winRatio ?? this.winRatio,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
