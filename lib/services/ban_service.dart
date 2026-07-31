import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ban_model.dart';
import '../models/channel_model.dart';
import '../models/channel_post_model.dart';
import '../services/channel_service.dart';

class BanService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _bansCollection = 'Bans';
  static const String _usersCollection = 'Users';
  static const String _audioRoomsCollection = 'audio_rooms_v2';
  static const String _bannedDevicesCollection = 'BannedDevices';

  /// Applies a ban to a user, device, or room, and logs it in the Bans collection.
  static Future<bool> applyBan(BanModel ban) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Log the ban in the main Bans collection
      final banRef = _firestore.collection(_bansCollection).doc();
      final banData = ban.copyWithId(banRef.id).toFirestore();
      batch.set(banRef, banData);

      // 2. Apply specific enforcement flags based on ban type
      switch (ban.type) {
        case BanType.login:
          final userRef = _firestore.collection(_usersCollection).doc(ban.targetId);
          batch.update(userRef, {
            'isLoginBanned': true,
            'loginBanExpiry': ban.isPermanent ? null : (ban.expiresAt != null ? Timestamp.fromDate(ban.expiresAt!) : null),
          });
          break;
          
        case BanType.mic:
          final userRef = _firestore.collection(_usersCollection).doc(ban.targetId);
          batch.update(userRef, {
            'isMicBanned': true,
            'micBanExpiry': ban.isPermanent ? null : (ban.expiresAt != null ? Timestamp.fromDate(ban.expiresAt!) : null),
          });
          break;
          
        case BanType.chat:
          final userRef = _firestore.collection(_usersCollection).doc(ban.targetId);
          batch.update(userRef, {
            'isChatBanned': true,
            'chatBanExpiry': ban.isPermanent ? null : (ban.expiresAt != null ? Timestamp.fromDate(ban.expiresAt!) : null),
          });
          break;

        case BanType.device:
          final deviceRef = _firestore.collection(_bannedDevicesCollection).doc(ban.targetId);
          batch.set(deviceRef, {
            'isBanned': true,
            'banExpiry': ban.isPermanent ? null : (ban.expiresAt != null ? Timestamp.fromDate(ban.expiresAt!) : null),
            'reason': ban.reason,
            'issuedAt': Timestamp.fromDate(ban.issuedAt),
            'issuedBy': ban.issuedBy,
          }, SetOptions(merge: true));
          break;

        case BanType.room:
          final roomRef = _firestore.collection(_audioRoomsCollection).doc(ban.targetId);
          batch.update(roomRef, {
            'isBanned': true,
            'banExpiry': ban.isPermanent ? null : (ban.expiresAt != null ? Timestamp.fromDate(ban.expiresAt!) : null),
          });
          break;
      }

      await batch.commit();

      // Post notification to Official Channel
      try {
        // Find an official channel
        var channelsSnapshot = await _firestore
            .collection('official_channels')
            .where('name', isEqualTo: 'imChat Official')
            .limit(1)
            .get();

        if (channelsSnapshot.docs.isEmpty) {
          channelsSnapshot = await _firestore
              .collection('official_channels')
              .where('name', isEqualTo: 'imChat official')
              .limit(1)
              .get();
        }

        // Fallback to the first available official channel if specific name not found
        if (channelsSnapshot.docs.isEmpty) {
           channelsSnapshot = await _firestore
              .collection('official_channels')
              .limit(1)
              .get();
        }

        String channelId = '';
        if (channelsSnapshot.docs.isNotEmpty) {
          channelId = channelsSnapshot.docs.first.id;
        } else {
          // Create the official channel if it doesn't exist (fire and forget)
          final docRef = _firestore.collection('official_channels').doc();
          channelId = docRef.id;
          final newChannel = ChannelModel(
            id: channelId,
            name: 'imChat Official',
            imageUrl: 'https://ui-avatars.com/api/?name=imChat+Official&background=0D8ABC&color=fff',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ChannelService.createChannel(newChannel).catchError(
            (e) => debugPrint('Error auto-creating channel: $e')
          );
        }

        String typeStr = ban.type.name.toUpperCase();
        String durationStr = ban.isPermanent 
            ? "Permanently" 
            : (ban.expiresAt != null ? "until ${ban.expiresAt.toString().substring(0, 16)}" : "Temporarily");
        String reasonStr = ban.reason.isNotEmpty ? "Reason: ${ban.reason}" : "No reason provided.";
        
        String text = "🛑 BAN ALERT 🛑\nTarget ID: ${ban.targetId}\nType: $typeStr\nDuration: $durationStr\n$reasonStr";

        // Fire and forget post creation to prevent UI hanging
        ChannelService.createPost(ChannelPostModel(
          id: '',
          channelId: channelId,
          textContent: text,
          createdAt: DateTime.now(),
        )).catchError((e) => debugPrint('Error posting ban notification: $e'));
      } catch (e) {
        debugPrint('Error posting ban notification: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error applying ban: $e');
      return false;
    }
  }

  /// Revokes a ban by marking it inactive and removing enforcement flags.
  static Future<bool> revokeBan(BanModel ban) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Mark the ban record as inactive
      final banRef = _firestore.collection(_bansCollection).doc(ban.id);
      batch.update(banRef, {'isActive': false});

      // 2. Remove enforcement flags
      switch (ban.type) {
        case BanType.login:
        case BanType.mic:
        case BanType.chat:
          final userRef = _firestore.collection(_usersCollection).doc(ban.targetId);
          
          if (ban.type == BanType.login) {
            batch.update(userRef, {'isLoginBanned': false, 'loginBanExpiry': null});
          } else if (ban.type == BanType.mic) {
            batch.update(userRef, {'isMicBanned': false, 'micBanExpiry': null});
          } else if (ban.type == BanType.chat) {
            batch.update(userRef, {'isChatBanned': false, 'chatBanExpiry': null});
          }
          break;
          
        case BanType.device:
          final deviceRef = _firestore.collection(_bannedDevicesCollection).doc(ban.targetId);
          batch.delete(deviceRef); // Remove device ban entirely
          break;
          
        case BanType.room:
          final roomRef = _firestore.collection(_audioRoomsCollection).doc(ban.targetId);
          batch.update(roomRef, {'isBanned': false, 'banExpiry': null});
          break;
      }

      await batch.commit();

      // Post notification to Official Channel for UNBAN
      try {
        var channelsSnapshot = await _firestore
            .collection('official_channels')
            .where('name', isEqualTo: 'imChat Official')
            .limit(1)
            .get();

        if (channelsSnapshot.docs.isEmpty) {
          channelsSnapshot = await _firestore
              .collection('official_channels')
              .where('name', isEqualTo: 'imChat official')
              .limit(1)
              .get();
        }

        if (channelsSnapshot.docs.isEmpty) {
           channelsSnapshot = await _firestore
              .collection('official_channels')
              .limit(1)
              .get();
        }

        String channelId = '';
        if (channelsSnapshot.docs.isNotEmpty) {
          channelId = channelsSnapshot.docs.first.id;
        } else {
          // Create the official channel if it doesn't exist (fire and forget)
          final docRef = _firestore.collection('official_channels').doc();
          channelId = docRef.id;
          final newChannel = ChannelModel(
            id: channelId,
            name: 'imChat Official',
            imageUrl: 'https://ui-avatars.com/api/?name=imChat+Official&background=0D8ABC&color=fff',
            isVerified: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ChannelService.createChannel(newChannel).catchError(
            (e) => debugPrint('Error auto-creating channel: $e')
          );
        }

        String typeStr = ban.type.name.toUpperCase();
        
        String text = "✅ UNBAN ALERT ✅\nTarget ID: ${ban.targetId}\nType: $typeStr\nStatus: Ban Revoked";

        // Fire and forget post creation to prevent UI hanging
        ChannelService.createPost(ChannelPostModel(
          id: '',
          channelId: channelId,
          textContent: text,
          createdAt: DateTime.now(),
        )).catchError((e) => debugPrint('Error posting unban notification: $e'));
      } catch (e) {
        debugPrint('Error posting unban notification: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error revoking ban: $e');
      return false;
    }
  }

  /// Gets all active bans for a specific target.
  static Future<List<BanModel>> getActiveBansForTarget(String targetId) async {
    try {
      final snapshot = await _firestore
          .collection(_bansCollection)
          .where('targetId', isEqualTo: targetId)
          .get();
          
      final bans = snapshot.docs.map((doc) => BanModel.fromFirestore(doc)).toList();
      return bans.where((b) => b.isActive).toList();
    } catch (e) {
      debugPrint('Error fetching active bans: $e');
      return [];
    }
  }

  /// Gets all bans.
  static Future<List<BanModel>> getAllBans() async {
    try {
      final snapshot = await _firestore
          .collection(_bansCollection)
          .get();
          
      final bans = snapshot.docs.map((doc) => BanModel.fromFirestore(doc)).toList();
      bans.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return bans;
    } catch (e) {
      debugPrint('Error fetching all bans: $e');
      return [];
    }
  }
}

extension BanModelX on BanModel {
  BanModel copyWithId(String newId) {
    return BanModel(
      id: newId,
      targetId: targetId,
      type: type,
      reason: reason,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      issuedBy: issuedBy,
      isPermanent: isPermanent,
      isActive: isActive,
    );
  }
}
