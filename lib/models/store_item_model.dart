import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum StoreItemType {
  avatarFrame,
  entryEffect,
  badge,
  backgroundTheme,
  roomTheme,
  seatDecor,
  micRefill,
  roomProfileBackground,
}

enum StoreCategory {
  store,
  officialStore,
}

class StoreItemModel {
  final String id;
  final String name;
  final String description;
  final StoreItemType type;
  final StoreCategory category;
  final String fileUrl;
  final String fileName;
  final String fileType; // .svga, .gif, .png, .mp4, .image
  final double diamondPrice;
  final int expirationDuration; // in days, 0 means permanent
  final int starRating;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final String? lockedFileUrl; // For seat decor locked state
  final Map<String, dynamic>? metadata; // Additional data like dimensions, etc.
  final int? displayId;

  StoreItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.fileUrl,
    required this.fileName,
    required this.fileType,
    required this.diamondPrice,
    required this.expirationDuration,
    this.starRating = 1,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailUrl,
    this.lockedFileUrl,
    this.metadata,
    this.displayId,
  });

  factory StoreItemModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return StoreItemModel(
        id: doc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        type: StoreItemType.values.firstWhere(
          (e) => e.toString() == 'StoreItemType.${data['type']}',
          orElse: () => StoreItemType.avatarFrame,
        ),
        category: data['category'] == 'official' 
            ? StoreCategory.officialStore 
            : StoreCategory.values.firstWhere(
                (e) => e.toString() == 'StoreCategory.${data['category']}',
                orElse: () => StoreCategory.store,
              ),
        fileUrl: data['fileUrl'] ?? '',
        fileName: data['fileName'] ?? '',
        fileType: data['fileType'] ?? '',
        diamondPrice: (data['diamondPrice'] ?? 0.0).toDouble(),
        expirationDuration: data['expirationDuration'] ?? 0,
        starRating: data['starRating'] ?? 1,
        isActive: data['isActive'] ?? true,
        createdAt: (data['createdAt'] is Timestamp) 
            ? (data['createdAt'] as Timestamp).toDate() 
            : DateTime.now(),
        updatedAt: (data['updatedAt'] is Timestamp) 
            ? (data['updatedAt'] as Timestamp).toDate() 
            : DateTime.now(),
        thumbnailUrl: data['thumbnailUrl'],
        lockedFileUrl: data['lockedFileUrl'],
        metadata: data['metadata'],
        displayId: data['displayId'],
      );
    } catch (e) {
      debugPrint('Error creating StoreItemModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'category': category.toString().split('.').last,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'diamondPrice': diamondPrice,
        'expirationDuration': expirationDuration,
        'starRating': starRating,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'thumbnailUrl': thumbnailUrl,
        'lockedFileUrl': lockedFileUrl,
        'metadata': metadata,
        if (displayId != null) 'displayId': displayId,
      };
    } catch (e) {
      debugPrint('Error converting StoreItemModel to Firestore: $e');
      rethrow;
    }
  }

  StoreItemModel copyWith({
    String? id,
    String? name,
    String? description,
    StoreItemType? type,
    StoreCategory? category,
    String? fileUrl,
    String? fileName,
    String? fileType,
    double? diamondPrice,
    int? expirationDuration,
    int? starRating,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailUrl,
    String? lockedFileUrl,
    Map<String, dynamic>? metadata,
    int? displayId,
  }) {
    return StoreItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      diamondPrice: diamondPrice ?? this.diamondPrice,
      expirationDuration: expirationDuration ?? this.expirationDuration,
      starRating: starRating ?? this.starRating,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lockedFileUrl: lockedFileUrl ?? this.lockedFileUrl,
      metadata: metadata ?? this.metadata,
      displayId: displayId ?? this.displayId,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case StoreItemType.avatarFrame:
        return 'Avatar Frame';
      case StoreItemType.entryEffect:
        return 'Entry Effect';
      case StoreItemType.badge:
        return 'Badge';
      case StoreItemType.backgroundTheme:
        return 'Profile skin';
      case StoreItemType.roomTheme:
        return 'Room theme';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case StoreCategory.store:
        return 'Store';
      case StoreCategory.officialStore:
        return 'Official Store';
    }
  }

  String get typeIcon {
    switch (type) {
      case StoreItemType.avatarFrame:
        return '🖼️';
      case StoreItemType.entryEffect:
        return '✨';
      case StoreItemType.badge:
        return '🏆';
      case StoreItemType.backgroundTheme:
        return '🎭';
      case StoreItemType.roomTheme:
        return '🎨';
      case StoreItemType.seatDecor:
        return '🪑';
      case StoreItemType.micRefill:
        return '🎙️';
      case StoreItemType.roomProfileBackground:
        return '🖼️';
    }
  }

  bool get isPermanent => expirationDuration == 0;

  String get expirationText {
    if (isPermanent) {
      return 'Permanent';
    } else if (expirationDuration == 1) {
      return '1 day';
    } else if (expirationDuration < 30) {
      return '$expirationDuration days';
    } else if (expirationDuration < 365) {
      final months = (expirationDuration / 30).round();
      return '$months month${months == 1 ? '' : 's'}';
    } else {
      final years = (expirationDuration / 365).round();
      return '$years year${years == 1 ? '' : 's'}';
    }
  }

  @override
  String toString() {
    return 'StoreItemModel(id: $id, name: $name, type: $type, category: $category, diamondPrice: $diamondPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserStoreItemModel {
  final String id;
  final String userId;
  final String userProfileId;
  final String storeItemId;
  final String storeItemName;
  final StoreItemType itemType;
  final DateTime assignedAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String assignedBy; // Admin ID who assigned this item

  UserStoreItemModel({
    required this.id,
    required this.userId,
    required this.userProfileId,
    required this.storeItemId,
    required this.storeItemName,
    required this.itemType,
    required this.assignedAt,
    this.expiresAt,
    this.isActive = true,
    required this.assignedBy,
  });

  factory UserStoreItemModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return UserStoreItemModel(
        id: doc.id,
        userId: data['userId'] ?? '',
        userProfileId: data['userProfileId'] ?? '',
        storeItemId: data['storeItemId'] ?? '',
        storeItemName: data['storeItemName'] ?? '',
        itemType: StoreItemType.values.firstWhere(
          (e) => e.toString() == 'StoreItemType.${data['itemType']}',
          orElse: () => StoreItemType.avatarFrame,
        ),
        assignedAt: (data['assignedAt'] as Timestamp).toDate(),
        expiresAt: data['expiresAt'] != null 
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
        isActive: data['isActive'] ?? true,
        assignedBy: data['assignedBy'] ?? '',
      );
    } catch (e) {
      debugPrint('Error creating UserStoreItemModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'userId': userId,
        'userProfileId': userProfileId,
        'storeItemId': storeItemId,
        'storeItemName': storeItemName,
        'itemType': itemType.toString().split('.').last,
        'assignedAt': Timestamp.fromDate(assignedAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'isActive': isActive,
        'assignedBy': assignedBy,
      };
    } catch (e) {
      debugPrint('Error converting UserStoreItemModel to Firestore: $e');
      rethrow;
    }
  }

  UserStoreItemModel copyWith({
    String? id,
    String? userId,
    String? userProfileId,
    String? storeItemId,
    String? storeItemName,
    StoreItemType? itemType,
    DateTime? assignedAt,
    DateTime? expiresAt,
    bool? isActive,
    String? assignedBy,
  }) {
    return UserStoreItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userProfileId: userProfileId ?? this.userProfileId,
      storeItemId: storeItemId ?? this.storeItemId,
      storeItemName: storeItemName ?? this.storeItemName,
      itemType: itemType ?? this.itemType,
      assignedAt: assignedAt ?? this.assignedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      assignedBy: assignedBy ?? this.assignedBy,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  String get statusText {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    return 'Active';
  }

  @override
  String toString() {
    return 'UserStoreItemModel(id: $id, userProfileId: $userProfileId, storeItemName: $storeItemName, itemType: $itemType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStoreItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
