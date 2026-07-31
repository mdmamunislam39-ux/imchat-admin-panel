import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/official_item_model.dart';
import '../models/store_item_model.dart';
import '../models/agency_notification_model.dart';
import 'notification_service.dart';

class OfficialItemsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _officialItemsCollection = 'official_items';
  static const String _marketItemsCollection = 'market_items';
  static const String _userStoreItemsCollection = 'user_store_items';
  static const String _usersCollection = 'Users';

  // ─── CRUD: Official Items ───

  /// Map OfficialItemCategory to the string type used in market_items
  static String _categoryToMarketType(OfficialItemCategory category) {
    switch (category) {
      case OfficialItemCategory.badge:
        return 'badge';
      case OfficialItemCategory.avatarFrame:
        return 'avatarFrame';
      case OfficialItemCategory.entryEffect:
        return 'entryEffect';
      case OfficialItemCategory.backgroundTheme:
        return 'backgroundTheme';
      case OfficialItemCategory.profileSkin:
        return 'profileSkin';
      case OfficialItemCategory.nameplate:
        return 'nameplate';
      case OfficialItemCategory.micRefill:
        return 'micRefill';
      case OfficialItemCategory.seatDecor:
        return 'seatDecor';
      case OfficialItemCategory.roomProfileBackground:
        return 'roomProfileBackground';
    }
  }

  static Future<int> generateNextDisplayId() async {
    try {
      int maxMarketId = 10000;
      int maxOfficialId = 10000;

      final marketQuery = await _firestore
          .collection(_marketItemsCollection)
          .orderBy('displayId', descending: true)
          .limit(1)
          .get();
      if (marketQuery.docs.isNotEmpty) {
        final data = marketQuery.docs.first.data();
        if (data['displayId'] != null) {
          maxMarketId = (data['displayId'] as num).toInt();
        }
      }

      final officialQuery = await _firestore
          .collection(_officialItemsCollection)
          .orderBy('displayId', descending: true)
          .limit(1)
          .get();
      if (officialQuery.docs.isNotEmpty) {
        final data = officialQuery.docs.first.data();
        if (data['displayId'] != null) {
          maxOfficialId = (data['displayId'] as num).toInt();
        }
      }

      return (maxMarketId > maxOfficialId ? maxMarketId : maxOfficialId) + 1;
    } catch (e) {
      debugPrint('Error generating displayId with order: $e');
      try {
        final marketSnapshot = await _firestore.collection(_marketItemsCollection).get();
        int maxId = 10000;
        for (final doc in marketSnapshot.docs) {
          final data = doc.data();
          if (data['displayId'] != null) {
            final val = (data['displayId'] as num).toInt();
            if (val > maxId) maxId = val;
          }
        }
        final officialSnapshot = await _firestore.collection(_officialItemsCollection).get();
        for (final doc in officialSnapshot.docs) {
          final data = doc.data();
          if (data['displayId'] != null) {
            final val = (data['displayId'] as num).toInt();
            if (val > maxId) maxId = val;
          }
        }
        return maxId + 1;
      } catch (innerE) {
        debugPrint('Fallback generation also failed: $innerE');
        return 10001;
      }
    }
  }

  /// Ensure all existing official and market items have a displayId (starting from 10001).
  /// This will assign IDs sequentially by their createdAt timestamps.
  static Future<void> ensureAllItemsHaveIds() async {
    try {
      final marketSnapshot = await _firestore.collection(_marketItemsCollection).get();
      final officialSnapshot = await _firestore.collection(_officialItemsCollection).get();

      final Map<String, Map<String, dynamic>> marketItemsMap = {};
      for (final doc in marketSnapshot.docs) {
        marketItemsMap[doc.id] = doc.data();
      }

      final Map<String, Map<String, dynamic>> officialItemsMap = {};
      for (final doc in officialSnapshot.docs) {
        officialItemsMap[doc.id] = doc.data();
      }

      final Set<String> allIds = {...marketItemsMap.keys, ...officialItemsMap.keys};

      final Map<String, int> assignedDisplayIds = {};
      int maxAssignedId = 10000;

      for (final id in allIds) {
        int? displayId;
        final marketData = marketItemsMap[id];
        if (marketData != null && marketData['displayId'] != null) {
          displayId = (marketData['displayId'] as num).toInt();
        }
        final officialData = officialItemsMap[id];
        if (officialData != null && officialData['displayId'] != null) {
          final offId = (officialData['displayId'] as num).toInt();
          if (displayId == null || offId > displayId) {
            displayId = offId;
          }
        }

        if (displayId != null) {
          assignedDisplayIds[id] = displayId;
          if (displayId > maxAssignedId) {
            maxAssignedId = displayId;
          }
        }
      }

      final List<String> unassignedIds = allIds.where((id) => !assignedDisplayIds.containsKey(id)).toList();

      if (unassignedIds.isEmpty) {
        debugPrint('All items already have a displayId.');
        return;
      }

      unassignedIds.sort((a, b) {
        DateTime getCreatedAt(String id) {
          final marketData = marketItemsMap[id];
          if (marketData != null && marketData['createdAt'] != null) {
            final ts = marketData['createdAt'];
            if (ts is Timestamp) return ts.toDate();
            if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
          }
          final officialData = officialItemsMap[id];
          if (officialData != null && officialData['createdAt'] != null) {
            final ts = officialData['createdAt'];
            if (ts is Timestamp) return ts.toDate();
            if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
          }
          return DateTime.now();
        }
        return getCreatedAt(a).compareTo(getCreatedAt(b));
      });

      int nextId = maxAssignedId + 1;
      final WriteBatch batch = _firestore.batch();

      for (final id in unassignedIds) {
        final currentId = nextId++;
        
        if (marketItemsMap.containsKey(id)) {
          batch.update(
            _firestore.collection(_marketItemsCollection).doc(id),
            {'displayId': currentId},
          );
        }
        if (officialItemsMap.containsKey(id)) {
          batch.update(
            _firestore.collection(_officialItemsCollection).doc(id),
            {'displayId': currentId},
          );
        }
      }

      await batch.commit();
      debugPrint('Assigned displayId to ${unassignedIds.length} items. Next available ID: $nextId');
    } catch (e) {
      debugPrint('Error running ensureAllItemsHaveIds migration: $e');
    }
  }

  /// Create a new official item — writes to both official_items (admin catalog)
  /// AND market_items (so mobile app's getStoreItemDetails() can find it)
  static Future<String?> createOfficialItem({
    required String name,
    required String description,
    required OfficialItemCategory category,
    required String fileUrl,
    required String fileName,
    required String fileType,
    int starRating = 1,
    String? thumbnailUrl,
    String? lockedFileUrl,
    double diamondPrice = 0,
    int? expirationDuration,
  }) async {
    try {
      // Use the same doc ID for both collections
      final docId = _firestore.collection(_officialItemsCollection).doc().id;
      final displayId = await generateNextDisplayId();

      // 1. Write to official_items (admin catalog)
      final item = OfficialItemModel(
        id: docId,
        name: name,
        description: description,
        category: category,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        thumbnailUrl: thumbnailUrl,
        lockedFileUrl: lockedFileUrl,
        starRating: starRating,
        isActive: true,
        createdAt: DateTime.now(),
        displayId: displayId,
      );

      await _firestore
          .collection(_officialItemsCollection)
          .doc(docId)
          .set(item.toFirestore());

      // 2. Also write to market_items so mobile app can fetch details
      await _firestore
          .collection(_marketItemsCollection)
          .doc(docId)
          .set({
        'name': name,
        'description': description,
        'type': _categoryToMarketType(category),
        'category': 'official',
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'thumbnailUrl': thumbnailUrl,
        if (lockedFileUrl != null) 'lockedFileUrl': lockedFileUrl,
        'imageUrl': thumbnailUrl ?? fileUrl,
        'starRating': starRating,
        'diamondPrice': diamondPrice,
        'expirationDuration': expirationDuration,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return docId;
    } catch (e) {
      debugPrint('Error creating official item: $e');
      return null;
    }
  }

  /// Update an existing official item
  static Future<bool> updateOfficialItem({
    required String itemId,
    required String name,
    required String description,
    required OfficialItemCategory category,
    required String fileUrl,
    required String fileName,
    required String fileType,
    int starRating = 1,
    String? thumbnailUrl,
    String? lockedFileUrl,
    double diamondPrice = 0,
    int? expirationDuration,
  }) async {
    try {
      final updateData = {
        'name': name,
        'description': description,
        'category': category.name,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        'starRating': starRating,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (lockedFileUrl != null) 'lockedFileUrl': lockedFileUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_officialItemsCollection)
          .doc(itemId)
          .update(updateData);

      final marketUpdateData = {
        'name': name,
        'description': description,
        'type': _categoryToMarketType(category),
        'fileUrl': fileUrl,
        'fileName': fileName,
        'fileType': fileType,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (lockedFileUrl != null) 'lockedFileUrl': lockedFileUrl,
        'diamondPrice': diamondPrice,
        if (expirationDuration != null) 'expirationDuration': expirationDuration,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection(_marketItemsCollection)
          .doc(itemId)
          .update(marketUpdateData);

      debugPrint('Official item updated in both collections: $itemId');
      return true;
    } catch (e) {
      debugPrint('Error updating official item: $e');
      return false;
    }
  }

  /// Get all official items
  static Future<List<OfficialItemModel>> getAllOfficialItems() async {
    try {
      final snapshot = await _firestore
          .collection(_officialItemsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OfficialItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting official items: $e');
      return [];
    }
  }

  /// Get official items by category
  static Future<List<OfficialItemModel>> getItemsByCategory(
      OfficialItemCategory category) async {
    try {
      final snapshot = await _firestore
          .collection(_officialItemsCollection)
          .where('category', isEqualTo: category.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OfficialItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting items by category: $e');
      return [];
    }
  }

  /// Toggle item active status in both collections
  static Future<bool> toggleItemStatus(String itemId, bool isActive) async {
    try {
      await _firestore
          .collection(_officialItemsCollection)
          .doc(itemId)
          .update({'isActive': isActive});
      await _firestore
          .collection(_marketItemsCollection)
          .doc(itemId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      debugPrint('Error toggling item status: $e');
      return false;
    }
  }

  /// Delete an official item from both collections
  static Future<bool> deleteOfficialItem(String itemId) async {
    try {
      await _firestore
          .collection(_officialItemsCollection)
          .doc(itemId)
          .delete();
      await _firestore
          .collection(_marketItemsCollection)
          .doc(itemId)
          .delete();
      debugPrint('Official item deleted from both collections: $itemId');
      return true;
    } catch (e) {
      debugPrint('Error deleting official item: $e');
      return false;
    }
  }

  // ─── User Search ───

  /// Search user by profile ID (searchId field)
  static Future<Map<String, dynamic>?> searchUserByProfileId(
      String profileId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('searchId', isEqualTo: profileId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullname'] ?? '',
          'profileId': data['searchId'] ?? '',
          'phone': data['number'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  // ─── Assignment ───

  /// Assign an official item to a user — writes to user_store_items
  /// in the exact same format the mobile app expects
  static Future<bool> assignItemToUser({
    required String officialItemId,
    required String itemName,
    required OfficialItemCategory itemCategory,
    required String userId,
    required String userProfileId,
    required String username,
    required int durationDays,
    required String adminId,
  }) async {
    try {
      final itemType = _categoryToMarketType(itemCategory);

      // Check if user already has this item
      final existingQuery = await _firestore
          .collection(_userStoreItemsCollection)
          .where('userId', isEqualTo: userId)
          .where('storeItemId', isEqualTo: officialItemId)
          .limit(1)
          .get();

      String docId;
      DateTime expiresAt;

      if (existingQuery.docs.isNotEmpty) {
        // Item already exists, add duration to existing expiresAt
        final existingDoc = existingQuery.docs.first;
        final existingData = existingDoc.data();
        final currentExpiry = (existingData['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // If it's already expired, start from now. Otherwise, add to existing expiry.
        final baseDate = currentExpiry.isAfter(DateTime.now()) ? currentExpiry : DateTime.now();
        expiresAt = baseDate.add(Duration(days: durationDays));
        docId = existingDoc.id;

        await _firestore.collection(_userStoreItemsCollection).doc(docId).update({
          'expiresAt': Timestamp.fromDate(expiresAt),
          'isActive': true,
          'assignedAt': FieldValue.serverTimestamp(),
          'assignedBy': adminId,
        });
      } else {
        // Create new item
        expiresAt = DateTime.now().add(Duration(days: durationDays));
        docId = _firestore.collection(_userStoreItemsCollection).doc().id;
        
        final userStoreItemData = {
          'id': docId,
          'userId': userId,
          'storeItemId': officialItemId, // points to market_items doc
          'storeItemName': itemName,
          'itemType': itemType, // string like 'badge', 'avatarFrame', etc.
          'assignedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'isActive': true,
          'assignedBy': adminId,
        };

        await _firestore
            .collection(_userStoreItemsCollection)
            .doc(docId)
            .set(userStoreItemData);
      }

      // Update UserProfileModel customization
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final customizationMap = userData['customization'] as Map<String, dynamic>? ?? {};
        
        List<String> ownedList = [];
        String selectedField = '';
        String ownedField = '';

        if (itemCategory == OfficialItemCategory.badge) {
          ownedField = 'ownedBadges';
          selectedField = 'selectedBadgeId';
        } else if (itemCategory == OfficialItemCategory.avatarFrame) {
          ownedField = 'ownedFrames';
          selectedField = 'selectedFrameId';
        } else if (itemCategory == OfficialItemCategory.entryEffect) {
          ownedField = 'ownedEntryEffects';
          selectedField = 'selectedEntryEffectId';
        } else if (itemCategory == OfficialItemCategory.backgroundTheme) {
          ownedField = 'ownedBackgroundThemes';
          selectedField = 'selectedBackgroundThemeId';
        } else if (itemCategory == OfficialItemCategory.nameplate) {
          ownedField = 'ownedNameplates';
          selectedField = 'selectedNameplateId';
        } else if (itemCategory == OfficialItemCategory.micRefill) {
          ownedField = 'ownedMicRefills';
          selectedField = 'selectedMicRefillId';
        }

        if (ownedField.isNotEmpty) {
          ownedList = List<String>.from(customizationMap[ownedField] ?? []);
          if (!ownedList.contains(officialItemId)) {
            ownedList.add(officialItemId);
            customizationMap[ownedField] = ownedList;
            // Optionally auto-select the new item
            customizationMap[selectedField] = officialItemId;
            
            await _firestore.collection(_usersCollection).doc(userId).update({
              'customization': customizationMap,
            });
          }
        }
      }

      // Send notification to user
      await NotificationService.sendNotificationToHost(
        hostId: userId,
        title: 'New Item Assigned!',
        message:
            'You have been assigned "$itemName" (${itemCategory.displayName}) for $durationDays days. Enjoy!',
        type: NotificationType.general,
        data: {
          'assignmentId': docId,
          'itemName': itemName,
          'itemCategory': itemCategory.name,
          'durationDays': durationDays,
          'expiresAt': expiresAt.toIso8601String(),
          'action': 'view_item',
        },
      );

      debugPrint(
          'Official item "$itemName" assigned to $username for $durationDays days');
      return true;
    } catch (e) {
      debugPrint('Error assigning official item: $e');
      return false;
    }
  }

  /// Remove an assignment from user_store_items
  static Future<bool> removeAssignment(String assignmentId) async {
    try {
      await _firestore
          .collection(_userStoreItemsCollection)
          .doc(assignmentId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error removing assignment: $e');
      return false;
    }
  }

  /// Get all assignments for a user from user_store_items
  static Future<List<UserStoreItemModel>> getUserAssignments(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userStoreItemsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('assignedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserStoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user assignments: $e');
      return [];
    }
  }

  /// Get statistics for overview
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final itemsSnapshot =
          await _firestore.collection(_officialItemsCollection).get();
      final assignmentsSnapshot =
          await _firestore.collection(_userStoreItemsCollection).get();

      final categoryCounts = <String, int>{};
      for (final cat in OfficialItemCategory.values) {
        categoryCounts[cat.name] = itemsSnapshot.docs
            .where((doc) => doc.data()['category'] == cat.name)
            .length;
      }

      int activeAssignments = 0;
      for (final doc in assignmentsSnapshot.docs) {
        final data = doc.data();
        if (data['isActive'] == true) {
          final expiresAt = data['expiresAt'];
          if (expiresAt == null) {
            activeAssignments++; // permanent item
          } else {
            final expiry = (expiresAt as Timestamp).toDate();
            if (DateTime.now().isBefore(expiry)) {
              activeAssignments++;
            }
          }
        }
      }

      return {
        'totalItems': itemsSnapshot.docs.length,
        'totalAssignments': assignmentsSnapshot.docs.length,
        'activeAssignments': activeAssignments,
        'categoryCounts': categoryCounts,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }
}
