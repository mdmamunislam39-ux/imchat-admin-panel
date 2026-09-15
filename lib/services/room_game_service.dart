import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/room_game_model.dart';

class RoomGameService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'room_games';
  static const String _configCollection = 'config';
  static const String _roomGamesConfigDoc = 'room_games';

  // Get stream of all custom room games
  static Stream<List<RoomGameModel>> getRoomGamesStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoomGameModel.fromFirestore(doc))
              .toList();
        });
  }

  // Create a new room game
  static Future<void> createRoomGame(RoomGameModel game) async {
    try {
      await _firestore.collection(_collectionName).add({
        ...game.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating room game: $e');
      rethrow;
    }
  }

  // Update an existing room game
  static Future<void> updateRoomGame(RoomGameModel game) async {
    try {
      await _firestore.collection(_collectionName).doc(game.id).set({
        ...game.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating room game: $e');
      rethrow;
    }
  }

  // Delete a room game
  static Future<void> deleteRoomGame(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting room game: $e');
      rethrow;
    }
  }

  // Toggle custom room game active status
  static Future<void> toggleRoomGameStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(id).set({
        'isActive': isActive,
        'isEnabled': isActive,
        'status': isActive ? 'active' : 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error toggling room game status: $e');
      rethrow;
    }
  }

  // Stream of built-in room games config document
  static Stream<DocumentSnapshot> getBuiltInRoomGamesConfigStream() {
    return _firestore
        .collection(_configCollection)
        .doc(_roomGamesConfigDoc)
        .snapshots();
  }

  // Toggle status for built-in room game (e.g. ludo, carrom, youtube, vote_pro, dice, custom_roulette, pk_battle)
  static Future<void> toggleBuiltInGameStatus(String gameKey, bool isActive) async {
    try {
      final docRef = _firestore.collection(_configCollection).doc(_roomGamesConfigDoc);
      await docRef.set({
        gameKey: {
          'isActive': isActive,
          'isEnabled': isActive,
          'status': isActive ? 'active' : 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        // Flat key for quick lookups
        '${gameKey}_active': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update or create in room_games collection for dual-channel support
      try {
        await _firestore.collection(_collectionName).doc(gameKey).set({
          'isActive': isActive,
          'isEnabled': isActive,
          'status': isActive ? 'active' : 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    } catch (e) {
      debugPrint('Error toggling built-in room game status: $e');
      rethrow;
    }
  }
}
