import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum OfficialItemCategory {
  badge,
  avatarFrame,
  entryEffect,
  backgroundTheme,
  profileSkin,
  nameplate,
  micRefill,
  seatDecor,
  roomProfileBackground,
}

extension OfficialItemCategoryExt on OfficialItemCategory {
  String get displayName {
    switch (this) {
      case OfficialItemCategory.badge:
        return 'Badge';
      case OfficialItemCategory.avatarFrame:
        return 'Avatar Frame';
      case OfficialItemCategory.entryEffect:
        return 'Entry Effect';
      case OfficialItemCategory.backgroundTheme:
        return 'Room theme';
      case OfficialItemCategory.profileSkin:
        return 'Profile Skin';
      case OfficialItemCategory.nameplate:
        return 'Nameplate';
      case OfficialItemCategory.micRefill:
        return 'Mic Refill';
      case OfficialItemCategory.seatDecor:
        return 'Seat Decor';
      case OfficialItemCategory.roomProfileBackground:
        return 'Room Profile Background';
    }
  }

  String get icon {
    switch (this) {
      case OfficialItemCategory.badge:
        return '🏆';
      case OfficialItemCategory.avatarFrame:
        return '🖼️';
      case OfficialItemCategory.entryEffect:
        return '✨';
      case OfficialItemCategory.backgroundTheme:
        return '🎨';
      case OfficialItemCategory.profileSkin:
        return '🎭';
      case OfficialItemCategory.nameplate:
        return '📛';
      case OfficialItemCategory.micRefill:
        return '🎙️';
      case OfficialItemCategory.seatDecor:
        return '🪑';
      case OfficialItemCategory.roomProfileBackground:
        return '🖼️';
    }
  }

  Color get color {
    switch (this) {
      case OfficialItemCategory.badge:
        return Colors.amber;
      case OfficialItemCategory.avatarFrame:
        return Colors.purple;
      case OfficialItemCategory.entryEffect:
        return Colors.cyan;
      case OfficialItemCategory.backgroundTheme:
        return Colors.teal;
      case OfficialItemCategory.profileSkin:
        return Colors.pink;
      case OfficialItemCategory.nameplate:
        return Colors.indigo;
      case OfficialItemCategory.micRefill:
        return Colors.deepPurple;
      case OfficialItemCategory.seatDecor:
        return Colors.orange;
      case OfficialItemCategory.roomProfileBackground:
        return Colors.indigo;
    }
  }
}

class OfficialItemModel {
  final String id;
  final String name;
  final String description;
  final OfficialItemCategory category;
  final String fileUrl;
  final String fileName;
  final String fileType; // .svga, .gif, .png, .mp4, .image
  final String? thumbnailUrl;
  final String? lockedFileUrl; // Added for seat decor locked state
  final int starRating;
  final bool isActive;
  final DateTime createdAt;
  final int? displayId;

  OfficialItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    this.thumbnailUrl,
    this.lockedFileUrl,
    this.starRating = 1,
    this.isActive = true,
    required this.createdAt,
    this.displayId,
  });

  factory OfficialItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfficialItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: OfficialItemCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => OfficialItemCategory.badge,
      ),
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileType: data['fileType'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      lockedFileUrl: data['lockedFileUrl'],
      starRating: data['starRating'] ?? 1,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      displayId: data['displayId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'category': category.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'thumbnailUrl': thumbnailUrl,
      if (lockedFileUrl != null) 'lockedFileUrl': lockedFileUrl,
      'starRating': starRating,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (displayId != null) 'displayId': displayId,
    };
  }

  OfficialItemModel copyWith({
    String? id,
    String? name,
    String? description,
    OfficialItemCategory? category,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? thumbnailUrl,
    String? lockedFileUrl,
    int? starRating,
    bool? isActive,
    DateTime? createdAt,
    int? displayId,
  }) {
    return OfficialItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lockedFileUrl: lockedFileUrl ?? this.lockedFileUrl,
      starRating: starRating ?? this.starRating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      displayId: displayId ?? this.displayId,
    );
  }

  /// Item file is always SVGA
  static List<String> getSupportedFileTypes(OfficialItemCategory category) {
    return ['.svga', '.gif', '.png', '.mp4'];
  }
}

class UserOfficialItemModel {
  final String id;
  final String userId;
  final String userProfileId;
  final String username;
  final String officialItemId;
  final String itemName;
  final OfficialItemCategory itemCategory;
  final int durationDays;
  final DateTime assignedAt;
  final DateTime expiresAt;
  final bool isActive;
  final String assignedBy;

  UserOfficialItemModel({
    required this.id,
    required this.userId,
    required this.userProfileId,
    required this.username,
    required this.officialItemId,
    required this.itemName,
    required this.itemCategory,
    required this.durationDays,
    required this.assignedAt,
    required this.expiresAt,
    this.isActive = true,
    required this.assignedBy,
  });

  factory UserOfficialItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserOfficialItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userProfileId: data['userProfileId'] ?? '',
      username: data['username'] ?? '',
      officialItemId: data['officialItemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemCategory: OfficialItemCategory.values.firstWhere(
        (e) => e.name == data['itemCategory'],
        orElse: () => OfficialItemCategory.badge,
      ),
      durationDays: data['durationDays'] ?? 0,
      assignedAt: (data['assignedAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      assignedBy: data['assignedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userProfileId': userProfileId,
      'username': username,
      'officialItemId': officialItemId,
      'itemName': itemName,
      'itemCategory': itemCategory.name,
      'durationDays': durationDays,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isActive': isActive,
      'assignedBy': assignedBy,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String get statusText {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    return 'Active';
  }

  Color get statusColor {
    if (!isActive) return Colors.grey;
    if (isExpired) return Colors.red;
    return Colors.green;
  }

  String get remainingText {
    if (isExpired) return 'Expired';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inDays > 0) return '${remaining.inDays} days left';
    if (remaining.inHours > 0) return '${remaining.inHours} hours left';
    return '${remaining.inMinutes} min left';
  }
}
