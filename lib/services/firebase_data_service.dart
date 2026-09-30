import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references based on actual Firebase structure
  static const String _usersCollection = 'Users';
  static const String _audioRoomsCollection = 'audio_rooms_v2';
  static const String _giftsCollection = 'gift';
  static const String _emojisCollection = 'emoji';
  static const String _sellersCollection = 'sellers';
  static const String _storeItemsCollection = 'market_items';
  static const String _userStoreItemsCollection = 'user_store_items';
  static const String _commissionRunsCollection = 'commission_runs';
  static const String _sellerSalesSummaryCollection = 'seller_sales_summary';
  static const String _sellerTransactionsCollection = 'seller_transactions';
  static const String _agenciesCollection = 'agencies';
  static const String _notificationsCollection = 'notifications';
  static const String _reportsCollection = 'Reports';
  static const String _eventsCollection = 'events';
  static const String _officialItemsCollection = 'official_items';

  // User Management
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection(_usersCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting users: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  static Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // Audio Rooms Management
  static Future<List<Map<String, dynamic>>> getAllAudioRooms() async {
    try {
      final snapshot = await _firestore.collection(_audioRoomsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting audio rooms: $e');
      return [];
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAudioRoomsStream() {
    return _firestore.collection(_audioRoomsCollection).snapshots();
  }

  static Future<bool> updateAudioRoom(String roomId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_audioRoomsCollection).doc(roomId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating audio room: $e');
      return false;
    }
  }

  static Future<bool> deleteAudioRoom(String roomId) async {
    try {
      await _firestore.collection(_audioRoomsCollection).doc(roomId).delete();
      // Also delete from fallback/legacy collections if existing
      await _firestore.collection('room').doc(roomId).delete().catchError((_) {});
      await _firestore.collection('audio_rooms').doc(roomId).delete().catchError((_) {});
      return true;
    } catch (e) {
      debugPrint('Error deleting audio room: $e');
      return false;
    }
  }

  // Audio Room Rules & Guideline
  static Future<String> getAudioRoomRules() async {
    try {
      final doc = await _firestore.collection('system_configs').doc('audio_room_rules').get();
      if (doc.exists && doc.data() != null) {
        final text = doc.data()!['rulesText']?.toString();
        if (text != null && text.trim().isNotEmpty) {
          return text;
        }
      }
    } catch (e) {
      debugPrint('Error getting audio room rules: $e');
    }
    return "There are a lot of very interested friends here. Let's chat together.";
  }

  static Future<bool> updateAudioRoomRules(String rulesText) async {
    try {
      await _firestore.collection('system_configs').doc('audio_room_rules').set({
        'rulesText': rulesText.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also sync to global_settings/app_settings for redundant coverage
      await _firestore.collection('global_settings').doc('app_settings').set({
        'audioRoomRules': rulesText.trim(),
      }, SetOptions(merge: true)).catchError((_) {});

      return true;
    } catch (e) {
      debugPrint('Error updating audio room rules: $e');
      return false;
    }
  }

  // Gifts Management
  static Future<List<Map<String, dynamic>>> getAllGifts() async {
    try {
      final snapshot = await _firestore.collection(_giftsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting gifts: $e');
      return [];
    }
  }

  static Future<bool> createGift(Map<String, dynamic> giftData) async {
    try {
      await _firestore.collection(_giftsCollection).add(giftData);
      return true;
    } catch (e) {
      debugPrint('Error creating gift: $e');
      return false;
    }
  }

  static Future<bool> updateGift(String giftId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_giftsCollection).doc(giftId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating gift: $e');
      return false;
    }
  }

  static Future<bool> deleteGift(String giftId) async {
    try {
      await _firestore.collection(_giftsCollection).doc(giftId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting gift: $e');
      return false;
    }
  }

  // Emojis Management
  static Future<List<Map<String, dynamic>>> getAllEmojis() async {
    try {
      final snapshot = await _firestore.collection(_emojisCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting emojis: $e');
      return [];
    }
  }

  static Future<bool> createEmoji(Map<String, dynamic> emojiData) async {
    try {
      await _firestore.collection(_emojisCollection).add(emojiData);
      return true;
    } catch (e) {
      debugPrint('Error creating emoji: $e');
      return false;
    }
  }

  static Future<bool> updateEmoji(String emojiId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_emojisCollection).doc(emojiId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating emoji: $e');
      return false;
    }
  }

  static Future<bool> deleteEmoji(String emojiId) async {
    try {
      await _firestore.collection(_emojisCollection).doc(emojiId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting emoji: $e');
      return false;
    }
  }

  // Sellers Management
  static Future<List<Map<String, dynamic>>> getAllSellers() async {
    try {
      final snapshot = await _firestore.collection(_sellersCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting sellers: $e');
      return [];
    }
  }

  static Future<bool> updateSeller(String sellerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_sellersCollection).doc(sellerId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating seller: $e');
      return false;
    }
  }

  // Store Items Management
  static Future<List<Map<String, dynamic>>> getAllStoreItems() async {
    try {
      final snapshot = await _firestore.collection(_storeItemsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting store items: $e');
      return [];
    }
  }

  static Future<bool> createStoreItem(Map<String, dynamic> itemData) async {
    try {
      await _firestore.collection(_storeItemsCollection).add(itemData);
      return true;
    } catch (e) {
      debugPrint('Error creating store item: $e');
      return false;
    }
  }

  static Future<bool> updateStoreItem(String itemId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_storeItemsCollection).doc(itemId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating store item: $e');
      return false;
    }
  }

  static Future<bool> deleteStoreItem(String itemId) async {
    try {
      await _firestore.collection(_storeItemsCollection).doc(itemId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting store item: $e');
      return false;
    }
  }

  // User Store Items (owned items)
  static Future<List<Map<String, dynamic>>> getUserStoreItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_userStoreItemsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user store items: $e');
      return [];
    }
  }

  static Future<bool> assignItemToUser(String userId, String itemId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_userStoreItemsCollection).add({
        'userId': userId,
        'itemId': itemId,
        'assignedAt': FieldValue.serverTimestamp(),
        ...data,
      });
      return true;
    } catch (e) {
      debugPrint('Error assigning item to user: $e');
      return false;
    }
  }

  // Commission Management
  static Future<List<Map<String, dynamic>>> getAllCommissionRuns() async {
    try {
      final snapshot = await _firestore.collection(_commissionRunsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting commission runs: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerSalesSummary() async {
    try {
      final snapshot = await _firestore.collection(_sellerSalesSummaryCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting seller sales summary: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getSellerTransactions() async {
    try {
      final snapshot = await _firestore.collection(_sellerTransactionsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting seller transactions: $e');
      return [];
    }
  }

  // Agencies Management
  static Future<List<Map<String, dynamic>>> getAllAgencies() async {
    try {
      final snapshot = await _firestore.collection(_agenciesCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting agencies: $e');
      return [];
    }
  }

  static Future<bool> createAgency(Map<String, dynamic> agencyData) async {
    try {
      await _firestore.collection(_agenciesCollection).add(agencyData);
      return true;
    } catch (e) {
      debugPrint('Error creating agency: $e');
      return false;
    }
  }

  static Future<bool> updateAgency(String agencyId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_agenciesCollection).doc(agencyId).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating agency: $e');
      return false;
    }
  }

  // Notifications Management
  static Future<List<Map<String, dynamic>>> getAllNotifications() async {
    try {
      final snapshot = await _firestore.collection(_notificationsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  static Future<bool> sendNotification(Map<String, dynamic> notificationData) async {
    try {
      await _firestore.collection(_notificationsCollection).add(notificationData);
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  // Reports Management
  static Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final snapshot = await _firestore.collection(_reportsCollection).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting reports: $e');
      return [];
    }
  }

  // Events Management
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    try {
      final snapshot = await _firestore.collection(_eventsCollection).orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting events: $e');
      return [];
    }
  }

  static Future<bool> createEvent(Map<String, dynamic> eventData) async {
    try {
      await _firestore.collection(_eventsCollection).add(eventData);
      return true;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return false;
    }
  }

  static Future<bool> updateEvent(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_eventsCollection).doc(id).update(data);
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  static Future<bool> deleteEvent(String id) async {
    try {
      await _firestore.collection(_eventsCollection).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> fetchItemById(String itemId) async {
    try {
      // Check store_items first
      var doc = await _firestore.collection(_storeItemsCollection).doc(itemId).get();
      if (doc.exists) {
        return {'id': doc.id, 'collection': 'store_items', ...doc.data()!};
      }
      
      // Then check official_items
      doc = await _firestore.collection(_officialItemsCollection).doc(itemId).get();
      if (doc.exists) {
        return {'id': doc.id, 'collection': 'official_items', ...doc.data()!};
      }
      
      return null;
    } catch (e) {
      debugPrint('Error fetching item by id: $e');
      return null;
    }
  }

  static Stream<QuerySnapshot> getEventRegistrationsStream(String eventId) {
    return _firestore.collection(_eventsCollection).doc(eventId).collection('registrations').snapshots();
  }

  static Future<List<Map<String, dynamic>>> getEventRegistrations(String eventId) async {
    try {
      final snapshot = await _firestore.collection(_eventsCollection).doc(eventId).collection('registrations').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error getting event registrations: $e');
      return [];
    }
  }

  // Statistics and Analytics
  static Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final usersSnapshot = await _firestore.collection(_usersCollection).get();
      final roomsSnapshot = await _firestore.collection(_audioRoomsCollection).get();
      final giftsSnapshot = await _firestore.collection(_giftsCollection).get();
      final sellersSnapshot = await _firestore.collection(_sellersCollection).get();
      final agenciesSnapshot = await _firestore.collection(_agenciesCollection).get();

      return {
        'totalUsers': usersSnapshot.docs.length,
        'totalRooms': roomsSnapshot.docs.length,
        'totalGifts': giftsSnapshot.docs.length,
        'totalSellers': sellersSnapshot.docs.length,
        'totalAgencies': agenciesSnapshot.docs.length,
        'activeUsers': usersSnapshot.docs.where((doc) => doc.data()['isOnline'] == true).length,
      };
    } catch (e) {
      debugPrint('Error getting system statistics: $e');
      return {};
    }
  }

  // User Activity and History
  static Future<List<Map<String, dynamic>>> getUserCallHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('CallHistory')
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user call history: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('Chats')
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user chats: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserContacts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection('Contacts')
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting user contacts: $e');
      return [];
    }
  }
}
