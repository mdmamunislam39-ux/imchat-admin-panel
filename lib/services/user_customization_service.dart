import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/custom_user_id_model.dart';
import '../models/custom_user_id_history_model.dart';
import 'simple_auth_service.dart';

class UserCustomizationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'premium_user_ids';
  static const List<String> _userCollections = ['Users', 'users', 'user', 'user_profiles'];
  static const String _historyCollection = 'custom_user_id_history';

  // Get stream of all custom user IDs
  static Stream<List<CustomUserIdModel>> getCustomUserIdsStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => CustomUserIdModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      return list;
    });
  }

  // Get stream of custom user ID history
  static Stream<List<CustomUserIdHistoryModel>> getCustomUserIdHistoryStream() {
    return _firestore
        .collection(_historyCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CustomUserIdHistoryModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Search user by original ID, Search ID, custom ID, phone, email, or name across candidate collections
  static Future<Map<String, dynamic>?> searchUserByOriginalId(String searchId) async {
    try {
      final cleanId = searchId.trim();
      if (cleanId.isEmpty) return null;

      final intId = int.tryParse(cleanId);
      String targetUserId = cleanId;

      // 1. Check if searchId is an existing Custom Short ID in premium_user_ids
      try {
        QuerySnapshot customIdQuery = await _firestore
            .collection(_collectionName)
            .where('customId', isEqualTo: cleanId)
            .limit(1)
            .get();

        if (customIdQuery.docs.isEmpty) {
          customIdQuery = await _firestore
              .collection(_collectionName)
              .where('customUserId', isEqualTo: cleanId)
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
          targetUserId = (customData['userId'] ?? customData['originalUserId'] ?? customIdQuery.docs.first.id).toString();
        }
      } catch (e) {
        debugPrint('Error searching premium_user_ids: $e');
      }

      // Fields to query
      final fieldsToQuery = [
        'searchId',
        'originalSearchId',
        'user_id',
        'userId',
        'id',
        'imchatId',
        'uniqueId',
        'customId',
        'customUserId',
        'number',
        'phone',
        'phoneNumber',
        'email',
        'fullname',
        'username',
        'name',
        'displayName',
      ];

      for (final collection in _userCollections) {
        // A. Direct Document ID Lookup
        for (final docIdToTry in {targetUserId, cleanId}) {
          try {
            final doc = await _firestore.collection(collection).doc(docIdToTry).get();
            if (doc.exists && doc.data() != null) {
              final data = doc.data()!;
              final origSearchId = data['originalSearchId'] ?? data['searchId'] ?? data['user_id'] ?? data['userId'] ?? data['uniqueId'] ?? data['imchatId'] ?? doc.id;
              final fullName = data['fullname'] ?? data['username'] ?? data['name'] ?? data['displayName'] ?? 'User';
              final photoUrl = data['photoUrl'] ?? data['imageUrl'] ?? data['profileImageUrl'] ?? data['avatar'] ?? data['photo'] ?? '';
              return {
                'id': doc.id,
                'searchId': origSearchId.toString(),
                'currentSearchId': (data['searchId'] ?? origSearchId).toString(),
                'originalSearchId': origSearchId.toString(),
                'name': fullName.toString(),
                'imageUrl': photoUrl.toString(),
                'phone': (data['number'] ?? data['phone'] ?? data['phoneNumber'] ?? '').toString(),
                'email': (data['email'] ?? '').toString(),
                'collection': collection,
              };
            }
          } catch (_) {}
        }

        // B. Query by Fields (String and Int)
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
              final origSearchId = data['originalSearchId'] ?? data['searchId'] ?? data['user_id'] ?? data['userId'] ?? data['uniqueId'] ?? data['imchatId'] ?? doc.id;
              final fullName = data['fullname'] ?? data['username'] ?? data['name'] ?? data['displayName'] ?? 'User';
              final photoUrl = data['photoUrl'] ?? data['imageUrl'] ?? data['profileImageUrl'] ?? data['avatar'] ?? data['photo'] ?? '';
              return {
                'id': doc.id,
                'searchId': origSearchId.toString(),
                'currentSearchId': (data['searchId'] ?? origSearchId).toString(),
                'originalSearchId': origSearchId.toString(),
                'name': fullName.toString(),
                'imageUrl': photoUrl.toString(),
                'phone': (data['number'] ?? data['phone'] ?? data['phoneNumber'] ?? '').toString(),
                'email': (data['email'] ?? '').toString(),
                'collection': collection,
              };
            }
          } catch (_) {}
        }
      }

      // C. Fallback scan in memory across collections
      for (final collection in _userCollections) {
        try {
          final snapshot = await _firestore.collection(collection).limit(200).get();
          final searchLower = cleanId.toLowerCase();
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dId = doc.id.toLowerCase();
            final sId = (data['searchId'] ?? '').toString().toLowerCase();
            final oId = (data['originalSearchId'] ?? '').toString().toLowerCase();
            final uId = (data['userId'] ?? data['user_id'] ?? data['uniqueId'] ?? data['imchatId'] ?? '').toString().toLowerCase();
            final name = (data['fullname'] ?? data['username'] ?? data['name'] ?? '').toString().toLowerCase();
            final phone = (data['number'] ?? data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();

            if (dId == searchLower || sId == searchLower || oId == searchLower || uId == searchLower || (intId != null && sId == intId.toString()) || name.contains(searchLower) || phone == searchLower) {
              final origSearchId = data['originalSearchId'] ?? data['searchId'] ?? data['user_id'] ?? data['userId'] ?? data['uniqueId'] ?? data['imchatId'] ?? doc.id;
              final fullName = data['fullname'] ?? data['username'] ?? data['name'] ?? data['displayName'] ?? 'User';
              final photoUrl = data['photoUrl'] ?? data['imageUrl'] ?? data['profileImageUrl'] ?? data['avatar'] ?? data['photo'] ?? '';
              return {
                'id': doc.id,
                'searchId': origSearchId.toString(),
                'currentSearchId': (data['searchId'] ?? origSearchId).toString(),
                'originalSearchId': origSearchId.toString(),
                'name': fullName.toString(),
                'imageUrl': photoUrl.toString(),
                'phone': (data['number'] ?? data['phone'] ?? data['phoneNumber'] ?? '').toString(),
                'email': (data['email'] ?? '').toString(),
                'collection': collection,
              };
            }
          }
        } catch (_) {}
      }

      return null;
    } catch (e) {
      debugPrint('Error searching user: $e');
      return null;
    }
  }

  static void _addHistoryLog(
    WriteBatch batch, {
    required String userId,
    required String currentOwnerId,
    required String customUserId,
    required UserIdHistoryAction action,
    String? notes,
  }) {
    final adminId = SimpleAuthService.currentUserId ?? 'unknown_admin';
    final historyRef = _firestore.collection(_historyCollection).doc();

    final historyModel = CustomUserIdHistoryModel(
      id: historyRef.id,
      userId: userId,
      currentOwnerId: currentOwnerId,
      customUserId: customUserId,
      action: action,
      actionByAdminId: adminId,
      timestamp: DateTime.now(),
      notes: notes,
    );

    batch.set(historyRef, historyModel.toMap());
  }

  // Helper to find and update user documents across candidate user collections
  static Future<void> _updateUserDocsInCollections(
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

    final fieldsToQuery = ['searchId', 'originalSearchId', 'user_id', 'userId', 'id', 'uniqueId', 'imchatId'];
    final docsToUpdate = <DocumentReference>[];
    final updatedDocPaths = <String>{};

    for (final collection in _userCollections) {
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

    // Apply updates to batch
    for (final docRef in docsToUpdate) {
      batch.update(docRef, updateData);
    }
  }

  // Assign custom ID to a User
  static Future<void> assignCustomUserId(CustomUserIdModel customUser) async {
    try {
      final batch = _firestore.batch();

      // 1. Check if this custom ID is already taken and active
      final existingSnapshot = await _firestore
          .collection(_collectionName)
          .where('customId', isEqualTo: customUser.customUserId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingSnapshot.docs.isNotEmpty) {
        final existingDoc = existingSnapshot.docs.first;
        if (existingDoc.id != customUser.userId) {
          throw Exception('This Custom ID is already assigned to another active user.');
        }
      }

      // 2. Resolve original searchId
      String resolvedOriginalSearchId = customUser.originalUserId;
      for (final collection in _userCollections) {
        try {
          final userDoc = await _firestore.collection(collection).doc(customUser.userId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final uData = userDoc.data()!;
            if (uData['originalSearchId'] != null && uData['originalSearchId'].toString().isNotEmpty) {
              resolvedOriginalSearchId = uData['originalSearchId'].toString();
              break;
            } else if (uData['searchId'] != null && uData['searchId'].toString().isNotEmpty && uData['searchId'].toString() != customUser.customUserId) {
              resolvedOriginalSearchId = uData['searchId'].toString();
              break;
            }
          }
        } catch (_) {}
      }

      // 3. Save to premium_user_ids (doc ID = user doc ID)
      final premiumDocRef = _firestore.collection(_collectionName).doc(customUser.userId);
      final updatedCustomModel = CustomUserIdModel(
        id: customUser.userId,
        userId: customUser.userId,
        originalUserId: resolvedOriginalSearchId,
        customUserId: customUser.customUserId,
        userName: customUser.userName,
        userImageUrl: customUser.userImageUrl,
        assignedAt: customUser.assignedAt,
        expiresAt: customUser.expiresAt,
        isActive: customUser.isActive,
      );
      batch.set(premiumDocRef, updatedCustomModel.toFirestore());

      // 4. Update across candidate user collections
      final userUpdateData = <String, dynamic>{
        'searchId': customUser.customUserId,
        'originalSearchId': resolvedOriginalSearchId,
        'hasCustomId': customUser.isActive,
        'isCustomIdActive': customUser.isActive,
        'customIdStatus': customUser.isActive ? 'active' : 'deactivated',
        'customIdExpiresAt': Timestamp.fromDate(customUser.expiresAt),
        'customId': customUser.customUserId,
        'customUserId': customUser.customUserId,
        if (customUser.userName.isNotEmpty && customUser.userName != 'User') ...{
          'fullname': customUser.userName,
          'username': customUser.userName,
          'name': customUser.userName,
          'displayName': customUser.userName,
        },
      };

      await _updateUserDocsInCollections(
        batch,
        targetIds: [customUser.userId, resolvedOriginalSearchId, customUser.originalUserId],
        updateData: userUpdateData,
      );

      // 5. Add History Log
      _addHistoryLog(
        batch,
        userId: customUser.userId,
        currentOwnerId: resolvedOriginalSearchId,
        customUserId: customUser.customUserId,
        action: UserIdHistoryAction.assign,
        notes: 'Assigned Custom ID: ${customUser.customUserId} (Original: $resolvedOriginalSearchId, Name: ${customUser.userName}, Expires: ${customUser.expiresAt.toIso8601String().split('T')[0]})',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error assigning custom user ID: $e');
      rethrow;
    }
  }

  // Update existing custom ID assignment (extend duration, change ID, update name, or toggle active)
  static Future<void> updateCustomUserId(
    String docId,
    DateTime newExpiresAt,
    bool isActive, {
    String? newCustomId,
    String? newName,
  }) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final userId = (data['userId'] ?? docId).toString();
      final origSearchId = (data['originalUserId'] ?? data['originalSearchId'] ?? '').toString();
      final oldCustomId = (data['customId'] ?? data['customUserId'] ?? '').toString();

      if (newCustomId != null && newCustomId.isNotEmpty && newCustomId != oldCustomId) {
        final existingSnapshot = await _firestore
            .collection(_collectionName)
            .where('customId', isEqualTo: newCustomId)
            .where('isActive', isEqualTo: true)
            .get();

        if (existingSnapshot.docs.isNotEmpty && existingSnapshot.docs.first.id != docId) {
          throw Exception('This Custom ID is already assigned to another active user.');
        }
      }

      final batch = _firestore.batch();

      final updateData = <String, dynamic>{
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'isActive': isActive,
        'status': isActive ? 'active' : 'deactivated',
      };

      String targetCustomId = oldCustomId;
      if (newCustomId != null && newCustomId.isNotEmpty) {
        updateData['customId'] = newCustomId;
        updateData['customUserId'] = newCustomId;
        targetCustomId = newCustomId;
      }

      if (newName != null && newName.trim().isNotEmpty) {
        updateData['userName'] = newName.trim();
      }

      batch.update(docRef, updateData);

      // Resolve original searchId
      String resolvedOrig = origSearchId;
      for (final collection in _userCollections) {
        try {
          final userDoc = await _firestore.collection(collection).doc(userId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final uData = userDoc.data()!;
            if (uData['originalSearchId'] != null && uData['originalSearchId'].toString().isNotEmpty) {
              resolvedOrig = uData['originalSearchId'].toString();
              break;
            }
          }
        } catch (_) {}
      }

      final userUpdateData = <String, dynamic>{
        'hasCustomId': isActive,
        'isCustomIdActive': isActive,
        'customIdStatus': isActive ? 'active' : 'deactivated',
        'customIdExpiresAt': Timestamp.fromDate(newExpiresAt),
        if (newName != null && newName.trim().isNotEmpty) ...{
          'fullname': newName.trim(),
          'username': newName.trim(),
          'name': newName.trim(),
          'displayName': newName.trim(),
        },
        if (isActive) 'searchId': targetCustomId,
        if (isActive) 'customId': targetCustomId,
        if (isActive) 'customUserId': targetCustomId,
        if (!isActive && resolvedOrig.isNotEmpty) 'searchId': resolvedOrig,
        if (!isActive) 'customId': FieldValue.delete(),
        if (!isActive) 'customUserId': FieldValue.delete(),
      };

      await _updateUserDocsInCollections(
        batch,
        targetIds: [userId, docId, resolvedOrig, oldCustomId, targetCustomId],
        updateData: userUpdateData,
      );

      // Add History Log
      _addHistoryLog(
        batch,
        userId: userId,
        currentOwnerId: resolvedOrig,
        customUserId: targetCustomId,
        action: UserIdHistoryAction.update,
        notes: 'Updated active: $isActive, ${newName != null ? 'Name: $newName, ' : ''}${newCustomId != null ? 'Changed ID from $oldCustomId to $newCustomId' : 'Extended expiration to ${newExpiresAt.toIso8601String().split('T')[0]}'}',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error updating custom user ID: $e');
      rethrow;
    }
  }

  // Delete custom ID assignment and restore the original searchId
  static Future<void> deleteCustomUserId(String docId) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final userId = (data['userId'] ?? docId).toString();
      final origSearchId = (data['originalUserId'] ?? data['originalSearchId'] ?? '').toString();
      final customUserId = (data['customId'] ?? data['customUserId'] ?? '').toString();

      final batch = _firestore.batch();
      batch.delete(docRef);

      // Resolve original searchId
      String resolvedOrig = origSearchId;
      for (final collection in _userCollections) {
        try {
          final userDoc = await _firestore.collection(collection).doc(userId).get();
          if (userDoc.exists && userDoc.data() != null) {
            final uData = userDoc.data()!;
            if (uData['originalSearchId'] != null && uData['originalSearchId'].toString().isNotEmpty) {
              resolvedOrig = uData['originalSearchId'].toString();
              break;
            }
          }
        } catch (_) {}
      }

      final userUpdateData = <String, dynamic>{
        'hasCustomId': false,
        'isCustomIdActive': false,
        'customIdStatus': 'removed',
        if (resolvedOrig.isNotEmpty) 'searchId': resolvedOrig,
        'customId': FieldValue.delete(),
        'customUserId': FieldValue.delete(),
        'customIdExpiresAt': FieldValue.delete(),
      };

      await _updateUserDocsInCollections(
        batch,
        targetIds: [userId, docId, resolvedOrig, customUserId],
        updateData: userUpdateData,
      );

      // Add History Log
      _addHistoryLog(
        batch,
        userId: userId,
        currentOwnerId: resolvedOrig,
        customUserId: customUserId,
        action: UserIdHistoryAction.remove,
        notes: 'Removed Custom ID $customUserId and restored Original ID $resolvedOrig',
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting custom user ID: $e');
      rethrow;
    }
  }
}
