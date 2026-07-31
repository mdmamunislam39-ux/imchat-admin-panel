import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FamilyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _familiesCollection = 'families';
  static const String _usersCollection = 'Users';

  // Get stream of all families
  static Stream<List<Map<String, dynamic>>> getFamiliesStream() {
    return _firestore
        .collection(_familiesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Search user by Profile ID (searchId)
  static Future<Map<String, dynamic>?> searchUserByProfileId(String profileId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('searchId', isEqualTo: profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['fullname'] ?? data['username'] ?? 'Unknown User',
          'profileId': data['searchId'] ?? '',
          'imageUrl': data['profileImage'] ?? data['profileImageUrl'] ?? data['photoUrl'] ?? '',
          'familyId': data['familyId'] ?? '',
          'familyName': data['familyName'] ?? '',
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error searching user by profile ID: $e');
      return null;
    }
  }

  // Create a new family manually by Admin
  static Future<bool> createFamily({
    required String name,
    required String description,
    required String logoUrl,
    required String creatorUserId,
    required String creatorName,
    required String creatorPhoto,
  }) async {
    try {
      final batch = _firestore.batch();
      
      final familyRef = _firestore.collection(_familiesCollection).doc();
      final familyId = familyRef.id;

      final familyData = {
        'familyId': familyId,
        'familyName': name,
        'description': description,
        'logoUrl': logoUrl,
        'creatorId': creatorUserId,
        'creatorName': creatorName,
        'creatorPhoto': creatorPhoto,
        'memberIds': [creatorUserId],
        'points': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(familyRef, familyData);

      // Update creator's family fields in Users collection
      final userRef = _firestore.collection(_usersCollection).doc(creatorUserId);
      batch.update(userRef, {
        'familyId': familyId,
        'familyName': name,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error creating family: $e');
      return false;
    }
  }

  // Update family details
  static Future<bool> updateFamily(String familyId, Map<String, dynamic> data) async {
    try {
      final batch = _firestore.batch();
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      
      batch.update(familyRef, data);

      // If familyName is updated, sync it to all members in Users collection
      if (data.containsKey('familyName')) {
        final newName = data['familyName'];
        final membersSnapshot = await _firestore
            .collection(_usersCollection)
            .where('familyId', isEqualTo: familyId)
            .get();

        for (var memberDoc in membersSnapshot.docs) {
          batch.update(memberDoc.reference, {
            'familyName': newName,
          });
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error updating family: $e');
      return false;
    }
  }

  // Dissolve/Delete a family
  static Future<bool> deleteFamily(String familyId) async {
    try {
      final batch = _firestore.batch();

      // Find all members in Users collection and clear family fields
      final membersSnapshot = await _firestore
          .collection(_usersCollection)
          .where('familyId', isEqualTo: familyId)
          .get();

      for (var memberDoc in membersSnapshot.docs) {
        batch.update(memberDoc.reference, {
          'familyId': null,
          'familyName': null,
        });
      }

      // Delete the family document
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.delete(familyRef);

      // Also clean up family requests associated with this family
      final requestsSnapshot = await _firestore
          .collection('family_requests')
          .where('familyId', isEqualTo: familyId)
          .get();

      for (var requestDoc in requestsSnapshot.docs) {
        batch.delete(requestDoc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting family: $e');
      return false;
    }
  }

  // Add a member to the family
  static Future<bool> addMember(String familyId, String familyName, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
      });

      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'familyId': familyId,
        'familyName': familyName,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error adding member to family: $e');
      return false;
    }
  }

  // Remove a member from the family
  static Future<bool> removeMember(String familyId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final familyRef = _firestore.collection(_familiesCollection).doc(familyId);
      batch.update(familyRef, {
        'memberIds': FieldValue.arrayRemove([userId]),
      });

      final userRef = _firestore.collection(_usersCollection).doc(userId);
      batch.update(userRef, {
        'familyId': null,
        'familyName': null,
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error removing member from family: $e');
      return false;
    }
  }

  // Get details of all users currently in a family
  static Future<List<Map<String, dynamic>>> getFamilyMembers(List<dynamic> memberIds) async {
    if (memberIds.isEmpty) return [];
    
    try {
      // Firestore 'in' query supports up to 10 elements at once
      final List<Map<String, dynamic>> members = [];
      
      // Batch member IDs in chunks of 10
      for (var i = 0; i < memberIds.length; i += 10) {
        final chunk = memberIds.sublist(i, i + 10 > memberIds.length ? memberIds.length : i + 10);
        final querySnapshot = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          members.add({
            'id': doc.id,
            'name': data['fullname'] ?? data['username'] ?? 'Unknown User',
            'profileId': data['searchId'] ?? '',
            'imageUrl': data['profileImage'] ?? data['profileImageUrl'] ?? data['photoUrl'] ?? '',
          });
        }
      }
      
      return members;
    } catch (e) {
      debugPrint('Error getting family members: $e');
      return [];
    }
  }
}
