import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelPostModel {
  final String id;
  final String channelId;
  final String? textContent;
  final String? imageUrl;
  final String? linkUrl;
  final String? voiceRoomId;
  final DateTime createdAt;

  ChannelPostModel({
    required this.id,
    required this.channelId,
    this.textContent,
    this.imageUrl,
    this.linkUrl,
    this.voiceRoomId,
    required this.createdAt,
  });

  factory ChannelPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChannelPostModel(
      id: doc.id,
      channelId: data['channelId'] ?? '',
      textContent: data['textContent'],
      imageUrl: data['imageUrl'],
      linkUrl: data['linkUrl'],
      voiceRoomId: data['voiceRoomId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'channelId': channelId,
      'textContent': textContent,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'voiceRoomId': voiceRoomId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ChannelPostModel copyWith({
    String? id,
    String? channelId,
    String? textContent,
    String? imageUrl,
    String? linkUrl,
    String? voiceRoomId,
    DateTime? createdAt,
  }) {
    return ChannelPostModel(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      textContent: textContent ?? this.textContent,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      voiceRoomId: voiceRoomId ?? this.voiceRoomId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
