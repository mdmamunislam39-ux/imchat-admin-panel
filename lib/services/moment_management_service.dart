import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/moment_post_model.dart';

class MomentManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _postsCollection = 'news_feed_posts';
  static const String _reportsCollection = 'moment_reports';
  static const String _appSettingsCollection = 'app_settings';

  // ─── 1. Notices Management ────────────────────────────────────────────────

  /// Create an official notice post
  static Future<String?> createNoticePost({
    required String title,
    required String content,
    Uint8List? mediaBytes,
    String? mediaFileName,
    bool isPinned = true,
  }) async {
    try {
      final docRef = _firestore.collection(_postsCollection).doc();
      final now = DateTime.now();

      // Dynamically fetch App Logo URL from Admin Panel App Theme config
      String? appLogoUrl;
      try {
        final themeDoc = await _firestore.collection('global_settings').doc('app_theme').get();
        if (themeDoc.exists && themeDoc.data() != null) {
          final themeData = themeDoc.data()!;
          appLogoUrl = (themeData['appLogoUrl'] ?? themeData['appLogo'] ?? themeData['logoUrl']) as String?;
        }
      } catch (e) {
        debugPrint('Note: Could not fetch app logo url: $e');
      }

      List<PostMedia> mediaList = [];
      if (mediaBytes != null && mediaFileName != null) {
        final ext = mediaFileName.split('.').last.toLowerCase();
        final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
        final ref = _storage
            .ref()
            .child('news_feed_media/${docRef.id}/${now.millisecondsSinceEpoch}_$mediaFileName');
        
        final uploadTask = await ref.putData(
          mediaBytes,
          SettableMetadata(contentType: isVideo ? 'video/$ext' : 'image/$ext'),
        );
        final url = await uploadTask.ref.getDownloadURL();
        mediaList.add(PostMedia(url: url, type: isVideo ? 'video' : 'image'));
      }

      final post = NewsFeedPost(
        id: docRef.id,
        userId: 'admin_official',
        userName: 'imChat Official Notice',
        userAvatar: appLogoUrl,
        isVerified: true,
        content: content,
        noticeTitle: title,
        isNotice: true,
        isPinned: isPinned,
        media: mediaList,
        createdAt: now,
        updatedAt: now,
      );

      await docRef.set(post.toFirestore());
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [MomentManagementService] Error creating notice: $e');
      return null;
    }
  }

  /// Get real-time stream of official notices
  static Stream<List<NewsFeedPost>> getNoticesStream() {
    return _firestore
        .collection(_postsCollection)
        .where('isNotice', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsFeedPost.fromFirestore(doc))
          .where((post) => !post.isDeleted)
          .toList();
    });
  }

  // ─── 2. Moderation & All Moments Feed ────────────────────────────────────

  /// Get real-time stream of recent moments (All Moments tab)
  static Stream<List<NewsFeedPost>> getAllMomentsStream({int limit = 50}) {
    return _firestore
        .collection(_postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NewsFeedPost.fromFirestore(doc))
          .where((post) => !post.isDeleted)
          .toList();
    });
  }

  /// Soft delete a post
  static Future<void> deletePost(String postId) async {
    await _firestore.collection(_postsCollection).doc(postId).update({
      'isDeleted': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Toggle pin status on a post
  static Future<void> togglePinPost(String postId, bool isPinned) async {
    await _firestore.collection(_postsCollection).doc(postId).update({
      'isPinned': isPinned,
      'updatedAt': Timestamp.now(),
    });
  }

  // ─── 3. Reported Posts Management ──────────────────────────────────────

  /// Get stream of pending reported posts
  static Stream<QuerySnapshot<Map<String, dynamic>>> getReportedPostsStream() {
    return _firestore
        .collection(_reportsCollection)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Dismiss a post report
  static Future<void> dismissReport(String reportId) async {
    await _firestore.collection(_reportsCollection).doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': Timestamp.now(),
    });
  }

  /// Delete a reported post and mark report as resolved
  static Future<void> deleteReportedPost(String postId, String reportId) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection(_postsCollection).doc(postId), {
      'isDeleted': true,
      'updatedAt': Timestamp.now(),
    });
    batch.update(_firestore.collection(_reportsCollection).doc(reportId), {
      'status': 'resolved',
      'actionTaken': 'deleted',
      'resolvedAt': Timestamp.now(),
    });
    await batch.commit();
  }

  // ─── 4. AdSense Configuration ──────────────────────────────────────────

  /// Stream AdSense / AdMob settings
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getAdSettingsStream() {
    return _firestore
        .collection(_appSettingsCollection)
        .doc('moment_ads')
        .snapshots();
  }

  /// Fetch AdSense settings once
  static Future<Map<String, dynamic>?> getAdSettings() async {
    try {
      final doc = await _firestore
          .collection(_appSettingsCollection)
          .doc('moment_ads')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting ad settings: $e');
      return null;
    }
  }

  /// Update AdSense / AdMob settings
  static Future<void> updateAdSettings(Map<String, dynamic> settingsData) async {
    final dataToSave = Map<String, dynamic>.from(settingsData);
    dataToSave['updatedAt'] = Timestamp.now();

    await _firestore.collection(_appSettingsCollection).doc('moment_ads').set(
      dataToSave,
      SetOptions(merge: true),
    );
  }
}
