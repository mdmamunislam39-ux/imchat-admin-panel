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

  /// Upload an image to Firebase Storage and return its URL
  static Future<String> uploadImage(Uint8List fileBytes, String folderPath) async {
    try {
      final String fileName = '${const Uuid().v4()}.png';
      final Reference ref = _storage.ref().child('app_theme/$folderPath/$fileName');
      
      final UploadTask uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
