import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/id_badge_model.dart';
import 'simple_auth_service.dart';

class IdBadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collectionName = 'custom_id_badges';
  static const String _globalSettingsDoc = 'id_badges';

  // Get stream of all configured digit ID badges
  static Stream<List<IdBadgeModel>> getIdBadgesStream() {
    return _firestore
        .collection(_collectionName)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => IdBadgeModel.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => a.digitLength.compareTo(b.digitLength));
      return list;
    });
  }

  // Get real-time stream of global ID badges map for easy lookup
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getGlobalBadgesStream() {
    return _firestore.collection('global_settings').doc(_globalSettingsDoc).snapshots();
  }

  // Save or update an ID badge for a specific digit length
  static Future<void> saveIdBadge(IdBadgeModel badge) async {
    try {
      final adminId = SimpleAuthService.currentUserId ?? 'unknown_admin';
      final docId = badge.digitLength.toString();
      final badgeData = badge.toMap();
      badgeData['updatedBy'] = adminId;

      final batch = _firestore.batch();

      // 1. Set in custom_id_badges collection
      final docRef = _firestore.collection(_collectionName).doc(docId);
      batch.set(docRef, badgeData, SetOptions(merge: true));

      // 2. Sync to global_settings/id_badges map for ultra-fast single-document lookup in mobile app
      final globalDocRef = _firestore.collection('global_settings').doc(_globalSettingsDoc);
      batch.set(
        globalDocRef,
        {
          'digit_${badge.digitLength}': {
            'digitLength': badge.digitLength,
            'name': badge.name,
            'badgeUrl': badge.badgeUrl,
            'fileType': badge.fileType,
            'isActive': badge.isActive,
            'width': badge.width,
            'height': badge.height,
            'updatedAt': Timestamp.fromDate(badge.updatedAt),
          },
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          'updatedBy': adminId,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving ID badge: $e');
      rethrow;
    }
  }

  // Delete an ID badge
  static Future<void> deleteIdBadge(int digitLength) async {
    try {
      final docId = digitLength.toString();
      final batch = _firestore.batch();

      final docRef = _firestore.collection(_collectionName).doc(docId);
      batch.delete(docRef);

      final globalDocRef = _firestore.collection('global_settings').doc(_globalSettingsDoc);
      batch.update(globalDocRef, {
        'digit_$digitLength': FieldValue.delete(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting ID badge: $e');
      rethrow;
    }
  }

  // Upload an ID badge file (PNG, WebP, GIF, SVGA) to Firebase Storage
  static Future<String> uploadBadgeFile(
    Uint8List fileBytes, {
    String? originalFileName,
  }) async {
    try {
      String ext = 'png';
      String contentType = 'image/png';

      if (originalFileName != null && originalFileName.contains('.')) {
        ext = originalFileName.split('.').last.toLowerCase().trim();
      }

      switch (ext) {
        case 'svga':
          contentType = 'application/x-svga';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'png':
        default:
          contentType = 'image/png';
          break;
      }

      final fileName = 'id_badge_${const Uuid().v4()}.$ext';
      final ref = _storage.ref().child('id_badges/$fileName');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'id_badge',
          'format': ext,
        },
      );

      final uploadTask = await ref.putData(fileBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading ID badge file: $e');
      throw Exception('Failed to upload badge file: $e');
    }
  }
}
