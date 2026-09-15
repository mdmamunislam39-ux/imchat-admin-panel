import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OfficialNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _officialTeamId = 'official_team';

  /// Generate a unique message ID
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 99999).toString();
    return 'msg_${timestamp}_$random';
  }

  /// Upload media bytes (image or audio) to Firebase Storage
  static Future<String?> uploadFile({
    required Uint8List bytes,
    required String name,
    required String path,
  }) async {
    try {
      final storageName = 'official_team/$path/${DateTime.now().millisecondsSinceEpoch}_$name';
      final ref = FirebaseStorage.instance.ref().child(storageName);
      final uploadTask = await ref.putData(bytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file to storage: $e');
      return null;
    }
  }

  /// Sends an official message to a single user in Firestore and triggers a push notification
  static Future<void> sendOfficialNotification({
    required String receiverId,
    required String receiverDeviceToken,
    required String title,
    required String messageText,
    String? imageUrl,
    String? audioUrl,
    String? linkUrl,
    Map<String, dynamic>? roomShare,
  }) async {
    try {
      final msgId = _generateId();
      final sentAt = FieldValue.serverTimestamp();

      // Determine message type
      String messageType = 'text';
      if (audioUrl != null && audioUrl.isNotEmpty) {
        messageType = 'audio';
      } else if (imageUrl != null && imageUrl.isNotEmpty) {
        messageType = 'image';
      } else if (roomShare != null && roomShare.isNotEmpty) {
        messageType = 'roomShare';
      }

      // Determine display/preview text for lastMsg
      String previewText = messageText;
      if (previewText.isEmpty) {
        if (messageType == 'image') {
          previewText = '📷 Photo';
        } else if (messageType == 'audio') {
          previewText = '🎙️ Voice Message';
        } else if (messageType == 'roomShare') {
          previewText = '🎙️ Voice Room Shared';
        }
      }

      final Map<String, dynamic> msgMap = {
        'msgId': msgId,
        'senderId': _officialTeamId,
        'type': messageType,
        'textMsg': messageText,
        'fileUrl': audioUrl ?? imageUrl ?? '',
        'gifUrl': '',
        'location': null,
        'roomShare': roomShare,
        'videoThumbnail': '',
        'isRead': false,
        'isRecAudio': messageType == 'audio',
        'isForwarded': false,
        'sentAt': sentAt,
        'replyMessage': null,
        'groupUpdate': null,
      };

      if (linkUrl != null && linkUrl.isNotEmpty) {
        msgMap['linkUrl'] = linkUrl;
      }

      final batch = _firestore.batch();

      // 1. Save message in receiver's chat messages
      final msgRef = _firestore
          .collection('Users')
          .doc(receiverId)
          .collection('Chats')
          .doc(_officialTeamId)
          .collection('Messages')
          .doc(msgId);
      batch.set(msgRef, msgMap);

      // 2. Save message in official_notifications subcollection
      final officialNotificationRef = _firestore
          .collection('Users')
          .doc(receiverId)
          .collection('official_notifications')
          .doc(msgId);
      batch.set(officialNotificationRef, msgMap);

      // 3. Update Chat node for the receiver
      final chatRef = _firestore
          .collection('Users')
          .doc(receiverId)
          .collection('Chats')
          .doc(_officialTeamId);
      batch.set(chatRef, {
        'senderId': _officialTeamId,
        'msgType': messageType,
        'lastMsg': previewText,
        'msgId': msgId,
        'updatedAt': sentAt,
        'timestamp': sentAt,
      }, SetOptions(merge: true));

      // 4. Log the notification in central audit logs
      final logRef = _firestore.collection('official_notification_logs').doc(msgId);
      batch.set(logRef, {
        'msgId': msgId,
        'senderId': _officialTeamId,
        'receiverId': receiverId,
        'textMsg': messageText.isNotEmpty ? messageText : previewText,
        'sentAt': sentAt,
        'source': 'admin_panel',
      });

      // Commit all Firestore operations in a batch
      await batch.commit();
      debugPrint('Firestore database writes completed for user: $receiverId');

      // 5. Send FCM Push Notification if deviceToken is present
      if (receiverDeviceToken.isNotEmpty) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          final idToken = await user?.getIdToken();
          final url = 'https://us-central1-imchat-84519.cloudfunctions.net/sendPushNotification';
          
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (idToken != null) 'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'data': {
                'type': 'message',
                'title': title.isNotEmpty ? title : 'imChat Official team',
                'body': previewText,
                'deviceToken': receiverDeviceToken,
                'senderId': _officialTeamId,
                'senderAvatar': '',
                'call': roomShare != null && roomShare.isNotEmpty
                    ? {
                        'type': 'follower_room',
                        'roomId': roomShare['roomId'],
                      }
                    : {},
              }
            }),
          );
          
          if (response.statusCode == 200) {
            debugPrint('FCM notification sent successfully to user $receiverId via HTTP');
          } else {
            debugPrint('FCM notification failed with HTTP status: ${response.statusCode}, body: ${response.body}');
          }
        } catch (fcmError) {
          debugPrint('Error sending FCM push notification via HTTP: $fcmError');
        }
      } else {
        debugPrint('Skip FCM notification for user $receiverId (No device token found)');
      }
    } catch (e) {
      debugPrint('Error sending notification to user $receiverId: $e');
      rethrow;
    }
  }
}
