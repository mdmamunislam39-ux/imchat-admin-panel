import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class VipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Map config field name to inventory customization fields
  static Map<String, dynamic> _getFieldMapping(String field) {
    switch (field) {
      case 'badgeUrl':
      case 'badgeMediaUrl':
        return {
          'category': 'badge',
          'ownedFields': ['ownedBadges'],
          'selectedFields': ['selectedBadgeId', 'selectedBadge', 'selectedBadgeUrl'],
          'selectedListFields': <String>[],
        };
      case 'frameUrl':
      case 'frameMediaUrl':
        return {
          'category': 'frame',
          'ownedFields': ['ownedFrames'],
          'selectedFields': ['selectedFrameId', 'selectedFrame', 'selectedFrameUrl'],
          'selectedListFields': <String>[],
        };
      case 'entryEffectUrl':
      case 'entryEffectMediaUrl':
        return {
          'category': 'entryEffect',
          'ownedFields': ['ownedEntryEffects'],
          'selectedFields': ['selectedEntryEffectId', 'selectedEntryEffect', 'selectedEntryEffectUrl'],
          'selectedListFields': <String>[],
        };
      case 'profileSkinUrl':
      case 'profileSkinMediaUrl':
        return {
          'category': 'profileSkin',
          'ownedFields': ['ownedBackgroundThemes', 'ownedRoomProfileBackgrounds', 'ownedShortProfileThemes'],
          'selectedFields': ['selectedBackgroundThemeId', 'selectedBackgroundThemeUrl', 'selectedProfileSkinId'],
          'selectedListFields': <String>[],
        };
      case 'nameplateUrl':
      case 'nameplateMediaUrl':
        return {
          'category': 'nameplate',
          'ownedFields': ['ownedNameplates'],
          'selectedFields': ['selectedNameplateId', 'selectedNameplateUrl'],
          'selectedListFields': ['selectedNameplateIds'],
        };
      default:
        return {
          'category': 'unknown',
          'ownedFields': <String>[],
          'selectedFields': <String>[],
          'selectedListFields': <String>[],
        };
    }
  }

  /// Synchronize VIP/SVIP item change or removal across all affected users in real-time.
  /// 
  /// - If [newUrl] is empty/null and [oldUrl] is not empty: Item was REMOVED.
  ///   Removes [oldUrl] from all users' inventory and unselects it.
  /// - If [newUrl] is not empty and [oldUrl] is not empty: Item was CHANGED.
  ///   Replaces [oldUrl] with [newUrl] in all users' inventory and updates selected.
  /// - If [newUrl] is not empty and [oldUrl] is empty: Item was ADDED.
  ///   Grants [newUrl] to all users currently holding this VIP/SVIP level.
  static Future<int> syncItemChangeAcrossUsers({
    required bool isSvip,
    required String levelId, // e.g. 'vip1', 'svip2'
    required String field,   // e.g. 'badgeUrl', 'frameMediaUrl'
    required String oldUrl,
    required String newUrl,
  }) async {
    final cleanOld = oldUrl.trim();
    final cleanNew = newUrl.trim();

    // If no change occurred, do nothing
    if (cleanOld == cleanNew) return 0;

    final mapping = _getFieldMapping(field);
    final List<String> ownedFields = List<String>.from(mapping['ownedFields'] ?? []);
    final List<String> selectedFields = List<String>.from(mapping['selectedFields'] ?? []);
    final List<String> selectedListFields = List<String>.from(mapping['selectedListFields'] ?? []);

    if (ownedFields.isEmpty) return 0;

    final levelNum = int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    int affectedUsersCount = 0;

    try {
      final Set<String> targetUserIds = {};

      // 1. Query users who own the oldUrl in any of the owned fields
      if (cleanOld.isNotEmpty) {
        for (final ownedField in ownedFields) {
          try {
            final snap = await _firestore
                .collection('Users')
                .where('customization.$ownedField', arrayContains: cleanOld)
                .get();
            for (final doc in snap.docs) {
              targetUserIds.add(doc.id);
            }
          } catch (e) {
            debugPrint('Query by arrayContains failed for $ownedField: $e');
          }
        }
      }

      // 2. Query users who have active VIP/SVIP level of this levelId
      if (levelNum > 0) {
        final levelField = isSvip ? 'activeSvipLevel' : 'activeVipLevel';
        final altLevelField = isSvip ? 'svipLevel' : 'vipLevel';
        
        try {
          final snap1 = await _firestore
              .collection('Users')
              .where(levelField, isEqualTo: levelNum)
              .get();
          for (final doc in snap1.docs) {
            targetUserIds.add(doc.id);
          }
        } catch (_) {}

        try {
          final snap2 = await _firestore
              .collection('Users')
              .where(altLevelField, isEqualTo: levelNum)
              .get();
          for (final doc in snap2.docs) {
            targetUserIds.add(doc.id);
          }
        } catch (_) {}
      }

      if (targetUserIds.isEmpty) {
        return 0;
      }

      // 3. Process updates in batches of 400 (Firestore max is 500)
      final userIdsList = targetUserIds.toList();
      const batchSize = 400;

      for (int i = 0; i < userIdsList.length; i += batchSize) {
        final chunk = userIdsList.sublist(i, (i + batchSize > userIdsList.length) ? userIdsList.length : i + batchSize);
        final batch = _firestore.batch();
        int batchCount = 0;

        for (final userId in chunk) {
          final userDocRef = _firestore.collection('Users').doc(userId);
          final userDoc = await userDocRef.get();
          if (!userDoc.exists || userDoc.data() == null) continue;

          final userData = userDoc.data()!;
          final customization = Map<String, dynamic>.from(userData['customization'] as Map? ?? {});
          bool modified = false;

          // Check if this user is an active VIP/SVIP holder of this level
          final userActiveLevel = userData[isSvip ? 'activeSvipLevel' : 'activeVipLevel'] ?? 
                                 userData[isSvip ? 'svipLevel' : 'vipLevel'] ?? 0;
          final bool isActiveLevelHolder = (userActiveLevel is num && userActiveLevel == levelNum);

          for (final ownedField in ownedFields) {
            final ownedList = List<String>.from(customization[ownedField] as List? ?? []);

            if (cleanOld.isNotEmpty && ownedList.contains(cleanOld)) {
              if (cleanNew.isEmpty) {
                // Item Removed: remove oldUrl
                ownedList.removeWhere((item) => item == cleanOld);
                customization[ownedField] = ownedList;
                modified = true;
              } else {
                // Item Changed: replace oldUrl with newUrl
                final idx = ownedList.indexOf(cleanOld);
                if (idx != -1) {
                  ownedList[idx] = cleanNew;
                }
                if (!ownedList.contains(cleanNew)) {
                  ownedList.add(cleanNew);
                }
                customization[ownedField] = ownedList;
                modified = true;
              }
            } else if (cleanNew.isNotEmpty && isActiveLevelHolder) {
              // Active holder receives newUrl
              if (!ownedList.contains(cleanNew)) {
                ownedList.add(cleanNew);
                customization[ownedField] = ownedList;
                modified = true;
              }
            }
          }

          // Handle single selected fields
          for (final selectedField in selectedFields) {
            final currentSelected = customization[selectedField]?.toString() ?? '';
            if (cleanOld.isNotEmpty && currentSelected == cleanOld) {
              if (cleanNew.isEmpty) {
                // Unselect or reset
                customization[selectedField] = '';
                modified = true;
              } else {
                // Update selected to new URL
                customization[selectedField] = cleanNew;
                modified = true;
              }
            }
          }

          // Handle list selected fields (e.g. selectedNameplateIds)
          for (final selectedListField in selectedListFields) {
            final selectedList = List<String>.from(customization[selectedListField] as List? ?? []);
            if (cleanOld.isNotEmpty && selectedList.contains(cleanOld)) {
              if (cleanNew.isEmpty) {
                selectedList.removeWhere((item) => item == cleanOld);
                customization[selectedListField] = selectedList;
                modified = true;
              } else {
                final idx = selectedList.indexOf(cleanOld);
                if (idx != -1) {
                  selectedList[idx] = cleanNew;
                }
                customization[selectedListField] = selectedList;
                modified = true;
              }
            }
          }

          if (modified) {
            batch.update(userDocRef, {
              'customization': customization,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            batchCount++;
            affectedUsersCount++;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      }
    } catch (e) {
      debugPrint('Error syncing VIP/SVIP item change across users: $e');
    }

    return affectedUsersCount;
  }

  /// Remove a specific asset field from VIP/SVIP level and sync across all users in real-time
  static Future<int> removeItemAndSync({
    required bool isSvip,
    required String levelId,
    required String field,
    required String currentUrl,
  }) async {
    final collectionName = isSvip ? 'svip_levels' : 'vip_levels';

    // 1. Update Firestore Config Document
    await _firestore
        .collection('config')
        .doc(collectionName)
        .collection('levels')
        .doc(levelId)
        .set({
          field: '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // 2. Sync removal with users in real-time
    if (currentUrl.isNotEmpty) {
      return await syncItemChangeAcrossUsers(
        isSvip: isSvip,
        levelId: levelId,
        field: field,
        oldUrl: currentUrl,
        newUrl: '',
      );
    }
    return 0;
  }

  /// Remove both Thumbnail and Media of an item category from VIP/SVIP level and sync across users
  static Future<int> removeRewardPairAndSync({
    required bool isSvip,
    required String levelId,
    required String thumbField,
    required String mediaField,
    required String currentThumbUrl,
    required String currentMediaUrl,
  }) async {
    final collectionName = isSvip ? 'svip_levels' : 'vip_levels';

    // 1. Update Firestore Config Document
    await _firestore
        .collection('config')
        .doc(collectionName)
        .collection('levels')
        .doc(levelId)
        .set({
          thumbField: '',
          mediaField: '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    int count = 0;
    // 2. Sync thumbnail removal
    if (currentThumbUrl.isNotEmpty) {
      count += await syncItemChangeAcrossUsers(
        isSvip: isSvip,
        levelId: levelId,
        field: thumbField,
        oldUrl: currentThumbUrl,
        newUrl: '',
      );
    }

    // 3. Sync media removal
    if (currentMediaUrl.isNotEmpty && currentMediaUrl != currentThumbUrl) {
      count += await syncItemChangeAcrossUsers(
        isSvip: isSvip,
        levelId: levelId,
        field: mediaField,
        oldUrl: currentMediaUrl,
        newUrl: '',
      );
    }

    return count;
  }
}
