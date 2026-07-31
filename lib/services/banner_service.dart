import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/banner_model.dart';

class BannerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'banners';

  // Get stream of all banners, ordered by orderIndex
  static Stream<List<BannerModel>> getBannersStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BannerModel.fromFirestore(doc)).toList();
    });
  }

  // Create a new banner
  static Future<void> createBanner(BannerModel banner) async {
    try {
      await _firestore.collection(_collectionName).add({
        ...banner.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating banner: $e');
      rethrow;
    }
  }

  // Update an existing banner
  static Future<void> updateBanner(BannerModel banner) async {
    try {
      await _firestore.collection(_collectionName).doc(banner.id).update({
        ...banner.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating banner: $e');
      rethrow;
    }
  }

  // Delete a banner
  static Future<void> deleteBanner(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting banner: $e');
      rethrow;
    }
  }

  // Update banner order indexes after reordering
  static Future<void> updateBannerOrders(List<BannerModel> banners) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < banners.length; i++) {
        final docRef = _firestore.collection(_collectionName).doc(banners[i].id);
        batch.update(docRef, {
          'orderIndex': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error updating banner orders: $e');
      rethrow;
    }
  }

  // Toggle banner active status
  static Future<void> toggleBannerStatus(String id, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling banner status: $e');
      rethrow;
    }
  }
}
