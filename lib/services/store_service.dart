import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../models/store_item_model.dart';

class StoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _storeItemsCollection = 'market_items';
  static const String _userStoreItemsCollection = 'user_store_items';
  static const String _usersCollection = 'Users';

  // Create a new store item
  static Future<String?> createStoreItem({
    required String name,
    required String description,
    required StoreItemType type,
    required StoreCategory category,
    required String fileUrl,
    required String fileName,
    required String fileType,
    required double diamondPrice,
    required int expirationDuration,
    int starRating = 1,
    String? thumbnailUrl,
    String? lockedFileUrl,
    Map<String, dynamic>? metadata,
    String? adminId,
  }) async {
    try {
      final itemId = _firestore.collection(_storeItemsCollection).doc().id;
      final now = DateTime.now();
      
      final storeItem = StoreItemModel(
        id: itemId,
        name: name,
        description: description,
        type: type,
        category: category,
        fileUrl: fileUrl,
        fileName: fileName,
        fileType: fileType,
        diamondPrice: diamondPrice,
        expirationDuration: expirationDuration,
        starRating: starRating,
        isActive: true,
        createdAt: now,
        updatedAt: now,
        thumbnailUrl: thumbnailUrl,
        lockedFileUrl: lockedFileUrl,
        metadata: metadata,
      );

      await _firestore.collection(_storeItemsCollection).doc(itemId).set(storeItem.toFirestore());

      debugPrint('Store item created successfully: $itemId');
      return itemId;
    } catch (e) {
      debugPrint('Error creating store item: $e');
      return null;
    }
  }

  // Get all store items
  static Future<List<StoreItemModel>> getAllStoreItems() async {
    try {
      final querySnapshot = await _firestore
          .collection(_storeItemsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all store items: $e');
      return [];
    }
  }

  // Get store items by category
  static Future<List<StoreItemModel>> getStoreItemsByCategory(StoreCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_storeItemsCollection)
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting store items by category: $e');
      return [];
    }
  }

  // Get store items by type
  static Future<List<StoreItemModel>> getStoreItemsByType(StoreItemType type) async {
    try {
      final querySnapshot = await _firestore
          .collection(_storeItemsCollection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => StoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting store items by type: $e');
      return [];
    }
  }

  // Get store item by ID
  static Future<StoreItemModel?> getStoreItemById(String itemId) async {
    try {
      final doc = await _firestore.collection(_storeItemsCollection).doc(itemId).get();
      if (doc.exists) {
        return StoreItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting store item by ID: $e');
      return null;
    }
  }

  // Update store item
  static Future<bool> updateStoreItem({
    required String itemId,
    String? name,
    String? description,
    double? diamondPrice,
    int? expirationDuration,
    int? starRating,
    bool? isActive,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (diamondPrice != null) updateData['diamondPrice'] = diamondPrice;
      if (expirationDuration != null) updateData['expirationDuration'] = expirationDuration;
      if (starRating != null) updateData['starRating'] = starRating;
      if (isActive != null) updateData['isActive'] = isActive;
      if (thumbnailUrl != null) updateData['thumbnailUrl'] = thumbnailUrl;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore.collection(_storeItemsCollection).doc(itemId).update(updateData);

      debugPrint('Store item updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating store item: $e');
      return false;
    }
  }

  // Delete store item
  static Future<bool> deleteStoreItem(String itemId) async {
    try {
      await _firestore.collection(_storeItemsCollection).doc(itemId).delete();
      debugPrint('Store item deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting store item: $e');
      return false;
    }
  }

  // Assign store item to user
  static Future<bool> assignItemToUser({
    required String storeItemId,
    required String userId,
    required String userProfileId,
    required String adminId,
  }) async {
    try {
      // Get store item details
      final storeItem = await getStoreItemById(storeItemId);
      if (storeItem == null) {
        debugPrint('Store item not found');
        return false;
      }

      // Check if user exists
      final userDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('User not found');
        return false;
      }

      final now = DateTime.now();
      final expiresAt = storeItem.isPermanent 
          ? null 
          : now.add(Duration(days: storeItem.expirationDuration));

      final userStoreItem = UserStoreItemModel(
        id: _firestore.collection(_userStoreItemsCollection).doc().id,
        userId: userId,
        userProfileId: userProfileId,
        storeItemId: storeItemId,
        storeItemName: storeItem.name,
        itemType: storeItem.type,
        assignedAt: now,
        expiresAt: expiresAt,
        isActive: true,
        assignedBy: adminId,
      );

      await _firestore.collection(_userStoreItemsCollection).doc(userStoreItem.id).set(userStoreItem.toFirestore());

      debugPrint('Store item assigned to user successfully');
      return true;
    } catch (e) {
      debugPrint('Error assigning store item to user: $e');
      return false;
    }
  }

  // Get user's store items
  static Future<List<UserStoreItemModel>> getUserStoreItems(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_userStoreItemsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('assignedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserStoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user store items: $e');
      return [];
    }
  }

  // Get user's store items by profile ID
  static Future<List<UserStoreItemModel>> getUserStoreItemsByProfileId(String userProfileId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_userStoreItemsCollection)
          .where('userProfileId', isEqualTo: userProfileId)
          .orderBy('assignedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserStoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user store items by profile ID: $e');
      return [];
    }
  }

  // Get all user store items (for admin view)
  static Future<List<UserStoreItemModel>> getAllUserStoreItems() async {
    try {
      final querySnapshot = await _firestore
          .collection(_userStoreItemsCollection)
          .orderBy('assignedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserStoreItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all user store items: $e');
      return [];
    }
  }

  // Remove store item from user
  static Future<bool> removeItemFromUser(String userStoreItemId) async {
    try {
      await _firestore.collection(_userStoreItemsCollection).doc(userStoreItemId).delete();
      debugPrint('Store item removed from user successfully');
      return true;
    } catch (e) {
      debugPrint('Error removing store item from user: $e');
      return false;
    }
  }

  // Search user by profile ID or Document ID
  static Future<Map<String, dynamic>?> searchUserByProfileId(String profileId) async {
    try {
      // First try searching by searchId
      var querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('searchId', isEqualTo: profileId)
          .limit(1)
          .get();

      DocumentSnapshot? userDoc;

      if (querySnapshot.docs.isNotEmpty) {
        userDoc = querySnapshot.docs.first;
      } else {
        // Fallback: Try searching by Document ID directly
        final docRef = await _firestore.collection(_usersCollection).doc(profileId).get();
        if (docRef.exists) {
          userDoc = docRef;
        }
      }

      if (userDoc != null && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          'id': userDoc.id,
          'name': userData['fullname'] ?? userData['username'] ?? '',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? userData['phone'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error searching user by profile ID: $e');
      return null;
    }
  }

  // Get store statistics
  static Future<Map<String, int>> getStoreStatistics() async {
    try {
      final storeItems = await getAllStoreItems();
      final userStoreItems = await getAllUserStoreItems();

      return {
        'totalItems': storeItems.length,
        'storeItems': storeItems.where((item) => item.category == StoreCategory.store).length,
        'officialStoreItems': storeItems.where((item) => item.category == StoreCategory.officialStore).length,
        'avatarFrames': storeItems.where((item) => item.type == StoreItemType.avatarFrame).length,
        'entryEffects': storeItems.where((item) => item.type == StoreItemType.entryEffect).length,
        'badges': storeItems.where((item) => item.type == StoreItemType.badge).length,
        'backgroundThemes': storeItems.where((item) => item.type == StoreItemType.backgroundTheme).length,
        'micRefills': storeItems.where((item) => item.type == StoreItemType.micRefill).length,
        'totalAssignments': userStoreItems.length,
        'activeAssignments': userStoreItems.where((item) => item.isActive && !item.isExpired).length,
      };
    } catch (e) {
      debugPrint('Error getting store statistics: $e');
      return {};
    }
  }

  // Get supported file types for each item type
  static List<String> getSupportedFileTypes(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return ['.svga', '.gif', '.png'];
      case StoreItemType.entryEffect:
        return ['.svga', '.gif', '.image', '.png', '.mp4'];
      case StoreItemType.badge:
        return ['.svga', '.gif', '.image', '.png'];
      case StoreItemType.backgroundTheme:
        return ['.svga'];
      case StoreItemType.roomTheme:
        return ['.svga', '.gif', '.image'];
      case StoreItemType.seatDecor:
        return ['.png'];
      case StoreItemType.micRefill:
        return ['.svga'];
      case StoreItemType.roomProfileBackground:
        return ['.svga', '.gif', '.png', '.image'];
    }
  }

  // Validate file type
  static bool isValidFileType(String fileName, StoreItemType type) {
    final supportedTypes = getSupportedFileTypes(type);
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    return supportedTypes.contains(extension);
  }

  // Analytics Methods
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final storeItemsSnapshot = await FirebaseFirestore.instance
          .collection('store_items')
          .get();
      
      final userItemsSnapshot = await FirebaseFirestore.instance
          .collection('user_store_items')
          .get();

      final totalItems = storeItemsSnapshot.docs.length;
      final totalAssignments = userItemsSnapshot.docs.length;
      
      // Calculate revenue (mock data for now)
      final totalRevenue = userItemsSnapshot.docs.fold<double>(0, (total, doc) {
        final data = doc.data();
        return total + (data['price'] ?? 0.0);
      });

      // Calculate trends (mock data for now)
      final revenueTrend = (math.Random().nextDouble() - 0.5) * 20; // -10% to +10%
      final userTrend = (math.Random().nextDouble() - 0.5) * 15;
      final salesTrend = (math.Random().nextDouble() - 0.5) * 25;
      final conversionTrend = (math.Random().nextDouble() - 0.5) * 10;

      // Generate sales data for chart
      final salesData = List.generate(7, (index) {
        return {
          'date': DateTime.now().subtract(Duration(days: 6 - index)),
          'value': 100 + math.Random().nextDouble() * 200,
        };
      });

      return {
        'totalItems': totalItems,
        'totalAssignments': totalAssignments,
        'totalRevenue': totalRevenue,
        'activeUsers': totalAssignments,
        'itemsSold': totalAssignments,
        'conversionRate': totalItems > 0 ? (totalAssignments / totalItems) * 100 : 0.0,
        'revenueTrend': revenueTrend,
        'userTrend': userTrend,
        'salesTrend': salesTrend,
        'conversionTrend': conversionTrend,
        'salesData': salesData,
      };
    } catch (e) {
      debugPrint('Error getting analytics: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTopItems() async {
    try {
      final userItemsSnapshot = await FirebaseFirestore.instance
          .collection('user_store_items')
          .get();

      final itemSales = <String, Map<String, dynamic>>{};

      for (var doc in userItemsSnapshot.docs) {
        final data = doc.data();
        final itemId = data['itemId'] as String;
        
        if (itemSales.containsKey(itemId)) {
          itemSales[itemId]!['sales'] = (itemSales[itemId]!['sales'] as int) + 1;
          itemSales[itemId]!['revenue'] = (itemSales[itemId]!['revenue'] as double) + (data['price'] ?? 0.0);
        } else {
          itemSales[itemId] = {
            'itemId': itemId,
            'sales': 1,
            'revenue': data['price'] ?? 0.0,
          };
        }
      }

      // Get item details
      final topItems = <Map<String, dynamic>>[];
      for (var entry in itemSales.entries) {
        try {
          final itemDoc = await FirebaseFirestore.instance
              .collection('store_items')
              .doc(entry.key)
              .get();
          
          if (itemDoc.exists) {
            final itemData = itemDoc.data()!;
            topItems.add({
              'id': entry.key,
              'name': itemData['name'],
              'type': StoreItemType.values.firstWhere(
                (type) => type.toString() == itemData['type'],
                orElse: () => StoreItemType.avatarFrame,
              ),
              'sales': entry.value['sales'],
              'revenue': entry.value['revenue'],
            });
          }
        } catch (e) {
          debugPrint('Error getting item details for ${entry.key}: $e');
        }
      }

      // Sort by sales
      topItems.sort((a, b) => (b['sales'] as int).compareTo(a['sales'] as int));
      
      return topItems.take(10).toList();
    } catch (e) {
      debugPrint('Error getting top items: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserActivity() async {
    try {
      final userItemsSnapshot = await FirebaseFirestore.instance
          .collection('user_store_items')
          .orderBy('assignedAt', descending: true)
          .limit(50)
          .get();

      final activities = <Map<String, dynamic>>[];

      for (var doc in userItemsSnapshot.docs) {
        final data = doc.data();
        activities.add({
          'type': 'assignment',
          'description': 'Item assigned to user',
          'timestamp': data['assignedAt'],
          'userId': data['userId'],
          'itemId': data['itemId'],
        });
      }

      return activities;
    } catch (e) {
      debugPrint('Error getting user activity: $e');
      rethrow;
    }
  }
}
