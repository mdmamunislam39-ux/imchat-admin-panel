import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/family_level_model.dart';

class FamilyLevelService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static const String _globalSettingsCollection = 'settings';
  static const String _familyLevelsCollection = 'family_levels';

  // Get all family levels ordered by required points
  static Stream<List<FamilyLevelModel>> getFamilyLevels() {
    return _firestore
        .collection(_globalSettingsCollection)
        .doc('global')
        .collection(_familyLevelsCollection)
        .orderBy('levelNumber')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FamilyLevelModel.fromFirestore(doc))
          .toList();
    });
  }

  // Add new family level
  static Future<void> addFamilyLevel(FamilyLevelModel level, {Uint8List? imageBytes, String? imageFileName}) async {
    try {
      String frameUrl = level.frameUrl;

      if (imageBytes != null && imageFileName != null) {
        final ref = _storage.ref().child('family_levels/${DateTime.now().millisecondsSinceEpoch}_$imageFileName');
        final uploadTask = ref.putData(imageBytes);
        final snapshot = await uploadTask;
        frameUrl = await snapshot.ref.getDownloadURL();
      }

      final newLevel = level.copyWith(
        frameUrl: frameUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_familyLevelsCollection)
          .add(newLevel.toFirestore());
    } catch (e) {
      debugPrint('Error adding family level: $e');
      rethrow;
    }
  }

  // Update existing family level
  static Future<void> updateFamilyLevel(FamilyLevelModel level, {Uint8List? imageBytes, String? imageFileName}) async {
    try {
      String frameUrl = level.frameUrl;

      if (imageBytes != null && imageFileName != null) {
        final ref = _storage.ref().child('family_levels/${DateTime.now().millisecondsSinceEpoch}_$imageFileName');
        final uploadTask = ref.putData(imageBytes);
        final snapshot = await uploadTask;
        frameUrl = await snapshot.ref.getDownloadURL();
      }

      final updatedLevel = level.copyWith(
        frameUrl: frameUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_familyLevelsCollection)
          .doc(level.id)
          .update(updatedLevel.toFirestore());
    } catch (e) {
      debugPrint('Error updating family level: $e');
      rethrow;
    }
  }

  // Delete family level
  static Future<void> deleteFamilyLevel(String levelId, String? frameUrl) async {
    try {
      if (frameUrl != null && frameUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(frameUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting frame image: $e');
          // Continue with document deletion even if image deletion fails
        }
      }

      await _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_familyLevelsCollection)
          .doc(levelId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting family level: $e');
      rethrow;
    }
  }
}
