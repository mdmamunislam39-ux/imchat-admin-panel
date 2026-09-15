import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/custom_room_id_model.dart';
import '../models/custom_room_id_history_model.dart';
import 'simple_auth_service.dart';

class RoomCustomizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'premium_room_ids';
  static const String _roomsCollection = 'audio_rooms_v2';
  static const String _historyCollection = 'custom_room_id_history';

  // Get stream of all custom room IDs
  static Stream<List<CustomRoomIdModel>> getCustomRoomIdsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => CustomRoomIdModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return list;
    });
  }

  // Get stream of custom room ID history
  static Stream<List<CustomRoomIdHistoryModel>> getCustomRoomIdHistoryStream() {
    return _firestore
        .collection(_historyCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomRoomIdHistoryModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Search room by original ID or Custom Short ID
  static Future<Map<String, dynamic>?> searchRoomByOriginalId(String searchId) async {
    try {
      final cleanId = searchId.trim();
      if (cleanId.isEmpty) return null;

      final intId = int.tryParse(cleanId);
      String targetRoomId = cleanId;

      // 1. Check if searchId is an existing Custom Short ID in premium_room_ids
      try {
        QuerySnapshot customIdQuery = await _firestore
            .collection(_collectionName)
            .where('customId', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (customIdQuery.docs.isEmpty) {
          customIdQuery = await _firestore
              .collection(_collectionName)
              .where('customRoomId', isEqualTo: cleanId)
              .limit(1)
              .get();
        }

        if (customIdQuery.docs.isEmpty && intId != null) {
          customIdQuery = await _firestore
              .collection(_collectionName)
              .where('customId', isEqualTo: intId)
              .limit(1)
              .get();
        }

        if (customIdQuery.docs.isNotEmpty) {
          final customData = customIdQuery.docs.first.data() as Map<String, dynamic>;
          targetRoomId = (customData['roomId'] ?? customData['originalRoomId'] ?? customIdQuery.docs.first.id).toString();
        }
      } catch (e) {
        debugPrint('Error searching premium_room_ids: $e');
      }

      // 2. Search room collections (audio_rooms_v2, audio_rooms, rooms, room)
      final collectionsToSearch = [_roomsCollection, 'audio_rooms', 'rooms', 'room'];
      final fieldsToQuery = ['roomId', 'originalRoomId', 'room_id', 'id', 'shortId', 'customId', 'customRoomId'];

      for (final collection in collectionsToSearch) {
        // A. Direct Document ID Lookup
        for (final docIdToTry in {targetRoomId, cleanId}) {
          try {
            final doc = await _firestore.collection(collection).doc(docIdToTry).get();
            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              final origId = data['originalRoomId'] ?? data['roomId'] ?? data['room_id'] ?? data['id'] ?? doc.id;
              return {
                'id': doc.id,
                'roomId': origId.toString(),
                'name': (data['roomName'] ?? data['name'] ?? data['title'] ?? 'Unknown Room').toString(),
                'imageUrl': (data['roomImageUrl'] ?? data['imageUrl'] ?? data['roomImage'] ?? data['image'] ?? data['cover'] ?? '').toString(),
                'collection': collection,
              };
            }
          } catch (_) {}
        }

        // B. Query by fields (String & Int)
        for (final field in fieldsToQuery) {
          try {
            var query = await _firestore
                .collection(collection)
                .where(field, isEqualTo: cleanId)
                .limit(1)
                .get();

            if (query.docs.isEmpty && intId != null) {
              query = await _firestore
                  .collection(collection)
                  .where(field, isEqualTo: intId)
                  .limit(1)
                  .get();
            }

            if (query.docs.isNotEmpty) {
              final doc = query.docs.first;
              final data = doc.data();
              final origId = data['originalRoomId'] ?? data['roomId'] ?? data['room_id'] ?? data['id'] ?? doc.id;
              return {
                'id': doc.id,
                'roomId': origId.toString(),
                'name': (data['roomName'] ?? data['name'] ?? data['title'] ?? 'Unknown Room').toString(),
                'imageUrl': (data['roomImageUrl'] ?? data['imageUrl'] ?? data['roomImage'] ?? data['image'] ?? data['cover'] ?? '').toString(),
                'collection': collection,
              };
            }
          } catch (_) {}
        }
      }

      // 3. Fallback memory scan across collections in case indexes or field name types differ
      for (final collection in collectionsToSearch) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dId = doc.id.toLowerCase();
            final rId = (data['roomId'] ?? data['originalRoomId'] ?? data['room_id'] ?? data['id'] ?? '').toString().toLowerCase();
            final cId = (data['customId'] ?? data['customRoomId'] ?? '').toString().toLowerCase();
            final searchLower = cleanId.toLowerCase();

            if (dId == searchLower || rId == searchLower || cId == searchLower || (intId != null && (rId == intId.toString() || cId == intId.toString()))) {
              final origId = data['originalRoomId'] ?? data['roomId'] ?? data['room_id'] ?? data['id'] ?? doc.id;
              return {
                'id': doc.id,
                'roomId': origId.toString(),
                'name': (data['roomName'] ?? data['name'] ?? data['title'] ?? 'Unknown Room').toString(),
                'imageUrl': (data['roomImageUrl'] ?? data['imageUrl'] ?? data['roomImage'] ?? data['image'] ?? data['cover'] ?? '').toString(),
                'collection': collection,
              };
            }
          }
        } catch (_) {}
      }

      return null;
    } catch (e) {
      debugPrint('Error searching room: $e');
      return null;
    }
  }

  static void _addHistoryLog(
    WriteBatch batch, {
    required String roomId,
    required String currentOwnerId,
    required String customRoomId,
    required RoomIdHistoryAction action,
    String? notes,
  }) {
    final adminId = SimpleAuthService.currentUserId ?? 'unknown_admin';
    final historyRef = _firestore.collection(_historyCollection).doc();
    
    final historyModel = CustomRoomIdHistoryModel(
      id: historyRef.id,
      roomId: roomId,
      currentOwnerId: currentOwnerId,
      customRoomId: customRoomId,
      action: action,
      actionByAdminId: adminId,
      timestamp: DateTime.now(),
      notes: notes,
    );
    
    batch.set(historyRef, historyModel.toMap());
  }

  // Helper to find and update room documents across collections by doc ID or field query
  static Future<void> _updateRoomDocsInCollections(
    WriteBatch batch, {
    required List<String> targetIds,
    required Map<String, dynamic> updateData,
  }) async {
    final cleanIds = targetIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (cleanIds.isEmpty) return;

    final collections = [_roomsCollection, 'audio_rooms', 'rooms'];
    final fieldsToQuery = ['roomId', 'originalRoomId', 'room_id', 'id'];

    final docsToUpdate = <DocumentReference>[];
    final updatedDocPaths = <String>{};

    for (final collection in collections) {
      final futures = <Future<List<DocumentReference>>>[];

      for (final id in cleanIds) {
        // Direct Document ID Lookup
        futures.add(() async {
          try {
            final doc = await _firestore.collection(collection).doc(id).get();
            if (doc.exists && doc.data() != null) {
              return <DocumentReference>[doc.reference];
            }
          } catch (_) {}
          return <DocumentReference>[];
        }());

        // Field queries
        final intId = int.tryParse(id);
        for (final field in fieldsToQuery) {
          futures.add(() async {
            try {
              final snapshot = await _firestore.collection(collection).where(field, isEqualTo: id).get();
              return snapshot.docs.map((d) => d.reference).toList();
            } catch (_) {}
            return <DocumentReference>[];
          }());

          if (intId != null) {
            futures.add(() async {
              try {
                final snapshot = await _firestore.collection(collection).where(field, isEqualTo: intId).get();
                return snapshot.docs.map((d) => d.reference).toList();
              } catch (_) {}
              return <DocumentReference>[];
            }());
          }
        }
      }

      final results = await Future.wait(futures);
      for (final refList in results) {
        for (final ref in refList) {
          if (!updatedDocPaths.contains(ref.path)) {
            updatedDocPaths.add(ref.path);
            docsToUpdate.add(ref);
          }
        }
      }
    }

    // Safely apply updates to batch sequentially
    for (final docRef in docsToUpdate) {
      batch.update(docRef, updateData);
    }
  }

  // Assign custom ID
  static Future<void> assignCustomRoomId(CustomRoomIdModel customRoomId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Check if this custom ID is already taken and active
      final existingSnapshot = await _firestore
          .collection(_collectionName)
          .where('customId', isEqualTo: customRoomId.customRoomId)
          .where('isActive', isEqualTo: true)
          .get();
          
      if (existingSnapshot.docs.isNotEmpty) {
        throw Exception('This Custom ID is already assigned to another active room.');
      }

      // 2. Set doc in premium_room_ids using the original roomId as the Document ID (Expected by User App)
      final newDocRef = _firestore.collection(_collectionName).doc(customRoomId.roomId);
      batch.set(newDocRef, customRoomId.toFirestore());

      // 3. Mark the room across candidate room collections
      final roomUpdateData = <String, dynamic>{
        'hasCustomId': customRoomId.isActive,
        'isCustomIdActive': customRoomId.isActive,
        'customIdStatus': customRoomId.isActive ? 'active' : 'deactivated',
        'customIdExpiresAt': Timestamp.fromDate(customRoomId.expiresAt),
        'customId': customRoomId.customRoomId,
        'customRoomId': customRoomId.customRoomId,
      };

      await _updateRoomDocsInCollections(
        batch,
        targetIds: [customRoomId.roomId, customRoomId.originalRoomId],
        updateData: roomUpdateData,
      );

      // 4. Add History Log
      _addHistoryLog(
        batch,
        roomId: customRoomId.roomId,
        currentOwnerId: '',
        customRoomId: customRoomId.customRoomId,
        action: RoomIdHistoryAction.assign,
        notes: 'Assigned ID: ${customRoomId.customRoomId}',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error assigning custom room ID: $e');
      rethrow;
    }
  }

  // Update existing custom ID assignment (e.g. extend duration, change ID)
  static Future<void> updateCustomRoomId(String docId, DateTime newExpiresAt, bool isActive, {String? newCustomId}) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final roomId = (data['roomId'] ?? '').toString();
      final origRoomId = (data['originalRoomId'] ?? '').toString();
      final currentOwnerId = data['currentOwnerId'] ?? '';
      final oldCustomId = data['customId'] ?? data['customRoomId'] ?? '';
      
      if (newCustomId != null && newCustomId.isNotEmpty && newCustomId != oldCustomId) {
        // Check uniqueness
        final existingSnapshot = await _firestore
            .collection(_collectionName)
            .where('customId', isEqualTo: newCustomId)
            .where('isActive', isEqualTo: true)
            .get();
            
        if (existingSnapshot.docs.isNotEmpty && existingSnapshot.docs.first.id != docId) {
          throw Exception('This Custom ID is already assigned to another active room.');
        }
      }

      final batch = _firestore.batch();
      
      // Update custom_room_ids doc
      final updateData = <String, dynamic>{
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'isActive': isActive,
        'status': isActive ? 'active' : 'deactivated',
      };
      
      String targetCustomId = oldCustomId;
      if (newCustomId != null && newCustomId.isNotEmpty) {
        updateData['customId'] = newCustomId;
        updateData['customRoomId'] = newCustomId; // fallback
        targetCustomId = newCustomId;
      }
      
      batch.update(docRef, updateData);

      // Update room docs in real-time across room collections
      final roomUpdateData = <String, dynamic>{
        'hasCustomId': isActive,
        'isCustomIdActive': isActive,
        'customIdStatus': isActive ? 'active' : 'deactivated',
        'customIdExpiresAt': Timestamp.fromDate(newExpiresAt),
        if (isActive) 'customId': targetCustomId,
        if (isActive) 'customRoomId': targetCustomId,
        if (!isActive) 'customId': FieldValue.delete(),
        if (!isActive) 'customRoomId': FieldValue.delete(),
      };

      await _updateRoomDocsInCollections(
        batch,
        targetIds: [roomId, origRoomId, docId, oldCustomId],
        updateData: roomUpdateData,
      );

      // Add History Log
      _addHistoryLog(
        batch,
        roomId: roomId.isNotEmpty ? roomId : docId,
        currentOwnerId: currentOwnerId,
        customRoomId: targetCustomId,
        action: RoomIdHistoryAction.update,
        notes: 'Updated active: $isActive, ${newCustomId != null ? 'Changed ID from $oldCustomId to $newCustomId' : 'Extended expiration'}',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating custom room ID: $e');
      rethrow;
    }
  }

  // Delete custom ID assignment
  static Future<void> deleteCustomRoomId(String docId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final roomId = (data['roomId'] ?? '').toString();
      final origRoomId = (data['originalRoomId'] ?? '').toString();
      final currentOwnerId = data['currentOwnerId'] ?? '';
      final customRoomId = data['customId'] ?? data['customRoomId'] ?? '';

      final batch = _firestore.batch();
      batch.delete(docRef);

      final roomUpdateData = <String, dynamic>{
        'hasCustomId': false,
        'isCustomIdActive': false,
        'customIdStatus': 'removed',
        'customId': FieldValue.delete(),
        'customRoomId': FieldValue.delete(),
      };

      await _updateRoomDocsInCollections(
        batch,
        targetIds: [roomId, origRoomId, docId, customRoomId],
        updateData: roomUpdateData,
      );

      // Add History Log
      _addHistoryLog(
        batch,
        roomId: roomId.isNotEmpty ? roomId : docId,
        currentOwnerId: currentOwnerId,
        customRoomId: customRoomId,
        action: RoomIdHistoryAction.remove,
        notes: 'Removed ID assignment',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting custom room ID: $e');
      rethrow;
    }
  }
}
