import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';

class AppThemeAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _collection = 'global_settings';
  static const String _doc = 'app_theme';

  /// Fetch current theme configuration
  static Future<Map<String, dynamic>?> getThemeConfig() async {
    try {
      final docSnap = await _firestore.collection(_collection).doc(_doc).get();
      if (docSnap.exists) {
        return docSnap.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load theme config: $e');
    }
  }

  /// Update theme configuration
  static Future<void> updateThemeConfig(Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(_doc).set(
        data,
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update theme config: $e');
    }
  }

  /// Upload an asset/image to Firebase Storage and return its URL
  static Future<String> uploadImage(
    Uint8List fileBytes,
    String folderPath, {
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
        case 'svg':
          contentType = 'image/svg+xml';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          ext = 'jpg';
          break;
        default:
          ext = 'png';
          contentType = 'image/png';
      }

      final String fileName = '${const Uuid().v4()}.$ext';
      final Reference ref = _storage.ref().child('app_theme/$folderPath/$fileName');
      
      final UploadTask uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: contentType),
      );
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
