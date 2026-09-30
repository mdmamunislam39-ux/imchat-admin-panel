import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../models/store_item_model.dart';
import 'official_items_service.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  static const String _userProfilesCollection = 'Users';
  static const String _userHistoryCollection = 'user_history';
  static const String _marketItemsCollection = 'market_items';

  // User Profile CRUD Operations
  static Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userProfilesCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        debugPrint('No user profile found for userId: $userId');
        return null;
      }

      return UserProfileModel.fromFirestore(doc.docs.first);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Find user by searchId, userId, or doc id
  static Future<UserProfileModel?> findUserBySearchIdOrUid(String query) async {
    try {
      final clean = query.trim();
      if (clean.isEmpty) return null;

      // 1. By searchId
      final snapSearchId = await _firestore
          .collection(_userProfilesCollection)
          .where('searchId', isEqualTo: clean)
          .limit(1)
          .get();
      if (snapSearchId.docs.isNotEmpty) {
        return UserProfileModel.fromFirestore(snapSearchId.docs.first);
      }

      // 2. By userId
      final snapUserId = await _firestore
          .collection(_userProfilesCollection)
          .where('userId', isEqualTo: clean)
          .limit(1)
          .get();
      if (snapUserId.docs.isNotEmpty) {
        return UserProfileModel.fromFirestore(snapUserId.docs.first);
      }

      // 3. By Document ID
      final docSnap = await _firestore.collection(_userProfilesCollection).doc(clean).get();
      if (docSnap.exists) {
        return UserProfileModel.fromFirestore(docSnap);
      }

      return null;
    } catch (e) {
      debugPrint('Error finding user by searchId or UID: $e');
      return null;
    }
  }

  static Stream<List<UserProfileModel>> getUserProfilesStream({int limit = 50}) {
    return _firestore
        .collection(_userProfilesCollection)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfileModel.fromFirestore(doc))
          .toList();
    });
  }

  static Future<List<UserProfileModel>> getAllUserProfiles({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_userProfilesCollection)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final userProfiles = snapshot.docs
          .map((doc) => UserProfileModel.fromFirestore(doc))
          .toList();

      if (userProfiles.isEmpty) {
        return await _getUsersFromLegacyCollection();
      }

      return userProfiles;
    } catch (e) {
      debugPrint('Error getting all user profiles: $e');
      return await _getUsersFromLegacyCollection();
    }
  }

  static Future<List<UserProfileModel>> _getUsersFromLegacyCollection() async {
    try {
      final snapshot = await _firestore.collection('Users').get();
      final users = snapshot.docs.map((doc) => UserProfileModel.fromFirestore(doc)).toList();

      if (users.isEmpty) {
        return await _createDemoUsers();
      }

      return users;
    } catch (e) {
      debugPrint('Error getting users from legacy collection: $e');
      return await _createDemoUsers();
    }
  }

  static Future<List<UserProfileModel>> _createDemoUsers() async {
    try {
      final demoUsers = [
        UserProfileModel(
          id: 'demo_user_1',
          userId: 'demo_user_1',
          username: 'John Doe',
          totalDiamonds: 1500.0,
          totalBeans: 250.0,
          diamondsSent: 5000.0,
          diamondsReceived: 2000.0,
          sendingLevel: UserLevel(
            level: 3,
            currentProgress: 5000.0,
            requiredForNext: 10000.0,
            levelName: 'Level 3',
            lastUpdated: DateTime.now(),
          ),
          receivingLevel: UserLevel(
            level: 2,
            currentProgress: 2000.0,
            requiredForNext: 5000.0,
            levelName: 'Level 2',
            lastUpdated: DateTime.now(),
          ),
          giftingLevel: UserLevel(
            level: 1,
            currentProgress: 500.0,
            requiredForNext: 2000.0,
            levelName: 'Level 1',
            lastUpdated: DateTime.now(),
          ),
          userType: UserType.regular,
          customization: UserCustomization(),
          activityStats: UserActivityStats(
            dailyDiamondsSent: 5000.0,
            dailyDiamondsReceived: 2000.0,
            lastUpdated: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
        UserProfileModel(
          id: 'demo_user_2',
          userId: 'demo_user_2',
          username: 'Jane Smith',
          totalDiamonds: 3000.0,
          totalBeans: 500.0,
          diamondsSent: 15000.0,
          diamondsReceived: 8000.0,
          sendingLevel: UserLevel(
            level: 5,
            currentProgress: 15000.0,
            requiredForNext: 20000.0,
            levelName: 'Level 5',
            lastUpdated: DateTime.now(),
          ),
          receivingLevel: UserLevel(
            level: 4,
            currentProgress: 8000.0,
            requiredForNext: 15000.0,
            levelName: 'Level 4',
            lastUpdated: DateTime.now(),
          ),
          giftingLevel: UserLevel(
            level: 3,
            currentProgress: 3000.0,
            requiredForNext: 10000.0,
            levelName: 'Level 3',
            lastUpdated: DateTime.now(),
          ),
          userType: UserType.host,
          agencyId: 'agency_1',
          agencyName: 'Elite Agency',
          customization: UserCustomization(),
          activityStats: UserActivityStats(
            dailyDiamondsSent: 15000.0,
            dailyDiamondsReceived: 8000.0,
            lastUpdated: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 60)),
          updatedAt: DateTime.now(),
        ),
        UserProfileModel(
          id: 'demo_user_3',
          userId: 'demo_user_3',
          username: 'Mike Johnson',
          totalDiamonds: 500.0,
          totalBeans: 100.0,
          diamondsSent: 500.0,
          diamondsReceived: 1000.0,
          sendingLevel: UserLevel(
            level: 1,
            currentProgress: 500.0,
            requiredForNext: 1000.0,
            levelName: 'Level 1',
            lastUpdated: DateTime.now(),
          ),
          receivingLevel: UserLevel(
            level: 1,
            currentProgress: 1000.0,
            requiredForNext: 2000.0,
            levelName: 'Level 1',
            lastUpdated: DateTime.now(),
          ),
          giftingLevel: UserLevel(
            level: 1,
            currentProgress: 100.0,
            requiredForNext: 1000.0,
            levelName: 'Level 1',
            lastUpdated: DateTime.now(),
          ),
          userType: UserType.regular,
          customization: UserCustomization(),
          activityStats: UserActivityStats(
            dailyDiamondsSent: 500.0,
            dailyDiamondsReceived: 1000.0,
            lastUpdated: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now(),
        ),
        UserProfileModel(
          id: 'demo_user_4',
          userId: 'demo_user_4',
          username: 'Sarah Wilson',
          totalDiamonds: 2000.0,
          totalBeans: 350.0,
          diamondsSent: 8000.0,
          diamondsReceived: 4000.0,
          sendingLevel: UserLevel(
            level: 4,
            currentProgress: 8000.0,
            requiredForNext: 15000.0,
            levelName: 'Level 4',
            lastUpdated: DateTime.now(),
          ),
          receivingLevel: UserLevel(
            level: 3,
            currentProgress: 4000.0,
            requiredForNext: 8000.0,
            levelName: 'Level 3',
            lastUpdated: DateTime.now(),
          ),
          giftingLevel: UserLevel(
            level: 2,
            currentProgress: 2500.0,
            requiredForNext: 5000.0,
            levelName: 'Level 2',
            lastUpdated: DateTime.now(),
          ),
          userType: UserType.regular,
          customization: UserCustomization(),
          activityStats: UserActivityStats(
            dailyDiamondsSent: 8000.0,
            dailyDiamondsReceived: 4000.0,
            lastUpdated: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          updatedAt: DateTime.now(),
        ),
        UserProfileModel(
          id: 'demo_user_5',
          userId: 'demo_user_5',
          username: 'Alex Brown',
          totalDiamonds: 800.0,
          totalBeans: 150.0,
          diamondsSent: 2000.0,
          diamondsReceived: 1500.0,
          sendingLevel: UserLevel(
            level: 2,
            currentProgress: 2000.0,
            requiredForNext: 5000.0,
            levelName: 'Level 2',
            lastUpdated: DateTime.now(),
          ),
          receivingLevel: UserLevel(
            level: 2,
            currentProgress: 1500.0,
            requiredForNext: 4000.0,
            levelName: 'Level 2',
            lastUpdated: DateTime.now(),
          ),
          giftingLevel: UserLevel(
            level: 1,
            currentProgress: 800.0,
            requiredForNext: 2000.0,
            levelName: 'Level 1',
            lastUpdated: DateTime.now(),
          ),
          userType: UserType.host,
          agencyId: 'agency_2',
          agencyName: 'Star Agency',
          customization: UserCustomization(),
          activityStats: UserActivityStats(
            dailyDiamondsSent: 2000.0,
            dailyDiamondsReceived: 1500.0,
            lastUpdated: DateTime.now(),
          ),
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Save demo users to the database
      for (final user in demoUsers) {
        await createUserProfile(user);
      }

      debugPrint('Created ${demoUsers.length} demo users');
      return demoUsers.cast<UserProfileModel>();
    } catch (e) {
      debugPrint('Error creating demo users: $e');
      return [];
    }
  }

  static Future<bool> createUserProfile(UserProfileModel profile) async {
    try {
      await _firestore
          .collection(_userProfilesCollection)
          .doc(profile.id)
          .set(profile.toFirestore());

      debugPrint('User profile created successfully: ${profile.id}');
      return true;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return false;
    }
  }

  static Future<bool> updateUserProfile(UserProfileModel profile) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      // Update in the Users collection (not user_profiles)
      await _firestore
          .collection('Users')
          .doc(profile.id)
          .update(updatedProfile.toFirestore());

      debugPrint('User profile updated successfully: ${profile.id}');
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  static Future<bool> deleteUserProfile(String profileId) async {
    try {
      await _firestore
          .collection(_userProfilesCollection)
          .doc(profileId)
          .delete();

      debugPrint('User profile deleted successfully: $profileId');
      return true;
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      return false;
    }
  }

  // Diamond and Bean Management
  static Future<bool> updateDiamonds(
    String userId,
    double amount, {
    bool isAddition = true,
  }) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final newAmount = isAddition
          ? profile.totalDiamonds + amount
          : profile.totalDiamonds - amount;

      if (newAmount < 0) {
        debugPrint('Insufficient diamonds for user: $userId');
        return false;
      }

      final updatedProfile = profile.copyWith(
        totalDiamonds: newAmount,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating diamonds: $e');
      return false;
    }
  }

  static Future<bool> updateBeans(
    String userId,
    double amount, {
    bool isAddition = true,
  }) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final newAmount = isAddition
          ? profile.totalBeans + amount
          : profile.totalBeans - amount;

      if (newAmount < 0) {
        debugPrint('Insufficient beans for user: $userId');
        return false;
      }

      final updatedProfile = profile.copyWith(
        totalBeans: newAmount,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating beans: $e');
      return false;
    }
  }

  // Level System Management
  static Future<bool> updateSendingLevel(
    String userId,
    double diamondsSent,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final newSendingLevel = _calculateLevel(
        profile.sendingLevel,
        diamondsSent,
        LevelType.sending,
      );

      final updatedProfile = profile.copyWith(
        sendingLevel: newSendingLevel,
        diamondsSent: profile.diamondsSent + diamondsSent,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating sending level: $e');
      return false;
    }
  }

  static Future<bool> updateReceivingLevel(
    String userId,
    double diamondsReceived,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final newReceivingLevel = _calculateLevel(
        profile.receivingLevel,
        diamondsReceived,
        LevelType.receiving,
      );

      final updatedProfile = profile.copyWith(
        receivingLevel: newReceivingLevel,
        diamondsReceived: profile.diamondsReceived + diamondsReceived,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating receiving level: $e');
      return false;
    }
  }

  static UserLevel _calculateLevel(
    UserLevel currentLevel,
    double newAmount,
    LevelType type,
  ) {
    final totalProgress = currentLevel.currentProgress + newAmount;
    final levelConfig = _getLevelConfig(type);

    int newLevel = currentLevel.level;
    double requiredForNext = currentLevel.requiredForNext;

    // Calculate new level based on progress
    for (int i = currentLevel.level; i < levelConfig.length; i++) {
      if (totalProgress >= levelConfig[i]) {
        newLevel = i + 1;
        requiredForNext = i + 1 < levelConfig.length
            ? levelConfig[i + 1] - totalProgress
            : 0.0;
      } else {
        requiredForNext = levelConfig[i] - totalProgress;
        break;
      }
    }

    return currentLevel.copyWith(
      level: newLevel,
      currentProgress: totalProgress,
      requiredForNext: requiredForNext,
      levelName: 'Level $newLevel',
      lastUpdated: DateTime.now(),
    );
  }

  static List<double> _getLevelConfig(LevelType type) {
    // Sending levels: 1-1000, 1001-5000, 5001-15000, etc.
    // Receiving levels: 1-200, 201-1000, 1001-5000, etc.
    switch (type) {
      case LevelType.sending:
        return [1000, 5000, 15000, 50000, 100000, 500000, 1000000];
      case LevelType.receiving:
        return [200, 1000, 5000, 15000, 50000, 100000, 500000];
      case LevelType.gifting:
        return [500, 2500, 10000, 30000, 75000, 200000, 500000];
      case LevelType.room:
        return [5000, 10000, 15000, 20000, 25000, 30000, 50000];
    }
  }

  // Customization Management
  static Future<bool> updateUserCustomization(
    String userId,
    UserCustomization customization,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final updatedProfile = profile.copyWith(
        customization: customization,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating user customization: $e');
      return false;
    }
  }

  static Future<bool> addOwnedItem(
    String userId,
    String itemId,
    StoreItemType itemType,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      UserCustomization newCustomization = profile.customization;

      switch (itemType) {
        case StoreItemType.badge:
          if (!profile.customization.ownedBadges.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedBadges: [...profile.customization.ownedBadges, itemId],
            );
          }
          break;
        case StoreItemType.avatarFrame:
          if (!profile.customization.ownedFrames.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedFrames: [...profile.customization.ownedFrames, itemId],
            );
          }
          break;
        case StoreItemType.entryEffect:
          if (!profile.customization.ownedEntryEffects.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedEntryEffects: [
                ...profile.customization.ownedEntryEffects,
                itemId,
              ],
            );
          }
          break;
        case StoreItemType.backgroundTheme:
          if (!profile.customization.ownedBackgroundThemes.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedBackgroundThemes: [
                ...profile.customization.ownedBackgroundThemes,
                itemId,
              ],
            );
          }
          break;
        case StoreItemType.roomProfileBackground:
          if (!profile.customization.ownedRoomProfileBackgrounds.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedRoomProfileBackgrounds: [
                ...profile.customization.ownedRoomProfileBackgrounds,
                itemId,
              ],
            );
          }
          break;
        case StoreItemType.shortProfileTheme:
          if (!profile.customization.ownedShortProfileThemes.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedShortProfileThemes: [
                ...profile.customization.ownedShortProfileThemes,
                itemId,
              ],
            );
          }
          break;
        case StoreItemType.roomTheme:
        case StoreItemType.seatDecor:
          // Currently not explicitly stored in UserCustomization, or handled differently
          break;
        case StoreItemType.micRefill:
          if (!profile.customization.ownedMicRefills.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedMicRefills: [
                ...profile.customization.ownedMicRefills,
                itemId,
              ],
            );
          }
          break;
        case StoreItemType.roomEntry:
          if (!profile.customization.ownedRoomEntries.contains(itemId)) {
            newCustomization = newCustomization.copyWith(
              ownedRoomEntries: [
                ...profile.customization.ownedRoomEntries,
                itemId,
              ],
            );
          }
          break;
      }

      return await updateUserCustomization(userId, newCustomization);
    } catch (e) {
      debugPrint('Error adding owned item: $e');
      return false;
    }
  }

  // Activity Stats Management
  static Future<bool> updateActivityStats(
    String userId,
    UserActivityStats stats,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final updatedProfile = profile.copyWith(
        activityStats: stats,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating activity stats: $e');
      return false;
    }
  }

  static Future<bool> recordDiamondTransaction(
    String userId,
    double amount,
    bool isSent,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final now = DateTime.now();
      final stats = profile.activityStats;

      // Update daily stats
      final updatedStats = stats.copyWith(
        dailyDiamondsSent: isSent
            ? stats.dailyDiamondsSent + amount
            : stats.dailyDiamondsSent,
        dailyDiamondsReceived: !isSent
            ? stats.dailyDiamondsReceived + amount
            : stats.dailyDiamondsReceived,
        lastUpdated: now,
      );

      // Record in history
      await _recordHistoryEntry(
        userId,
        isSent ? HistoryType.diamondSent : HistoryType.diamondReceived,
        amount,
        'Diamond ${isSent ? 'sent' : 'received'}',
      );

      return await updateActivityStats(userId, updatedStats);
    } catch (e) {
      debugPrint('Error recording diamond transaction: $e');
      return false;
    }
  }

  // Blocked Users Management
  static Future<bool> blockUser(String userId, String blockedUserId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      if (profile.blockedUserIds.contains(blockedUserId)) {
        debugPrint('User already blocked');
        return true;
      }

      final updatedProfile = profile.copyWith(
        blockedUserIds: [...profile.blockedUserIds, blockedUserId],
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  static Future<bool> unblockUser(String userId, String blockedUserId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final updatedBlockedList = profile.blockedUserIds
          .where((id) => id != blockedUserId)
          .toList();

      final updatedProfile = profile.copyWith(
        blockedUserIds: updatedBlockedList,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  // Punishment System
  static Future<bool> addPunishment(
    String userId,
    UserPunishment punishment,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final updatedPunishments = [...profile.punishments, punishment];
      final updatedProfile = profile.copyWith(
        punishments: updatedPunishments,
        status: punishment.type == PunishmentType.permanentBlock
            ? UserStatus.blocked
            : punishment.type == PunishmentType.suspension
            ? UserStatus.suspended
            : profile.status,
        updatedAt: DateTime.now(),
      );

      return await updateUserProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error adding punishment: $e');
      return false;
    }
  }

  // History Management
  static Future<List<UserHistoryEntry>> getUserHistory(
    String userId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection(_userHistoryCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserHistoryEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user history: $e');
      return [];
    }
  }

  static Future<bool> _recordHistoryEntry(
    String userId,
    HistoryType type,
    double amount,
    String description,
  ) async {
    try {
      final entry = UserHistoryEntry(
        id: _firestore.collection(_userHistoryCollection).doc().id,
        userId: userId,
        type: type,
        amount: amount,
        description: description,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection(_userHistoryCollection)
          .doc(entry.id)
          .set(entry.toFirestore());

      return true;
    } catch (e) {
      debugPrint('Error recording history entry: $e');
      return false;
    }
  }

  // Market Items Management
  static Future<bool> createMarketItem(StoreItemModel item) async {
    try {
      final displayId = await OfficialItemsService.generateNextDisplayId();
      final updatedItem = item.copyWith(displayId: displayId);

      await _firestore
          .collection(_marketItemsCollection)
          .doc(updatedItem.id)
          .set(updatedItem.toFirestore());

      debugPrint('Market item created successfully: ${updatedItem.id} (displayId: $displayId)');
      return true;
    } catch (e) {
      debugPrint('Error creating market item: $e');
      return false;
    }
  }

  static Future<List<StoreItemModel>> getMarketItems({
    StoreItemType? type,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_marketItemsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting market items: $e');
      return [];
    }
  }

  static Stream<List<StoreItemModel>> streamAllMarketItems({StoreItemType? type}) {
    Query query = _firestore.collection(_marketItemsCollection);
        
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }
    
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map((doc) {
        try {
          return StoreItemModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing store item \${doc.id}: \$e');
          return null;
        }
      }).whereType<StoreItemModel>().toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  // File Upload for Market Items
  static Future<String?> uploadMarketItemFile(
    Uint8List fileData,
    String fileName,
    String itemId,
  ) async {
    try {
      final ref = _storage.ref().child('market_items/$itemId/$fileName');
      final uploadTask = await ref.putData(fileData);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Store Item Management
  static Future<bool> updateStoreItem(StoreItemModel item) async {
    try {
      await _firestore
          .collection(_marketItemsCollection)
          .doc(item.id)
          .update(item.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error updating store item: $e');
      return false;
    }
  }

  static Future<bool> deleteStoreItem(String itemId) async {
    try {
      await _firestore.collection(_marketItemsCollection).doc(itemId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting store item: $e');
      return false;
    }
  }

  // Search and Filter
  static Future<List<UserProfileModel>> searchUsers(
    String query, {
    UserType? userType,
    UserStatus? status,
    int limit = 20,
  }) async {
    try {
      // First try to search by searchId in the Users collection
      if (query.isNotEmpty) {
        final searchIdQuery = await _firestore
            .collection('Users')
            .where('searchId', isEqualTo: query)
            .limit(limit)
            .get();

        if (searchIdQuery.docs.isNotEmpty) {
          return searchIdQuery.docs.map((doc) => UserProfileModel.fromFirestore(doc)).toList();
        }
      }

      // Fallback to regular search by username
      Query queryBuilder = _firestore.collection('Users').limit(limit);

      final snapshot = await queryBuilder.get();
      final profiles = snapshot.docs.map((doc) => UserProfileModel.fromFirestore(doc)).toList();

      // Filter by username if query is provided
      if (query.isNotEmpty) {
        return profiles
            .where(
              (profile) =>
                  profile.username.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  (profile.searchId != null &&
                      profile.searchId!.contains(query)),
            )
            .toList().cast<UserProfileModel>();
      }

      return profiles.cast<UserProfileModel>();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  // Statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final snapshot = await _firestore
          .collection(_userProfilesCollection)
          .get();
      final profiles = snapshot.docs
          .map((doc) => UserProfileModel.fromFirestore(doc))
          .toList();

      int totalUsers = profiles.length;
      int activeUsers = profiles
          .where((p) => p.status == UserStatus.active)
          .length;
      int blockedUsers = profiles
          .where((p) => p.status == UserStatus.blocked)
          .length;
      int hosts = profiles.where((p) => p.userType == UserType.host).length;
      int sellers = profiles.where((p) => p.userType == UserType.seller).length;

      double totalDiamonds = profiles.fold(
        0.0,
        (total, p) => total + p.totalDiamonds,
      );
      double totalBeans = profiles.fold(0.0, (total, p) => total + p.totalBeans);

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'blockedUsers': blockedUsers,
        'hosts': hosts,
        'sellers': sellers,
        'totalDiamonds': totalDiamonds,
        'totalBeans': totalBeans,
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }
}
