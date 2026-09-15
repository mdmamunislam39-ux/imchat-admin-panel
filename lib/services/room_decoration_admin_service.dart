import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class RoomDecorationAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'system_configs';
  static const String _doc = 'room_creation_decoration';

  /// Real-time stream of room creation decoration config
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getDecorationStream() {
    return _firestore.collection(_collection).doc(_doc).snapshots();
  }

  /// Get decoration config once
  static Future<Map<String, dynamic>?> getDecorationConfig() async {
    try {
      final docSnap = await _firestore.collection(_collection).doc(_doc).get();
      if (docSnap.exists && docSnap.data() != null) {
        return docSnap.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting room decoration config: $e');
      return null;
    }
  }

  /// Save or update decoration config in both system_configs and global_settings,
  /// and automatically sync to market_items & store_items for real-time mobile app delivery
  static Future<void> saveDecorationConfig(Map<String, dynamic> data) async {
    try {
      final payload = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection(_collection).doc(_doc).set(
        payload,
        SetOptions(merge: true),
      );

      // Also mirror to global_settings for backward compatibility
      try {
        await _firestore.collection('global_settings').doc('room_creation_decoration').set(
          payload,
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Failed to mirror to global_settings: $e');
      }

      // Automatically sync free seat decor to market_items & store_items in real-time
      try {
        await syncFreeSeatDecorToStore(
          name: data['defaultSeatName'] ?? 'Classic Mic & Owner (Free)',
          seatColorMode: data['defaultSeatColorMode'] ?? 'original',
          seatDecorUrl: data['defaultSeatDecorUrl'] ?? '',
          lockedSeatDecorUrl: data['defaultLockedSeatDecorUrl'] ?? '',
        );
      } catch (e) {
        debugPrint('Failed to auto-sync free seat decor: $e');
      }
    } catch (e) {
      debugPrint('Error saving room decoration config: $e');
      throw Exception('Failed to save decoration config: $e');
    }
  }

  /// Sync free seat decor directly to market_items, store_items, and official_items
  /// so that users in the mobile app see it in their seat decor sheet in real-time without any refresh.
  static Future<void> syncFreeSeatDecorToStore({
    String? name,
    String? seatColorMode,
    String? seatDecorUrl,
    String? lockedSeatDecorUrl,
  }) async {
    try {
      final String effectiveName = name ?? 'Classic Mic & Owner (Free)';
      final classicPayload = {
        'id': 'free_mode_original',
        'name': effectiveName,
        'title': effectiveName,
        'type': 'seatDecor',
        'category': 'seatDecor',
        'diamondPrice': 0.0,
        'price': 0,
        'isFree': true,
        'isFreeMode': true,
        'seatColorMode': seatColorMode ?? 'original',
        'fileUrl': seatDecorUrl ?? '',
        'lockedFileUrl': lockedSeatDecorUrl ?? '',
        'thumbnailUrl': seatDecorUrl ?? '',
        'isActive': true,
        'isOfficial': true,
        'starRating': 5,
        'description': 'Free Classic Frosted Glass Mic & Owner seat decor set for voice rooms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final goldenPayload = {
        'id': 'free_mode_golden',
        'name': 'Golden Sofa & Host (Free)',
        'title': 'Golden Sofa & Host (Free)',
        'type': 'seatDecor',
        'category': 'seatDecor',
        'diamondPrice': 0.0,
        'price': 0,
        'isFree': true,
        'isFreeMode': true,
        'seatColorMode': 'golden',
        'fileUrl': '',
        'lockedFileUrl': '',
        'thumbnailUrl': '',
        'isActive': true,
        'isOfficial': true,
        'starRating': 5,
        'description': 'Free Golden Frosted Glass Sofa & Host seat decor set for voice rooms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final purplePayload = {
        'id': 'free_mode_purple',
        'name': 'Neon Purple & Gold (Free)',
        'title': 'Neon Purple & Gold (Free)',
        'type': 'seatDecor',
        'category': 'seatDecor',
        'diamondPrice': 0.0,
        'price': 0,
        'isFree': true,
        'isFreeMode': true,
        'seatColorMode': 'purple',
        'fileUrl': '',
        'lockedFileUrl': '',
        'thumbnailUrl': '',
        'isActive': true,
        'isOfficial': true,
        'starRating': 5,
        'description': 'Free Neon Royal Purple & Gold Sofa seat decor set for voice rooms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final dashedPinkPayload = {
        'id': 'free_mode_dashedPink',
        'name': 'Dashed Pink (Free)',
        'title': 'Dashed Pink (Free)',
        'type': 'seatDecor',
        'category': 'seatDecor',
        'diamondPrice': 0.0,
        'price': 0,
        'isFree': true,
        'isFreeMode': true,
        'seatColorMode': 'dashedPink',
        'fileUrl': '',
        'lockedFileUrl': '',
        'thumbnailUrl': '',
        'isActive': true,
        'isOfficial': true,
        'starRating': 5,
        'description': 'Free Dashed Pink musical notes seat decor set for voice rooms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final dashedOrangePayload = {
        'id': 'free_mode_dashedOrange',
        'name': 'Dashed Orange (Free)',
        'title': 'Dashed Orange (Free)',
        'type': 'seatDecor',
        'category': 'seatDecor',
        'diamondPrice': 0.0,
        'price': 0,
        'isFree': true,
        'isFreeMode': true,
        'seatColorMode': 'dashedOrange',
        'fileUrl': '',
        'lockedFileUrl': '',
        'thumbnailUrl': '',
        'isActive': true,
        'isOfficial': true,
        'starRating': 5,
        'description': 'Free Dashed Orange sofa seat decor set for voice rooms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only insert if document does NOT exist yet, ensuring admin edits/prices/activations are never overwritten
      final itemsToSync = [
        classicPayload,
        goldenPayload,
        purplePayload,
        dashedPinkPayload,
        dashedOrangePayload,
      ];

      for (final payload in itemsToSync) {
        final id = payload['id'] as String;
        final docRef = _firestore.collection('market_items').doc(id);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          await docRef.set(payload);
        }
      }

      debugPrint('✅ Successfully checked and synced free seat decor sets to market_items in real-time');
    } catch (e) {
      debugPrint('Error syncing free seat decor to store: $e');
    }
  }

  /// Upload image/asset to Firebase Storage
  static Future<String> uploadAsset(Uint8List bytes, String folder, {String? fileName}) async {
    try {
      final String actualName = fileName != null && fileName.isNotEmpty
          ? '${DateTime.now().millisecondsSinceEpoch}_$fileName'
          : '${DateTime.now().millisecondsSinceEpoch}.png';

      final Reference ref = _storage.ref().child('room_decorations/$folder/$actualName');
      
      // Determine content type
      String contentType = 'image/png';
      if (actualName.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      } else if (actualName.toLowerCase().endsWith('.jpg') || actualName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (actualName.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (actualName.toLowerCase().endsWith('.svga')) {
        contentType = 'application/octet-stream';
      }

      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading asset: $e');
      throw Exception('Failed to upload asset: $e');
    }
  }

  /// Fetch store items of type backgroundTheme
  static Future<List<Map<String, dynamic>>> getStoreBackgrounds() async {
    try {
      final snapshot = await _firestore
          .collection('market_items')
          .where('type', isEqualTo: 'backgroundTheme')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error loading store backgrounds: $e');
      return [];
    }
  }

  /// Fetch store items of type seatDecor
  static Future<List<Map<String, dynamic>>> getStoreSeatDecors() async {
    try {
      final snapshot = await _firestore
          .collection('market_items')
          .where('type', isEqualTo: 'seatDecor')
          .get();

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('Error loading store seat decors: $e');
      return [];
    }
  }
}
