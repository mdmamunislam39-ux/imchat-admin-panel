import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gift_transaction_model.dart';
import '../models/bean_conversion_model.dart';

class GiftReceivingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fallback constants
  static const double hostReceiverRate = 0.70;
  static const double hostAgencyRate = 0.10;
  static const double normalReceiverRate = 0.50;
  static const double beanToDiamondRate = 1.0;

  // Bean Exchange Packages Collection
  static final CollectionReference _packagesCollection =
      _firestore.collection('bean_exchange_packages');

  static const List<Map<String, int>> defaultPackages = [
    {'diamonds': 1000, 'beans': 1000},
    {'diamonds': 5000, 'beans': 5000},
    {'diamonds': 15100, 'beans': 15000},
    {'diamonds': 60800, 'beans': 60000},
    {'diamonds': 245000, 'beans': 240000},
    {'diamonds': 1225000, 'beans': 1200000},
    {'diamonds': 6125000, 'beans': 6000000},
  ];

  /// Initialize default exchange packages if collection is empty
  static Future<void> initializeDefaultExchangePackages() async {
    try {
      final snap = await _packagesCollection.limit(1).get();
      if (snap.docs.isEmpty) {
        final batch = _firestore.batch();
        for (int i = 0; i < defaultPackages.length; i++) {
          final pkg = defaultPackages[i];
          final docRef = _packagesCollection.doc();
          batch.set(docRef, {
            'diamonds': pkg['diamonds'],
            'beans': pkg['beans'],
            'sortOrder': i,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        debugPrint('Initialized default bean exchange packages');
      }
    } catch (e) {
      debugPrint('Error initializing default exchange packages: $e');
    }
  }

  /// Stream exchange packages in real-time ordered by beans
  static Stream<QuerySnapshot> streamExchangePackages() {
    return _packagesCollection.orderBy('beans', descending: false).snapshots();
  }

  /// Add new package to bean wall
  static Future<bool> addExchangePackage({
    required int diamonds,
    required int beans,
  }) async {
    try {
      await _packagesCollection.add({
        'diamonds': diamonds,
        'beans': beans,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Added exchange package: $diamonds diamonds for $beans beans');
      return true;
    } catch (e) {
      debugPrint('Error adding exchange package: $e');
      return false;
    }
  }

  /// Update existing package
  static Future<bool> updateExchangePackage({
    required String packageId,
    required int diamonds,
    required int beans,
  }) async {
    try {
      await _packagesCollection.doc(packageId).update({
        'diamonds': diamonds,
        'beans': beans,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Updated exchange package $packageId: $diamonds diamonds, $beans beans');
      return true;
    } catch (e) {
      debugPrint('Error updating exchange package: $e');
      return false;
    }
  }

  /// Delete exchange package
  static Future<bool> deleteExchangePackage(String packageId) async {
    try {
      await _packagesCollection.doc(packageId).delete();
      debugPrint('Deleted exchange package: $packageId');
      return true;
    } catch (e) {
      debugPrint('Error deleting exchange package: $e');
      return false;
    }
  }

  /// Initialize default conversion config in Firestore
  static Future<void> initializeConversionConfig() async {
    try {
      final docRef = _firestore.collection('platform_config').doc('gift_conversion');
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'hostReceiverRate': hostReceiverRate,
          'hostAgencyRate': hostAgencyRate,
          'normalReceiverRate': normalReceiverRate,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('Conversion config initialized with defaults');
      }
    } catch (e) {
      debugPrint('Error initializing conversion config: $e');
    }
  }

  /// Read current conversion config
  static Future<Map<String, dynamic>> getConversionConfig() async {
    try {
      final doc = await _firestore
          .collection('platform_config')
          .doc('gift_conversion')
          .get();

      if (doc.exists) {
        return doc.data()!;
      }

      // Return defaults if doc doesn't exist
      return {
        'hostReceiverRate': hostReceiverRate,
        'hostAgencyRate': hostAgencyRate,
        'normalReceiverRate': normalReceiverRate,
      };
    } catch (e) {
      debugPrint('Error getting conversion config: $e');
      return {
        'hostReceiverRate': hostReceiverRate,
        'hostAgencyRate': hostAgencyRate,
        'normalReceiverRate': normalReceiverRate,
      };
    }
  }

  /// Admin updates conversion rates
  static Future<bool> updateConversionRates({
    double? newHostReceiverRate,
    double? newHostAgencyRate,
    double? newNormalReceiverRate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (newHostReceiverRate != null) {
        updates['hostReceiverRate'] = newHostReceiverRate;
      }
      if (newHostAgencyRate != null) {
        updates['hostAgencyRate'] = newHostAgencyRate;
      }
      if (newNormalReceiverRate != null) {
        updates['normalReceiverRate'] = newNormalReceiverRate;
      }

      await _firestore
          .collection('platform_config')
          .doc('gift_conversion')
          .set(updates, SetOptions(merge: true));

      debugPrint('Conversion rates updated: $updates');
      return true;
    } catch (e) {
      debugPrint('Error updating conversion rates: $e');
      return false;
    }
  }

  /// Process a gift received — atomic transaction
  static Future<bool> processGiftReceived({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required ReceiverType receiverType,
    required double diamondAmount,
    required String giftName,
    String? agencyId,
  }) async {
    try {
      final config = await getConversionConfig();

      double beansToReceiver;
      double beansToAgency = 0.0;
      double platformShare;

      if (receiverType == ReceiverType.host) {
        final receiverRate = (config['hostReceiverRate'] ?? hostReceiverRate).toDouble();
        final agencyRate = (config['hostAgencyRate'] ?? hostAgencyRate).toDouble();
        beansToReceiver = diamondAmount * receiverRate;
        beansToAgency = diamondAmount * agencyRate;
        platformShare = diamondAmount - beansToReceiver - beansToAgency;
      } else {
        final receiverRate = (config['normalReceiverRate'] ?? normalReceiverRate).toDouble();
        beansToReceiver = diamondAmount * receiverRate;
        platformShare = diamondAmount - beansToReceiver;
      }

      await _firestore.runTransaction((transaction) async {
        // Update receiver beans
        final receiverRef = _firestore.collection('Users').doc(receiverId);
        transaction.update(receiverRef, {
          'beans': FieldValue.increment(beansToReceiver),
        });

        // Write gift_transactions record
        final txnRef = _firestore.collection('gift_transactions').doc();
        transaction.set(txnRef, {
          'senderId': senderId,
          'senderName': senderName,
          'receiverId': receiverId,
          'receiverName': receiverName,
          'receiverType': receiverType.name,
          'diamondAmount': diamondAmount,
          'beansToReceiver': beansToReceiver,
          'beansToAgency': beansToAgency,
          'platformShare': platformShare,
          'agencyId': agencyId,
          'giftName': giftName,
          'createdAt': Timestamp.now(),
        });

        // Write host_earnings if host (so CommissionService picks it up)
        if (receiverType == ReceiverType.host) {
          final earningRef = _firestore.collection('host_earnings').doc();
          transaction.set(earningRef, {
            'hostId': receiverId,
            'diamondsEarned': diamondAmount,
            'beansEarned': beansToReceiver,
            'agencyId': agencyId,
            'earningDate': Timestamp.now(),
            'source': 'gift',
            'giftName': giftName,
            'createdAt': Timestamp.now(),
          });
        }
      });

      debugPrint('Gift processed: $diamondAmount diamonds from $senderName to $receiverName');
      return true;
    } catch (e) {
      debugPrint('Error processing gift: $e');
      return false;
    }
  }

  /// Admin query: get gift transactions
  static Future<List<GiftTransactionModel>> getGiftTransactions({
    String? filterType,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('gift_transactions')
          .orderBy('createdAt', descending: true);

      if (filterType != null && filterType.isNotEmpty) {
        query = query.where('receiverType', isEqualTo: filterType);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs
          .map((doc) => GiftTransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting gift transactions: $e');
      return [];
    }
  }

  /// Admin: gift statistics for stat cards
  static Future<Map<String, dynamic>> getGiftStatistics() async {
    try {
      final snapshot = await _firestore.collection('gift_transactions').get();

      double totalDiamonds = 0.0;
      double totalBeansDistributed = 0.0;
      double totalPlatformShare = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalDiamonds += (data['diamondAmount'] ?? 0.0).toDouble();
        totalBeansDistributed += (data['beansToReceiver'] ?? 0.0).toDouble();
        totalBeansDistributed += (data['beansToAgency'] ?? 0.0).toDouble();
        totalPlatformShare += (data['platformShare'] ?? 0.0).toDouble();
      }

      return {
        'totalGifts': snapshot.docs.length,
        'totalDiamonds': totalDiamonds,
        'totalBeansDistributed': totalBeansDistributed,
        'totalPlatformShare': totalPlatformShare,
      };
    } catch (e) {
      debugPrint('Error getting gift statistics: $e');
      return {};
    }
  }

  /// Convert beans to diamonds — atomic transaction
  static Future<bool> convertBeansToDiamonds({
    required String userId,
    required String username,
    required double amount,
  }) async {
    try {
      final config = await getConversionConfig();
      final rate = (config['beanToDiamondRate'] ?? beanToDiamondRate).toDouble();
      final diamondsReceived = amount * rate;

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('Users').doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) throw Exception('User not found');

        final currentBeans = (userDoc.data()?['beans'] ?? 0.0).toDouble();
        if (currentBeans < amount) throw Exception('Insufficient beans');

        // Deduct beans, add diamonds (diamonds)
        transaction.update(userRef, {
          'beans': FieldValue.increment(-amount),
          'diamonds': FieldValue.increment(diamondsReceived),
        });

        // Write bean_conversions record
        final conversionRef = _firestore.collection('bean_conversions').doc();
        transaction.set(conversionRef, {
          'userId': userId,
          'username': username,
          'beansSpent': amount,
          'diamondsReceived': diamondsReceived,
          'createdAt': Timestamp.now(),
        });
      });

      debugPrint('Converted $amount beans to $diamondsReceived diamonds for $username');
      return true;
    } catch (e) {
      debugPrint('Error converting beans to diamonds: $e');
      return false;
    }
  }

  /// Admin query: get bean conversions
  static Future<List<BeanConversionModel>> getBeanConversions({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bean_conversions')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => BeanConversionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting bean conversions: $e');
      return [];
    }
  }

  /// Admin query: aggregate gift history stats
  static Future<List<Map<String, dynamic>>> getGiftHistoryStats() async {
    try {
      // In a production environment with millions of records, this should be handled by a 
      // Cloud Function that maintains rolling counts. For now, we perform an in-memory aggregation.
      final snapshot = await _firestore.collection('gift_transactions').get();
      final now = DateTime.now();
      
      final Map<String, Map<String, dynamic>> stats = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String giftName = data['giftName'] ?? 'Unknown';
        final double diamondAmount = (data['diamondAmount'] ?? 0.0).toDouble();
        
        DateTime createdAt;
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } else {
          continue;
        }

        if (!stats.containsKey(giftName)) {
          stats[giftName] = {
            'giftName': giftName,
            'diamondAmount': diamondAmount,
            'dailyCount': 0,
            'weeklyCount': 0,
            'monthlyCount': 0,
            'totalCount': 0,
          };
        }

        final stat = stats[giftName]!;
        stat['totalCount'] += 1;

        final difference = now.difference(createdAt);
        if (difference.inHours <= 24) {
          stat['dailyCount'] += 1;
        }
        if (difference.inDays <= 7) {
          stat['weeklyCount'] += 1;
        }
        if (difference.inDays <= 30) {
          stat['monthlyCount'] += 1;
        }
      }

      return stats.values.toList();
    } catch (e) {
      debugPrint('Error getting gift history stats: $e');
      return [];
    }
  }
}
