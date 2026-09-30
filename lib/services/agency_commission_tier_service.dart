import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/agency_commission_tier_model.dart';

class AgencyCommissionTierService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _globalSettingsCollection = 'settings';
  static const String _commissionTiersSubCollection = 'agency_commission_tiers';
  static const String _globalDoc = 'agency_commission_tiers';

  /// Stream of all commission tiers ordered by required diamonds/tier level
  static Stream<List<AgencyCommissionTierModel>> getTiersStream() {
    return _firestore
        .collection(_globalSettingsCollection)
        .doc('global')
        .collection(_commissionTiersSubCollection)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AgencyCommissionTierModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.minTargetDiamonds != b.minTargetDiamonds) {
          return a.minTargetDiamonds.compareTo(b.minTargetDiamonds);
        }
        return a.tierLevel.compareTo(b.tierLevel);
      });
      return list;
    });
  }

  /// Get list of commission tiers once
  static Future<List<AgencyCommissionTierModel>> getTiers() async {
    try {
      final snapshot = await _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_commissionTiersSubCollection)
          .get();

      final list = snapshot.docs
          .map((doc) => AgencyCommissionTierModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        if (a.minTargetDiamonds != b.minTargetDiamonds) {
          return a.minTargetDiamonds.compareTo(b.minTargetDiamonds);
        }
        return a.tierLevel.compareTo(b.tierLevel);
      });
      return list;
    } catch (e) {
      debugPrint('Error getting agency commission tiers: $e');
      return [];
    }
  }

  /// Add or update a commission tier
  static Future<bool> saveTier(AgencyCommissionTierModel tier) async {
    try {
      final collectionRef = _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_commissionTiersSubCollection);

      String docId = tier.id.trim();
      if (docId.isEmpty) {
        final docRef = collectionRef.doc();
        docId = docRef.id;
      }

      final tierWithId = tier.copyWith(
        id: docId,
        updatedAt: DateTime.now(),
      );

      await collectionRef.doc(docId).set(tierWithId.toFirestore(), SetOptions(merge: true));

      // Mirror summary list to global_settings for fast direct retrieval in mobile app
      await _syncToGlobalSettings();

      return true;
    } catch (e) {
      debugPrint('Error saving agency commission tier: $e');
      return false;
    }
  }

  /// Delete a commission tier
  static Future<bool> deleteTier(String tierId) async {
    try {
      await _firestore
          .collection(_globalSettingsCollection)
          .doc('global')
          .collection(_commissionTiersSubCollection)
          .doc(tierId)
          .delete();

      // Mirror sync after delete
      await _syncToGlobalSettings();

      return true;
    } catch (e) {
      debugPrint('Error deleting agency commission tier: $e');
      return false;
    }
  }

  /// Mirror to global_settings/agency_commission_tiers and system_configs/agency_commission_tiers
  static Future<void> _syncToGlobalSettings() async {
    try {
      final tiers = await getTiers();
      final tiersMapList = tiers.map((t) => t.toFirestore()).toList();

      final payload = {
        'tiers': tiersMapList,
        'count': tiers.length,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('global_settings').doc(_globalDoc).set(payload, SetOptions(merge: true));
      await _firestore.collection('system_configs').doc(_globalDoc).set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error mirroring agency commission tiers to global_settings: $e');
    }
  }

  /// Seed default standard tiers if none exist
  static Future<bool> seedDefaultTiers() async {
    try {
      final defaultTiers = [
        AgencyCommissionTierModel(
          id: 'tier_1',
          tierLevel: 1,
          tierName: 'Tier 1',
          minTargetDiamonds: 10000,
          commissionPercentage: 5.0,
          bonusRewardDiamonds: 500,
          badgeColorHex: '#4CAF50',
          description: 'Weekly target 10K diamonds for 5% commission & 500 diamond bonus',
          isActive: true,
        ),
        AgencyCommissionTierModel(
          id: 'tier_2',
          tierLevel: 2,
          tierName: 'Tier 2',
          minTargetDiamonds: 50000,
          commissionPercentage: 8.0,
          bonusRewardDiamonds: 3000,
          badgeColorHex: '#2196F3',
          description: 'Weekly target 50K diamonds for 8% commission & 3,000 diamond bonus',
          isActive: true,
        ),
        AgencyCommissionTierModel(
          id: 'tier_3',
          tierLevel: 3,
          tierName: 'Tier 3',
          minTargetDiamonds: 100000,
          commissionPercentage: 10.0,
          bonusRewardDiamonds: 7000,
          badgeColorHex: '#FFB300',
          description: 'Weekly target 100K diamonds for 10% commission & 7,000 diamond bonus',
          isActive: true,
        ),
        AgencyCommissionTierModel(
          id: 'tier_4',
          tierLevel: 4,
          tierName: 'Tier 4',
          minTargetDiamonds: 500000,
          commissionPercentage: 15.0,
          bonusRewardDiamonds: 40000,
          badgeColorHex: '#9C27B0',
          description: 'Weekly target 500K diamonds for 15% commission & 40,000 diamond bonus',
          isActive: true,
        ),
        AgencyCommissionTierModel(
          id: 'tier_5',
          tierLevel: 5,
          tierName: 'Tier 5',
          minTargetDiamonds: 1000000,
          commissionPercentage: 20.0,
          bonusRewardDiamonds: 100000,
          badgeColorHex: '#E91E63',
          description: 'Weekly target 1M diamonds for 20% commission & 100,000 diamond bonus',
          isActive: true,
        ),
      ];

      for (var tier in defaultTiers) {
        await _firestore
            .collection(_globalSettingsCollection)
            .doc('global')
            .collection(_commissionTiersSubCollection)
            .doc(tier.id)
            .set(tier.toFirestore(), SetOptions(merge: true));
      }

      await _syncToGlobalSettings();
      return true;
    } catch (e) {
      debugPrint('Error seeding default agency commission tiers: $e');
      return false;
    }
  }
}
