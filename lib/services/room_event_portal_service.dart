import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/room_event_portal_model.dart';

class RoomEventPortalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collectionPath = 'room_event_portal';

  // Get all portals
  Stream<List<RoomEventPortalModel>> getPortals() {
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RoomEventPortalModel.fromFirestore(doc))
          .toList();
          
      // Sort locally to avoid Firestore composite index requirement
      list.sort((a, b) {
        int orderCompare = a.orderIndex.compareTo(b.orderIndex);
        if (orderCompare != 0) return orderCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return list;
    });
  }

  // Add new portal
  Future<void> addPortal(RoomEventPortalModel portal, File? imageFile) async {
    try {
      String imageUrl = portal.imageUrl;

      if (imageFile != null) {
        // Upload image to Firebase Storage
        final ref = _storage
            .ref()
            .child('room_event_portal')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final newPortal = portal.copyWith(imageUrl: imageUrl);
      
      await _firestore.collection(_collectionPath).add(newPortal.toFirestore());
    } catch (e) {
      throw Exception('Failed to add portal: $e');
    }
  }

  // Update existing portal
  Future<void> updatePortal(RoomEventPortalModel portal, File? imageFile) async {
    try {
      String imageUrl = portal.imageUrl;

      if (imageFile != null) {
        // Upload new image
        final ref = _storage
            .ref()
            .child('room_event_portal')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(imageFile);
        imageUrl = await ref.getDownloadURL();
      }

      final updatedPortal = portal.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionPath)
          .doc(portal.id)
          .update(updatedPortal.toFirestore());
    } catch (e) {
      throw Exception('Failed to update portal: $e');
    }
  }

  // Delete portal
  Future<void> deletePortal(String id) async {
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete portal: $e');
    }
  }

  // Toggle active status
  Future<void> toggleStatus(String id, bool currentStatus) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(id)
          .update({'isActive': !currentStatus});
    } catch (e) {
      throw Exception('Failed to toggle status: $e');
    }
  }

  // Update order of multiple portals
  Future<void> updatePortalOrders(List<RoomEventPortalModel> portals) async {
    try {
      final batch = _firestore.batch();
      for (int i = 0; i < portals.length; i++) {
        final docRef = _firestore.collection(_collectionPath).doc(portals[i].id);
        batch.update(docRef, {'orderIndex': i});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update orders: $e');
    }
  }
}
