import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SvipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and auto-upgrade user's SVIP level if they meet the threshold
  static Future<void> checkAndAutoUpgradeSvip({
    required String userId,
    required int newRechargeAmount,
    required String currentMonth,
    required Transaction transaction,
    required DocumentReference userRef,
    required Map<String, dynamic> userData,
    required List<Map<String, dynamic>> svipLevels,
  }) async {
    try {
      // Check SVIP auto-upgrade
      int currentActiveSvip = userData['activeSvipLevel'] ?? 0;
      int highestEligibleSvip = currentActiveSvip;
      Map<String, dynamic>? highestSvipData;

      for (var level in svipLevels) {
        final levelId = level['id'] as String;
        final levelNum = int.tryParse(levelId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
        final rawTarget = level['rechargeTarget'];
        final target = rawTarget is int ? rawTarget : (rawTarget is double ? rawTarget.toInt() : (int.tryParse(rawTarget?.toString() ?? '0') ?? 0));
        
        if (newRechargeAmount >= target && levelNum > highestEligibleSvip) {
          highestEligibleSvip = levelNum;
          highestSvipData = level;
        }
      }

      Map<String, dynamic> custData = userData['customization'] ?? {};
      bool hasUpdates = false;

      void addAssetToInventory(String listKey, String url) {
        if (url.isNotEmpty) {
          List<String> currentList = List<String>.from(custData[listKey] ?? []);
          if (!currentList.contains(url)) {
            currentList.add(url);
            custData[listKey] = currentList;
            hasUpdates = true;
          }
        }
      }

      // Apply SVIP Upgrade if eligible
      if (highestEligibleSvip > currentActiveSvip && highestSvipData != null) {
        final levelId = highestSvipData['id'] as String;
        final claimedRef = _firestore.collection('Users').doc(userId).collection('claimed_svips').doc(currentMonth);
        transaction.set(claimedRef, {levelId: true}, SetOptions(merge: true));

        transaction.update(userRef, {
          'activeSvipLevel': highestEligibleSvip,
          'svipValidUntilMonth': currentMonth,
        });

        addAssetToInventory('ownedBadges', (highestSvipData['badgeMediaUrl']?.toString() ?? '').isNotEmpty ? highestSvipData['badgeMediaUrl'] : highestSvipData['badgeUrl'] ?? '');
        addAssetToInventory('ownedFrames', (highestSvipData['frameMediaUrl']?.toString() ?? '').isNotEmpty ? highestSvipData['frameMediaUrl'] : highestSvipData['frameUrl'] ?? '');
        addAssetToInventory('ownedEntryEffects', (highestSvipData['entryEffectMediaUrl']?.toString() ?? '').isNotEmpty ? highestSvipData['entryEffectMediaUrl'] : highestSvipData['entryEffectUrl'] ?? '');
        addAssetToInventory('ownedBackgroundThemes', (highestSvipData['profileSkinMediaUrl']?.toString() ?? '').isNotEmpty ? highestSvipData['profileSkinMediaUrl'] : highestSvipData['profileSkinUrl'] ?? '');
        addAssetToInventory('ownedNameplates', (highestSvipData['nameplateMediaUrl']?.toString() ?? '').isNotEmpty ? highestSvipData['nameplateMediaUrl'] : highestSvipData['nameplateUrl'] ?? '');
      }

      if (hasUpdates) {
        transaction.update(userRef, {'customization': custData});
      }
    } catch (e) {
      debugPrint('Error auto-upgrading SVIP: $e');
    }
  }
}
