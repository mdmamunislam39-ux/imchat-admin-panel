import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/channel_model.dart';
import '../models/channel_post_model.dart';

class ChannelService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _channelsCollection = 'official_channels';
  static const String _postsCollection = 'channel_posts';

  // --- Channels ---

  static Stream<List<ChannelModel>> getChannelsStream() {
    return _firestore
        .collection(_channelsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChannelModel.fromFirestore(doc)).toList();
    });
  }

  static Future<void> createChannel(ChannelModel channel) async {
    try {
      final docRef = _firestore.collection(_channelsCollection).doc();
      final newChannel = channel.copyWith(id: docRef.id);
      
      await docRef.set({
        ...newChannel.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Mirror in Users collection so chat list can find its profile
      await _firestore.collection('Users').doc(newChannel.id).set({
        'id': newChannel.id,
        'userId': newChannel.id,
        'username': newChannel.name,
        'name': newChannel.name,
        'profileImageUrl': newChannel.imageUrl,
        'imageUrl': newChannel.imageUrl,
        'userType': 'regular',
        'isOfficialChannel': true,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Asynchronously broadcast to all users
      _broadcastChannelToAllUsers(newChannel);
    } catch (e) {
      debugPrint('Error creating channel: $e');
      rethrow;
    }
  }

  static Future<void> updateChannel(ChannelModel channel) async {
    try {
      await _firestore.collection(_channelsCollection).doc(channel.id).update({
        ...channel.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update mirror in Users collection
      try {
        await _firestore.collection('Users').doc(channel.id).update({
          'username': channel.name,
          'name': channel.name,
          'profileImageUrl': channel.imageUrl,
          'imageUrl': channel.imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // If it doesn't exist, create it
        await _firestore.collection('Users').doc(channel.id).set({
          'id': channel.id,
          'userId': channel.id,
          'username': channel.name,
          'name': channel.name,
          'profileImageUrl': channel.imageUrl,
          'imageUrl': channel.imageUrl,
          'userType': 'regular',
          'isOfficialChannel': true,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Asynchronously update channel info in users' chat lists
      _broadcastChannelUpdateToAllUsers(channel);
    } catch (e) {
      debugPrint('Error updating channel: $e');
      rethrow;
    }
  }

  static Future<void> deleteChannel(String id) async {
    try {
      // Start a batch to delete the channel and its posts
      final batch = _firestore.batch();
      final channelRef = _firestore.collection(_channelsCollection).doc(id);
      batch.delete(channelRef);

      // Delete mirror in Users collection
      batch.delete(_firestore.collection('Users').doc(id));

      // Get all posts for this channel and delete them
      final postsSnapshot = await _firestore
          .collection(_postsCollection)
          .where('channelId', isEqualTo: id)
          .get();
      
      for (var doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting channel: $e');
      rethrow;
    }
  }

  static Future<void> toggleVerification(String id, bool isVerified) async {
    try {
      await _firestore.collection(_channelsCollection).doc(id).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling channel verification: $e');
      rethrow;
    }
  }

  // --- Posts ---

  static Stream<List<ChannelPostModel>> getChannelPostsStream(String channelId) {
    return _firestore
        .collection(_postsCollection)
        .where('channelId', isEqualTo: channelId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) => ChannelPostModel.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  static Future<void> createPost(ChannelPostModel post, {List<Map<String, dynamic>>? targetUsers}) async {
    try {
      final docRef = _firestore.collection(_postsCollection).doc();
      final newPost = post.copyWith(id: docRef.id);

      await docRef.set(<String, dynamic>{
        ...newPost.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (targetUsers == null) {
        // Asynchronously broadcast post to all users' chat lists
        _broadcastPostToAllUsers(newPost);
      } else {
        // Asynchronously broadcast post to target users' chat lists
        _broadcastPostToTargetUsers(newPost, targetUsers);
      }
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  static Future<void> deletePost(String id) async {
    try {
      await _firestore.collection(_postsCollection).doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  // --- Broadcasting ---

  static Future<void> _broadcastChannelToAllUsers(ChannelModel channel) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      final users = usersSnapshot.docs;

      final int batchSize = 500;
      for (int i = 0; i < users.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < users.length) ? i + batchSize : users.length;
        final chunk = users.sublist(i, end);

        for (var user in chunk) {
          final chatRef = _firestore
              .collection('Users')
              .doc(user.id)
              .collection('Chats')
              .doc(channel.id);
          
          batch.set(chatRef, {
            'id': channel.id,
            'channelId': channel.id,
            'name': channel.name,
            'username': channel.name,
            'channelName': channel.name,
            'image': channel.imageUrl,
            'imageUrl': channel.imageUrl,
            'profileImageUrl': channel.imageUrl,
            'profileImage': channel.imageUrl,
            'lastMessage': 'Welcome to the official channel!',
            'message': 'Welcome to the official channel!',
            'latestMessage': 'Welcome to the official channel!',
            'text': 'Welcome to the official channel!',
            'timestamp': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'official_channel',
            'unreadCount': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      debugPrint('Successfully broadcasted channel to ${users.length} users.');
    } catch (e) {
      debugPrint('Error broadcasting channel to users: $e');
    }
  }

  static Future<void> _broadcastChannelUpdateToAllUsers(ChannelModel channel) async {
    try {
      final usersSnapshot = await _firestore.collection('Users').get();
      final users = usersSnapshot.docs;

      final int batchSize = 500;
      for (int i = 0; i < users.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < users.length) ? i + batchSize : users.length;
        final chunk = users.sublist(i, end);

        for (var user in chunk) {
          final chatRef = _firestore
              .collection('Users')
              .doc(user.id)
              .collection('Chats')
              .doc(channel.id);
          
          batch.set(chatRef, {
            'name': channel.name,
            'username': channel.name,
            'channelName': channel.name,
            'image': channel.imageUrl,
            'imageUrl': channel.imageUrl,
            'profileImageUrl': channel.imageUrl,
            'profileImage': channel.imageUrl,
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error broadcasting channel update: $e');
    }
  }

  static Future<void> _broadcastPostToAllUsers(ChannelPostModel post) async {
    try {
      final channelDoc = await _firestore.collection(_channelsCollection).doc(post.channelId).get();
      if (!channelDoc.exists) return;
      final channel = ChannelModel.fromFirestore(channelDoc);

      final usersSnapshot = await _firestore.collection('Users').get();
      final users = usersSnapshot.docs;

      String message = post.textContent ?? '';
      if (message.isEmpty) {
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          message = '📷 Image Post';
        } else if (post.voiceRoomId != null && post.voiceRoomId!.isNotEmpty) {
          message = '🎤 Voice Room Shared';
        } else if (post.linkUrl != null && post.linkUrl!.isNotEmpty) {
          message = '🔗 Link Shared';
        }
      }

      final int batchSize = 500;
      for (int i = 0; i < users.length; i += batchSize) {
        // Yield to the event loop to prevent UI freezing on large datasets
        await Future.delayed(const Duration(milliseconds: 50));
        
        final batch = _firestore.batch();
        final end = (i + batchSize < users.length) ? i + batchSize : users.length;
        final chunk = users.sublist(i, end);

        final List<String> tokensToSend = [];

        for (var user in chunk) {
          final data = user.data();
          final deviceToken = data['deviceToken']?.toString() ?? '';
          if (deviceToken.isNotEmpty) {
            tokensToSend.add(deviceToken);
          }

          final chatRef = _firestore
              .collection('Users')
              .doc(user.id)
              .collection('Chats')
              .doc(channel.id);
          
          batch.set(chatRef, {
            'id': channel.id,
            'channelId': channel.id,
            'name': channel.name,
            'username': channel.name,
            'channelName': channel.name,
            'image': channel.imageUrl,
            'imageUrl': channel.imageUrl,
            'profileImageUrl': channel.imageUrl,
            'profileImage': channel.imageUrl,
            'lastMessage': message,
            'message': message,
            'latestMessage': message,
            'text': message,
            'timestamp': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'type': 'official_channel',
            'unreadCount': FieldValue.increment(1),
          }, SetOptions(merge: true));

          final msgRef = chatRef.collection('Messages').doc(post.id);
          batch.set(msgRef, {
            'msgId': post.id,
            'senderId': channel.id,
            'type': 'text',
            'textMsg': message,
            'fileUrl': post.imageUrl ?? '',
            'gifUrl': '',
            'location': null,
            'roomShare': post.voiceRoomId,
            'videoThumbnail': '',
            'isRead': false,
            'isRecAudio': false,
            'isForwarded': false,
            'sentAt': FieldValue.serverTimestamp(),
            'replyMessage': null,
            'groupUpdate': null,
          });
        }
        await batch.commit();

        // Send push notifications asynchronously to this batch
        _sendFCMNotifications(
          tokens: tokensToSend,
          title: channel.name,
          body: message,
          senderId: channel.id,
          senderAvatar: channel.imageUrl,
        );
      }
      debugPrint('Successfully broadcasted post to ${users.length} users.');
    } catch (e) {
      debugPrint('Error broadcasting post to users: $e');
    }
  }

  static Future<void> _sendFCMNotifications({
    required List<String> tokens,
    required String title,
    required String body,
    required String senderId,
    required String senderAvatar,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final url = 'https://us-central1-imchat-84519.cloudfunctions.net/sendPushNotification';

      for (final token in tokens) {
        http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null) 'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({
            'data': {
              'type': 'message',
              'title': title,
              'body': body,
              'deviceToken': token,
              'senderId': senderId,
              'senderAvatar': senderAvatar,
              'call': {},
            }
          }),
        ).catchError((e) {
          debugPrint('Error sending channel post FCM notification: $e');
          return http.Response('', 500);
        });
      }
    } catch (e) {
      debugPrint('Error in _sendFCMNotifications: $e');
    }
  }

  static Future<void> _broadcastPostToTargetUsers(ChannelPostModel post, List<Map<String, dynamic>> targetUsers) async {
    try {
      final channelDoc = await _firestore.collection(_channelsCollection).doc(post.channelId).get();
      if (!channelDoc.exists) return;
      final channel = ChannelModel.fromFirestore(channelDoc);

      String message = post.textContent ?? '';
      if (message.isEmpty) {
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
          message = '📷 Image Post';
        } else if (post.audioUrl != null && post.audioUrl!.isNotEmpty) {
          message = '🎵 Voice Message';
        } else if (post.voiceRoomId != null && post.voiceRoomId!.isNotEmpty) {
          message = '🎤 Voice Room Shared';
        } else if (post.linkUrl != null && post.linkUrl!.isNotEmpty) {
          message = '🔗 Link Shared';
        }
      }

      final int batchSize = 500;
      for (int i = 0; i < targetUsers.length; i += batchSize) {
        await Future.delayed(const Duration(milliseconds: 50));
        
        final batch = _firestore.batch();
        final end = (i + batchSize < targetUsers.length) ? i + batchSize : targetUsers.length;
        final chunk = targetUsers.sublist(i, end);

        final List<String> tokensToSend = [];

        for (var user in chunk) {
          final userId = user['userId'] ?? user['id'] ?? '';
          if (userId.isEmpty) continue;

          final deviceToken = user['deviceToken']?.toString() ?? '';
          if (deviceToken.isNotEmpty) {
            tokensToSend.add(deviceToken);
          }

          final chatRef = _firestore
              .collection('Users')
              .doc(userId)
              .collection('Chats')
              .doc(channel.id);
          
          batch.set(chatRef, {
            'id': channel.id,
            'channelId': channel.id,
            'name': channel.name,
            'username': channel.name,
            'channelName': channel.name,
            'image': channel.imageUrl,
            'imageUrl': channel.imageUrl,
            'profileImageUrl': channel.imageUrl,
            'profileImage': channel.imageUrl,
            'lastMessage': message,
            'message': message,
            'latestMessage': message,
            'text': message,
            'timestamp': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'type': 'official_channel',
            'unreadCount': FieldValue.increment(1),
          }, SetOptions(merge: true));

          final msgRef = chatRef.collection('Messages').doc(post.id);
          final bool isAudio = post.audioUrl != null && post.audioUrl!.isNotEmpty;
          batch.set(msgRef, {
            'msgId': post.id,
            'senderId': channel.id,
            'type': isAudio ? 'audio' : 'text',
            'textMsg': message,
            'fileUrl': post.imageUrl ?? (isAudio ? post.audioUrl : ''),
            'gifUrl': '',
            'location': null,
            'roomShare': post.voiceRoomId,
            'videoThumbnail': '',
            'isRead': false,
            'isRecAudio': isAudio,
            'isForwarded': false,
            'sentAt': FieldValue.serverTimestamp(),
            'replyMessage': null,
            'groupUpdate': null,
          });
        }
        await batch.commit();

        // Send push notifications asynchronously to this batch
        _sendFCMNotifications(
          tokens: tokensToSend,
          title: channel.name,
          body: message,
          senderId: channel.id,
          senderAvatar: channel.imageUrl,
        );
      }
      debugPrint('Successfully broadcasted post to ${targetUsers.length} target users.');
    } catch (e) {
      debugPrint('Error broadcasting post to target users: $e');
    }
  }
}
