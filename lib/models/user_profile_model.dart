import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserType {
  regular,
  host,
  seller,
  admin,
  agency,
  // ignore: constant_identifier_names
  agency_owner,
}

enum UserStatus {
  active,
  blocked,
  suspended,
  pending,
}

enum LevelType {
  sending,
  receiving,
  gifting,
  room,
}

class UserProfileModel {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final String? phone;
  final String? email;
  final String? loginProvider;
  final String? searchId;
  final UserType userType;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;
  
  // Diamonds & Beans
  final double totalDiamonds;
  final double totalBeans;
  final double diamondsSent;
  final double diamondsReceived;
  
  // Level System
  final UserLevel sendingLevel;
  final UserLevel receivingLevel;
  final UserLevel giftingLevel;
  
  // Customization
  final UserCustomization customization;
  
  // Activity Stats
  final UserActivityStats activityStats;
  
  // Host Information
  final String? agencyId;
  final String? agencyName;
  
  // Blocked Users
  final List<String> blockedUserIds;
  final List<UserPunishment> punishments;

  UserProfileModel({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    this.bio,
    this.phone,
    this.email,
    this.loginProvider,
    this.searchId,
    this.userType = UserType.regular,
    this.status = UserStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
    this.totalDiamonds = 0.0,
    this.totalBeans = 0.0,
    this.diamondsSent = 0.0,
    this.diamondsReceived = 0.0,
    required this.sendingLevel,
    required this.receivingLevel,
    required this.giftingLevel,
    required this.customization,
    required this.activityStats,
    this.agencyId,
    this.agencyName,
    this.blockedUserIds = const [],
    this.punishments = const [],
  });

  static double _parseNumber(Map<String, dynamic> data, List<String> keys, {double defaultValue = 0.0}) {
    for (final key in keys) {
      final val = data[key];
      if (val != null) {
        if (val is num) {
          return val.toDouble();
        } else if (val is String) {
          final parsed = double.tryParse(val.trim());
          if (parsed != null) return parsed;
        }
      }
    }
    return defaultValue;
  }

  static String _firstNonEmpty(Map<String, dynamic> data, List<String> keys, {String defaultValue = ''}) {
    for (final key in keys) {
      final val = data[key];
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty) {
          return str;
        }
      }
    }
    return defaultValue;
  }

  static String? _firstNonEmptyNullable(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final val = data[key];
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty) {
          return str;
        }
      }
    }
    return null;
  }

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final rawUsername = _firstNonEmpty(data, [
        'fullname', 'username', 'name', 'displayName', 'nickname', 'userName', 'user_name', 'fullName'
      ], defaultValue: '');
      final rawPhoto = _firstNonEmptyNullable(data, [
        'photoUrl', 'profileImageUrl', 'avatar', 'photo', 'profileImage', 'image', 'userImage', 'photoURL', 'profile_picture', 'picture'
      ]);
      final rawPhone = _firstNonEmptyNullable(data, [
        'number', 'phone', 'phoneNumber', 'mobile', 'mobileNumber', 'phone_number'
      ]);
      final rawEmail = _firstNonEmptyNullable(data, [
        'email', 'googleEmail', 'userEmail', 'mail', 'google', 'user_email'
      ]);
      final rawLoginProvider = _firstNonEmptyNullable(data, [
        'loginProvider', 'provider', 'authProvider', 'login_provider'
      ]);
      final rawSearchId = _firstNonEmptyNullable(data, [
        'searchId', 'uniqueId', 'user_id', 'id'
      ]);

      return UserProfileModel(
        id: doc.id,
        userId: data['userId']?.toString() ?? doc.id,
        username: rawUsername,
        profileImageUrl: rawPhoto,
        bio: data['bio']?.toString(),
        phone: rawPhone,
        email: rawEmail,
        loginProvider: rawLoginProvider,
        searchId: rawSearchId,
        userType: UserType.values.firstWhere(
          (e) => e.name == data['userType'],
          orElse: () => (data['isHost'] == true) ? UserType.host : UserType.regular,
        ),
        status: UserStatus.values.firstWhere(
          (e) => e.name == data['status'],
          orElse: () => UserStatus.active,
        ),
        createdAt: data['createdAt'] != null && data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null && data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        lastActiveAt: data['lastActiveAt'] != null && data['lastActiveAt'] is Timestamp
            ? (data['lastActiveAt'] as Timestamp).toDate()
            : null,
        totalDiamonds: _parseNumber(data, ['diamonds', 'totalDiamonds', 'walletDiamonds', 'diamond']),
        totalBeans: _parseNumber(data, ['beans', 'totalBeans', 'walletBeans', 'bean', 'beansEarned', 'beansCount']),
        diamondsSent: (data['diamondsSent'] ?? 0.0).toDouble(),
        diamondsReceived: (data['diamondsReceived'] ?? 0.0).toDouble(),
        sendingLevel: UserLevel.fromMap(data['sendingLevel'] ?? {}),
        receivingLevel: UserLevel.fromMap(data['receivingLevel'] ?? {}),
        giftingLevel: UserLevel.fromMap(data['giftingLevel'] ?? {}),
        customization: UserCustomization.fromMap(data['customization'] ?? {}),
        activityStats: UserActivityStats.fromMap(data['activityStats'] ?? {}),
        agencyId: data['agencyId']?.toString(),
        agencyName: data['agencyName']?.toString(),
        blockedUserIds: List<String>.from(data['blockedUserIds'] ?? []),
        punishments: (data['punishments'] as List<dynamic>?)
            ?.map((e) => UserPunishment.fromMap(e))
            .toList() ?? [],
      );
    } catch (e) {
      debugPrint('Error creating UserProfileModel from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      bool isLoginBanPermanent = false;
      DateTime? loginBanEndTime;
      bool isMicBanPermanent = false;
      DateTime? micBanEndTime;
      bool isPostBanPermanent = false;
      DateTime? postBanEndTime;

      for (final p in punishments) {
        if (p.isActive && !p.isExpired) {
          switch (p.type) {
            case PunishmentType.voiceRoomBan:
              if (p.expiresAt == null) {
                isMicBanPermanent = true;
              } else {
                micBanEndTime = p.expiresAt;
              }
              break;
            case PunishmentType.postBan:
              if (p.expiresAt == null) {
                isPostBanPermanent = true;
              } else {
                postBanEndTime = p.expiresAt;
              }
              break;
            case PunishmentType.accountBan:
            case PunishmentType.deviceBan:
            case PunishmentType.permanentBlock:
            case PunishmentType.temporaryBlock:
            case PunishmentType.suspension:
              if (p.expiresAt == null || p.type == PunishmentType.permanentBlock) {
                isLoginBanPermanent = true;
              } else {
                loginBanEndTime = p.expiresAt;
              }
              break;
            case PunishmentType.warning:
              break;
          }
        }
      }

      // If status is explicitly blocked, ensure login ban is true if not already configured
      if (status == UserStatus.blocked && !isLoginBanPermanent && loginBanEndTime == null) {
        isLoginBanPermanent = true;
      }

      return {
        'userId': userId,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'bio': bio,
        'phone': phone,
        'email': email,
        'loginProvider': loginProvider,
        'searchId': searchId,
        'userType': userType.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
        'totalDiamonds': totalDiamonds,
        'totalBeans': totalBeans,
        'diamondsSent': diamondsSent,
        'diamondsReceived': diamondsReceived,
        'sendingLevel': sendingLevel.toMap(),
        'receivingLevel': receivingLevel.toMap(),
        'giftingLevel': giftingLevel.toMap(),
        'customization': customization.toMap(),
        'activityStats': activityStats.toMap(),
        'agencyId': agencyId,
        'agencyName': agencyName,
        'blockedUserIds': blockedUserIds,
        'punishments': punishments.map((e) => e.toMap()).toList(),
        'banStatus': {
          'loginBanEndTime': loginBanEndTime != null ? Timestamp.fromDate(loginBanEndTime) : null,
          'isLoginBanPermanent': isLoginBanPermanent,
          'micBanEndTime': micBanEndTime != null ? Timestamp.fromDate(micBanEndTime) : null,
          'isMicBanPermanent': isMicBanPermanent,
          'postBanEndTime': postBanEndTime != null ? Timestamp.fromDate(postBanEndTime) : null,
          'isPostBanPermanent': isPostBanPermanent,
          'chatBanEndTime': null,
          'isChatBanPermanent': false,
        },
      };
    } catch (e) {
      debugPrint('Error converting UserProfileModel to Firestore: $e');
      rethrow;
    }
  }

  UserProfileModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? profileImageUrl,
    String? bio,
    String? phone,
    String? email,
    String? loginProvider,
    String? searchId,
    UserType? userType,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    double? totalDiamonds,
    double? totalBeans,
    double? diamondsSent,
    double? diamondsReceived,
    UserLevel? sendingLevel,
    UserLevel? receivingLevel,
    UserLevel? giftingLevel,
    UserCustomization? customization,
    UserActivityStats? activityStats,
    String? agencyId,
    String? agencyName,
    List<String>? blockedUserIds,
    List<UserPunishment>? punishments,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      loginProvider: loginProvider ?? this.loginProvider,
      searchId: searchId ?? this.searchId,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalDiamonds: totalDiamonds ?? this.totalDiamonds,
      totalBeans: totalBeans ?? this.totalBeans,
      diamondsSent: diamondsSent ?? this.diamondsSent,
      diamondsReceived: diamondsReceived ?? this.diamondsReceived,
      sendingLevel: sendingLevel ?? this.sendingLevel,
      receivingLevel: receivingLevel ?? this.receivingLevel,
      giftingLevel: giftingLevel ?? this.giftingLevel,
      customization: customization ?? this.customization,
      activityStats: activityStats ?? this.activityStats,
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      punishments: punishments ?? this.punishments,
    );
  }

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty && phone != '-';
  bool get hasEmail => email != null && email!.trim().isNotEmpty && email != '-';
  String get contactInfo {
    if (hasPhone && hasEmail) {
      return '$phone | $email';
    } else if (hasPhone) {
      return phone!;
    } else if (hasEmail) {
      return email!;
    }
    return '-';
  }

  bool get isHost => userType == UserType.host;
  bool get isSeller => userType == UserType.seller;
  bool get isAdmin => userType == UserType.admin;
  bool get isBlocked => status == UserStatus.blocked;
  bool get isSuspended => status == UserStatus.suspended;

  @override
  String toString() {
    return 'UserProfileModel(id: $id, username: $username, userType: $userType, totalDiamonds: $totalDiamonds, totalBeans: $totalBeans)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserLevel {
  final int level;
  final double currentProgress;
  final double requiredForNext;
  final String? customImageUrl;
  final String levelName;
  final DateTime lastUpdated;

  UserLevel({
    required this.level,
    required this.currentProgress,
    required this.requiredForNext,
    this.customImageUrl,
    required this.levelName,
    required this.lastUpdated,
  });

  factory UserLevel.fromMap(Map<String, dynamic> data) {
    try {
      return UserLevel(
        level: data['level'] ?? 1,
        currentProgress: (data['currentProgress'] ?? 0.0).toDouble(),
        requiredForNext: (data['requiredForNext'] ?? 1000.0).toDouble(),
        customImageUrl: data['customImageUrl'],
        levelName: data['levelName'] ?? 'Level 1',
        lastUpdated: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating UserLevel from map: $e');
      return UserLevel(
        level: data['level'] ?? 1,
        currentProgress: (data['currentProgress'] ?? 0.0).toDouble(),
        requiredForNext: (data['requiredForNext'] ?? 1000.0).toDouble(),
        customImageUrl: data['customImageUrl'],
        levelName: data['levelName'] ?? 'Level 1',
        lastUpdated: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'currentProgress': currentProgress,
      'requiredForNext': requiredForNext,
      'customImageUrl': customImageUrl,
      'levelName': levelName,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  double get progressPercentage => 
      requiredForNext > 0 ? (currentProgress / requiredForNext) * 100 : 0.0;

  UserLevel copyWith({
    int? level,
    double? currentProgress,
    double? requiredForNext,
    String? customImageUrl,
    String? levelName,
    DateTime? lastUpdated,
  }) {
    return UserLevel(
      level: level ?? this.level,
      currentProgress: currentProgress ?? this.currentProgress,
      requiredForNext: requiredForNext ?? this.requiredForNext,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      levelName: levelName ?? this.levelName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserCustomization {
  final String? selectedBadgeId;
  final String? selectedFrameId;
  final String? selectedEntryEffectId;
  final String? selectedBackgroundThemeId;
  final String? selectedNameplateId;
  final List<String> selectedNameplateIds;
  final String? selectedMicRefillId;
  final String? selectedRoomProfileBackgroundId;
  final String? selectedShortProfileThemeId;
  final String? selectedRoomEntryId;
  final List<String> ownedBadges;
  final List<String> ownedFrames;
  final List<String> ownedEntryEffects;
  final List<String> ownedBackgroundThemes;
  final List<String> ownedNameplates;
  final List<String> ownedMicRefills;
  final List<String> ownedRoomProfileBackgrounds;
  final List<String> ownedShortProfileThemes;
  final List<String> ownedRoomEntries;

  UserCustomization({
    this.selectedBadgeId,
    this.selectedFrameId,
    this.selectedEntryEffectId,
    this.selectedBackgroundThemeId,
    this.selectedNameplateId,
    this.selectedNameplateIds = const [],
    this.selectedMicRefillId,
    this.selectedRoomProfileBackgroundId,
    this.selectedShortProfileThemeId,
    this.selectedRoomEntryId,
    this.ownedBadges = const [],
    this.ownedFrames = const [],
    this.ownedEntryEffects = const [],
    this.ownedBackgroundThemes = const [],
    this.ownedNameplates = const [],
    this.ownedMicRefills = const [],
    this.ownedRoomProfileBackgrounds = const [],
    this.ownedShortProfileThemes = const [],
    this.ownedRoomEntries = const [],
  });

  factory UserCustomization.fromMap(Map<String, dynamic> data) {
    final nameplateId = data['selectedNameplateId'] as String?;
    List<String> nameplateIds = [];
    if (data['selectedNameplateIds'] != null) {
      nameplateIds = (data['selectedNameplateIds'] as List?)?.whereType<String>().toList() ?? [];
    } else if (nameplateId != null && nameplateId.isNotEmpty) {
      nameplateIds = [nameplateId];
    }

    return UserCustomization(
      selectedBadgeId: data['selectedBadgeId'] as String?,
      selectedFrameId: data['selectedFrameId'] as String?,
      selectedEntryEffectId: data['selectedEntryEffectId'] as String?,
      selectedBackgroundThemeId: data['selectedBackgroundThemeId'] as String?,
      selectedNameplateId: nameplateId ?? (nameplateIds.isNotEmpty ? nameplateIds.first : null),
      selectedNameplateIds: nameplateIds,
      selectedMicRefillId: data['selectedMicRefillId'] as String?,
      selectedRoomProfileBackgroundId: data['selectedRoomProfileBackgroundId'] as String?,
      selectedShortProfileThemeId: data['selectedShortProfileThemeId'] as String?,
      selectedRoomEntryId: data['selectedRoomEntryId'] as String?,
      ownedBadges: (data['ownedBadges'] as List?)?.whereType<String>().toList() ?? [],
      ownedFrames: (data['ownedFrames'] as List?)?.whereType<String>().toList() ?? [],
      ownedEntryEffects: (data['ownedEntryEffects'] as List?)?.whereType<String>().toList() ?? [],
      ownedBackgroundThemes: (data['ownedBackgroundThemes'] as List?)?.whereType<String>().toList() ?? [],
      ownedNameplates: (data['ownedNameplates'] as List?)?.whereType<String>().toList() ?? [],
      ownedMicRefills: (data['ownedMicRefills'] as List?)?.whereType<String>().toList() ?? [],
      ownedRoomProfileBackgrounds: (data['ownedRoomProfileBackgrounds'] as List?)?.whereType<String>().toList() ?? [],
      ownedShortProfileThemes: (data['ownedShortProfileThemes'] as List?)?.whereType<String>().toList() ?? [],
      ownedRoomEntries: (data['ownedRoomEntries'] as List?)?.whereType<String>().toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedBadgeId': selectedBadgeId,
      'selectedFrameId': selectedFrameId,
      'selectedEntryEffectId': selectedEntryEffectId,
      'selectedBackgroundThemeId': selectedBackgroundThemeId,
      'selectedNameplateId': selectedNameplateId ?? (selectedNameplateIds.isNotEmpty ? selectedNameplateIds.first : null),
      'selectedNameplateIds': selectedNameplateIds,
      'selectedMicRefillId': selectedMicRefillId,
      'selectedRoomProfileBackgroundId': selectedRoomProfileBackgroundId,
      'selectedShortProfileThemeId': selectedShortProfileThemeId,
      'selectedRoomEntryId': selectedRoomEntryId,
      'ownedBadges': ownedBadges,
      'ownedFrames': ownedFrames,
      'ownedEntryEffects': ownedEntryEffects,
      'ownedBackgroundThemes': ownedBackgroundThemes,
      'ownedNameplates': ownedNameplates,
      'ownedMicRefills': ownedMicRefills,
      'ownedRoomProfileBackgrounds': ownedRoomProfileBackgrounds,
      'ownedShortProfileThemes': ownedShortProfileThemes,
      'ownedRoomEntries': ownedRoomEntries,
    };
  }

  UserCustomization copyWith({
    String? selectedBadgeId,
    String? selectedFrameId,
    String? selectedEntryEffectId,
    String? selectedBackgroundThemeId,
    String? selectedNameplateId,
    List<String>? selectedNameplateIds,
    String? selectedMicRefillId,
    String? selectedRoomProfileBackgroundId,
    String? selectedShortProfileThemeId,
    String? selectedRoomEntryId,
    List<String>? ownedBadges,
    List<String>? ownedFrames,
    List<String>? ownedEntryEffects,
    List<String>? ownedBackgroundThemes,
    List<String>? ownedNameplates,
    List<String>? ownedMicRefills,
    List<String>? ownedRoomProfileBackgrounds,
    List<String>? ownedShortProfileThemes,
    List<String>? ownedRoomEntries,
  }) {
    return UserCustomization(
      selectedBadgeId: selectedBadgeId ?? this.selectedBadgeId,
      selectedFrameId: selectedFrameId ?? this.selectedFrameId,
      selectedEntryEffectId: selectedEntryEffectId ?? this.selectedEntryEffectId,
      selectedBackgroundThemeId: selectedBackgroundThemeId ?? this.selectedBackgroundThemeId,
      selectedNameplateId: selectedNameplateId ?? this.selectedNameplateId,
      selectedNameplateIds: selectedNameplateIds ?? this.selectedNameplateIds,
      selectedMicRefillId: selectedMicRefillId ?? this.selectedMicRefillId,
      selectedRoomProfileBackgroundId: selectedRoomProfileBackgroundId ?? this.selectedRoomProfileBackgroundId,
      selectedShortProfileThemeId: selectedShortProfileThemeId ?? this.selectedShortProfileThemeId,
      selectedRoomEntryId: selectedRoomEntryId ?? this.selectedRoomEntryId,
      ownedBadges: ownedBadges ?? this.ownedBadges,
      ownedFrames: ownedFrames ?? this.ownedFrames,
      ownedEntryEffects: ownedEntryEffects ?? this.ownedEntryEffects,
      ownedBackgroundThemes: ownedBackgroundThemes ?? this.ownedBackgroundThemes,
      ownedNameplates: ownedNameplates ?? this.ownedNameplates,
      ownedMicRefills: ownedMicRefills ?? this.ownedMicRefills,
      ownedRoomProfileBackgrounds: ownedRoomProfileBackgrounds ?? this.ownedRoomProfileBackgrounds,
      ownedShortProfileThemes: ownedShortProfileThemes ?? this.ownedShortProfileThemes,
      ownedRoomEntries: ownedRoomEntries ?? this.ownedRoomEntries,
    );
  }
}

class UserActivityStats {
  final double dailyDiamondsSent;
  final double dailyDiamondsReceived;
  final double weeklyDiamondsSent;
  final double weeklyDiamondsReceived;
  final double monthlyDiamondsSent;
  final double monthlyDiamondsReceived;
  final int dailyVoiceRoomMinutes;
  final int weeklyVoiceRoomMinutes;
  final int monthlyVoiceRoomMinutes;
  final DateTime lastUpdated;

  UserActivityStats({
    this.dailyDiamondsSent = 0.0,
    this.dailyDiamondsReceived = 0.0,
    this.weeklyDiamondsSent = 0.0,
    this.weeklyDiamondsReceived = 0.0,
    this.monthlyDiamondsSent = 0.0,
    this.monthlyDiamondsReceived = 0.0,
    this.dailyVoiceRoomMinutes = 0,
    this.weeklyVoiceRoomMinutes = 0,
    this.monthlyVoiceRoomMinutes = 0,
    required this.lastUpdated,
  });

  factory UserActivityStats.fromMap(Map<String, dynamic> data) {
    try {
      return UserActivityStats(
        dailyDiamondsSent: (data['dailyDiamondsSent'] ?? 0.0).toDouble(),
        dailyDiamondsReceived: (data['dailyDiamondsReceived'] ?? 0.0).toDouble(),
        weeklyDiamondsSent: (data['weeklyDiamondsSent'] ?? 0.0).toDouble(),
        weeklyDiamondsReceived: (data['weeklyDiamondsReceived'] ?? 0.0).toDouble(),
        monthlyDiamondsSent: (data['monthlyDiamondsSent'] ?? 0.0).toDouble(),
        monthlyDiamondsReceived: (data['monthlyDiamondsReceived'] ?? 0.0).toDouble(),
        dailyVoiceRoomMinutes: data['dailyVoiceRoomMinutes'] ?? 0,
        weeklyVoiceRoomMinutes: data['weeklyVoiceRoomMinutes'] ?? 0,
        monthlyVoiceRoomMinutes: data['monthlyVoiceRoomMinutes'] ?? 0,
        lastUpdated: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error creating UserActivityStats from map: $e');
      return UserActivityStats(
        dailyDiamondsSent: (data['dailyDiamondsSent'] ?? 0.0).toDouble(),
        dailyDiamondsReceived: (data['dailyDiamondsReceived'] ?? 0.0).toDouble(),
        weeklyDiamondsSent: (data['weeklyDiamondsSent'] ?? 0.0).toDouble(),
        weeklyDiamondsReceived: (data['weeklyDiamondsReceived'] ?? 0.0).toDouble(),
        monthlyDiamondsSent: (data['monthlyDiamondsSent'] ?? 0.0).toDouble(),
        monthlyDiamondsReceived: (data['monthlyDiamondsReceived'] ?? 0.0).toDouble(),
        dailyVoiceRoomMinutes: data['dailyVoiceRoomMinutes'] ?? 0,
        weeklyVoiceRoomMinutes: data['weeklyVoiceRoomMinutes'] ?? 0,
        monthlyVoiceRoomMinutes: data['monthlyVoiceRoomMinutes'] ?? 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyDiamondsSent': dailyDiamondsSent,
      'dailyDiamondsReceived': dailyDiamondsReceived,
      'weeklyDiamondsSent': weeklyDiamondsSent,
      'weeklyDiamondsReceived': weeklyDiamondsReceived,
      'monthlyDiamondsSent': monthlyDiamondsSent,
      'monthlyDiamondsReceived': monthlyDiamondsReceived,
      'dailyVoiceRoomMinutes': dailyVoiceRoomMinutes,
      'weeklyVoiceRoomMinutes': weeklyVoiceRoomMinutes,
      'monthlyVoiceRoomMinutes': monthlyVoiceRoomMinutes,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  UserActivityStats copyWith({
    double? dailyDiamondsSent,
    double? dailyDiamondsReceived,
    double? weeklyDiamondsSent,
    double? weeklyDiamondsReceived,
    double? monthlyDiamondsSent,
    double? monthlyDiamondsReceived,
    int? dailyVoiceRoomMinutes,
    int? weeklyVoiceRoomMinutes,
    int? monthlyVoiceRoomMinutes,
    DateTime? lastUpdated,
  }) {
    return UserActivityStats(
      dailyDiamondsSent: dailyDiamondsSent ?? this.dailyDiamondsSent,
      dailyDiamondsReceived: dailyDiamondsReceived ?? this.dailyDiamondsReceived,
      weeklyDiamondsSent: weeklyDiamondsSent ?? this.weeklyDiamondsSent,
      weeklyDiamondsReceived: weeklyDiamondsReceived ?? this.weeklyDiamondsReceived,
      monthlyDiamondsSent: monthlyDiamondsSent ?? this.monthlyDiamondsSent,
      monthlyDiamondsReceived: monthlyDiamondsReceived ?? this.monthlyDiamondsReceived,
      dailyVoiceRoomMinutes: dailyVoiceRoomMinutes ?? this.dailyVoiceRoomMinutes,
      weeklyVoiceRoomMinutes: weeklyVoiceRoomMinutes ?? this.weeklyVoiceRoomMinutes,
      monthlyVoiceRoomMinutes: monthlyVoiceRoomMinutes ?? this.monthlyVoiceRoomMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserPunishment {
  final String id;
  final String reason;
  final PunishmentType type;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final String issuedBy;
  final bool isActive;

  UserPunishment({
    required this.id,
    required this.reason,
    required this.type,
    required this.issuedAt,
    this.expiresAt,
    required this.issuedBy,
    this.isActive = true,
  });

  factory UserPunishment.fromMap(Map<String, dynamic> data) {
    try {
      return UserPunishment(
        id: data['id'] ?? '',
        reason: data['reason'] ?? '',
        type: PunishmentType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => PunishmentType.warning,
        ),
        issuedAt: data['issuedAt'] != null 
            ? (data['issuedAt'] as Timestamp).toDate()
            : DateTime.now(),
        expiresAt: data['expiresAt'] != null 
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
        issuedBy: data['issuedBy'] ?? '',
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      debugPrint('Error creating UserPunishment from map: $e');
      return UserPunishment(
        id: data['id'] ?? '',
        reason: data['reason'] ?? '',
        type: PunishmentType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => PunishmentType.warning,
        ),
        issuedAt: DateTime.now(),
        expiresAt: null,
        issuedBy: data['issuedBy'] ?? '',
        isActive: data['isActive'] ?? true,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'type': type.name,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'issuedBy': issuedBy,
      'isActive': isActive,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  UserPunishment copyWith({
    String? id,
    String? reason,
    PunishmentType? type,
    DateTime? issuedAt,
    DateTime? expiresAt,
    String? issuedBy,
    bool? isActive,
  }) {
    return UserPunishment(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      type: type ?? this.type,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      issuedBy: issuedBy ?? this.issuedBy,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum PunishmentType {
  voiceRoomBan,
  postBan,
  accountBan,
  deviceBan,
  warning,
  temporaryBlock,
  permanentBlock,
  suspension,
}

class UserHistoryEntry {
  final String id;
  final String userId;
  final HistoryType type;
  final double amount;
  final String? description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  UserHistoryEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.description,
    required this.timestamp,
    this.metadata,
  });

  factory UserHistoryEntry.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      return UserHistoryEntry(
        id: doc.id,
        userId: data['userId'] ?? '',
        type: HistoryType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => HistoryType.diamondSent,
        ),
        amount: (data['amount'] ?? 0.0).toDouble(),
        description: data['description'],
        timestamp: data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
        metadata: data['metadata'],
      );
    } catch (e) {
      debugPrint('Error creating UserHistoryEntry from Firestore: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toFirestore() {
    try {
      return {
        'userId': userId,
        'type': type.name,
        'amount': amount,
        'description': description,
        'timestamp': Timestamp.fromDate(timestamp),
        'metadata': metadata,
      };
    } catch (e) {
      debugPrint('Error converting UserHistoryEntry to Firestore: $e');
      rethrow;
    }
  }
}

enum HistoryType {
  diamondSent,
  diamondReceived,
  beanEarned,
  beanSpent,
  voiceRoomTime,
  levelUp,
  itemPurchased,
  itemAssigned,
}
