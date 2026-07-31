import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// A lightweight helper that writes official team messages directly to Firestore,
/// so they appear in the mobile app's imChat Team conversation.
class OfficialTeamHelper {
  static final _firestore = FirebaseFirestore.instance;
  static const String _officialTeamId = 'official_team';

  /// Generate a unique message ID
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 99999).toString();
    return 'msg_${timestamp}_$random';
  }

  /// Core: Write an official text message to a user's imChat Team conversation
  static Future<void> _sendMessage({
    required String receiverId,
    required String text,
  }) async {
    try {
      final msgId = _generateId();

      final msgMap = {
        'msgId': msgId,
        'senderId': _officialTeamId,
        'type': 'text',
        'textMsg': text, // Admin panel doesn't encrypt messages (plain text for official)
        'fileUrl': '',
        'gifUrl': '',
        'location': null,
        'roomShare': null,
        'videoThumbnail': '',
        'isRead': false,
        'isRecAudio': false,
        'isForwarded': false,
        'sentAt': FieldValue.serverTimestamp(),
        'replyMessage': null,
        'groupUpdate': null,
      };

      // Write to the user's imChat Team messages subcollection
      await _firestore
          .collection('Users/$receiverId/Chats/$_officialTeamId/Messages')
          .doc(msgId)
          .set(msgMap);

      // Update Chat node so the conversation appears in the list
      await _firestore
          .collection('Users/$receiverId/Chats')
          .doc(_officialTeamId)
          .set({
        'senderId': _officialTeamId,
        'msgType': 'text',
        'lastMsg': text,
        'msgId': msgId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Audit log
      await _firestore.collection('official_notification_logs').doc(msgId).set({
        'msgId': msgId,
        'senderId': _officialTeamId,
        'receiverId': receiverId,
        'textMsg': text,
        'sentAt': FieldValue.serverTimestamp(),
        'source': 'admin_panel',
      });

      debugPrint('✅ [OfficialTeamHelper] Message sent to $receiverId');
    } catch (e) {
      debugPrint('❌ [OfficialTeamHelper] Failed to send message: $e');
    }
  }

  /// Trigger: When admin assigns Agency status to a user
  static Future<void> sendAgencyAssignedCongratulations({
    required String userId,
    required String userName,
    required String agencyName,
  }) async {
    final msg =
        '🏆 Congratulations $userName! You have been assigned as an Agency Owner of "$agencyName". Welcome to the official agency program!';
    await _sendMessage(receiverId: userId, text: msg);
  }

  /// Trigger: When admin removes a host from an agency
  static Future<void> sendHostTerminationNotice({
    required String userId,
    required String userName,
    required String agencyName,
  }) async {
    final msg =
        '📢 Notice: $userName, you have been removed from "$agencyName". Your host status has been deactivated. Please contact support if you have any questions.';
    await _sendMessage(receiverId: userId, text: msg);
  }

  /// Trigger: When admin sends a host invitation from the admin panel
  static Future<void> sendHostInvitationMessage({
    required String receiverId,
    required String receiverName,
    required String invitationId,
    required String agencyId,
    required String agencyName,
  }) async {
    try {
      final msgId = _generateId();

      final msgMap = {
        'msgId': msgId,
        'senderId': _officialTeamId,
        'type': 'hostInvitation',
        'textMsg': '',
        'fileUrl': '',
        'gifUrl': '',
        'location': null,
        'roomShare': null,
        'invitationId': invitationId,
        'invitationAgencyId': agencyId,
        'invitationAgencyName': agencyName,
        'videoThumbnail': '',
        'isRead': false,
        'isRecAudio': false,
        'isForwarded': false,
        'sentAt': FieldValue.serverTimestamp(),
        'replyMessage': null,
        'groupUpdate': null,
      };

      await _firestore
          .collection('Users/$receiverId/Chats/$_officialTeamId/Messages')
          .doc(msgId)
          .set(msgMap);

      await _firestore
          .collection('Users/$receiverId/Chats')
          .doc(_officialTeamId)
          .set({
        'senderId': _officialTeamId,
        'msgType': 'hostInvitation',
        'lastMsg': '🏆 Agency invitation from $agencyName',
        'msgId': msgId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _firestore.collection('official_notification_logs').doc(msgId).set({
        'msgId': msgId,
        'senderId': _officialTeamId,
        'receiverId': receiverId,
        'textMsg': 'Agency invitation from $agencyName',
        'sentAt': FieldValue.serverTimestamp(),
        'source': 'admin_panel',
      });

      debugPrint('✅ [OfficialTeamHelper] Host invitation message sent to $receiverId');
    } catch (e) {
      debugPrint('❌ [OfficialTeamHelper] Failed to send host invitation message: $e');
    }
  }
}
