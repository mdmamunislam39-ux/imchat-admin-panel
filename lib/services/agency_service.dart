import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/agency_model.dart';
import '../models/host_model.dart';
import '../models/agency_notification_model.dart';
import '../helpers/official_team_helper.dart';

class AgencyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Agency Management
  static Future<String> createAgency(AgencyModel agency) async {
    try {
      final docRef = await _firestore.collection('agencies').add(agency.toFirestore());
      await docRef.update({'agencyId': docRef.id});
      debugPrint('Agency created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating agency: $e');
      rethrow;
    }
  }

  static Future<AgencyModel?> getAgency(String agencyId) async {
    try {
      final doc = await _firestore.collection('agencies').doc(agencyId).get();
      if (doc.exists) {
        return AgencyModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting agency: $e');
      return null;
    }
  }

  /// Real-time stream of all agencies, ordered by creation date descending.
  static Stream<List<AgencyModel>> getAgenciesStream() {
    return _firestore
        .collection('agencies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AgencyModel.fromFirestore(doc)).toList());
  }

  static Future<List<AgencyModel>> getAllAgencies() async {
    try {
      final querySnapshot = await _firestore
          .collection('agencies')
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AgencyModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting all agencies: $e');
      return [];
    }
  }

  /// Update the commission rate for an agency (value as decimal, e.g. 0.15 = 15%).
  static Future<bool> updateCommissionRate(String agencyId, double rate) async {
    try {
      await _firestore.collection('agencies').doc(agencyId).update({
        'commissionRate': rate,
        'updatedAt': Timestamp.now(),
      });
      debugPrint('Commission rate updated to $rate for agency $agencyId');
      return true;
    } catch (e) {
      debugPrint('Error updating commission rate: $e');
      return false;
    }
  }

  /// Hold (pause) or resume commission payouts for an agency.
  static Future<bool> toggleCommissionHold(String agencyId, {required bool hold}) async {
    try {
      await _firestore.collection('agencies').doc(agencyId).update({
        'isCommissionHeld': hold,
        'updatedAt': Timestamp.now(),
      });
      debugPrint('Commission hold set to $hold for agency $agencyId');
      return true;
    } catch (e) {
      debugPrint('Error toggling commission hold: $e');
      return false;
    }
  }

  static Future<bool> updateAgency(String agencyId, AgencyModel agency) async {
    try {
      await _firestore.collection('agencies').doc(agencyId).update(agency.toFirestore());
      debugPrint('Agency updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating agency: $e');
      return false;
    }
  }

  static Future<bool> deleteAgency(String agencyId) async {
    try {
      // Get the agency to find the ownerUserId
      final agencyDoc = await _firestore.collection('agencies').doc(agencyId).get();
      if (agencyDoc.exists) {
        final data = agencyDoc.data()!;
        final ownerUserId = data['ownerUserId'];
        if (ownerUserId != null && ownerUserId.toString().isNotEmpty) {
          // Check if user has other agencies
          final otherAgencies = await _firestore
              .collection('agencies')
              .where('ownerUserId', isEqualTo: ownerUserId)
              .get();
          
          final activeOtherAgencies = otherAgencies.docs.where((doc) => doc.id != agencyId).toList();
          
          if (activeOtherAgencies.isEmpty) {
            // Safe to clear roles
            await _firestore.collection('Users').doc(ownerUserId.toString()).update({
              'isAgency': false,
              'agencyId': null,
              'agencyName': null,
              'userType': 'regular',
              'roles': FieldValue.arrayRemove(['agency']),
            });
            debugPrint('Safely reset agency status for owner: $ownerUserId');
          } else {
            debugPrint('Owner $ownerUserId still has other active agencies. Roles not reset.');
          }
        }
      }
      
      await _firestore.collection('agencies').doc(agencyId).delete();
      debugPrint('Agency deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting agency: $e');
      return false;
    }
  }

  // User search functionality (similar to seller service)
  static Future<List<Map<String, dynamic>>> searchUser(String query) async {
    try {
      if (query.isEmpty) {
        // Return all users if no query
        final querySnapshot = await _firestore
            .collection('Users')
            .limit(50)
            .get();
        
        return querySnapshot.docs.map((doc) {
          final userData = doc.data();
          return {
            'id': doc.id,
            'name': userData['fullname'] ?? 'Unknown',
            'profileId': userData['searchId'] ?? '',
            'phone': userData['number'] ?? '',
            'email': userData['email'] ?? '',
            'address': userData['address'] ?? '',
            'balance': (userData['diamonds'] ?? 0.0).toDouble(),
            'isAgency': userData['isAgency'] ?? false,
            'userType': userData['userType'] ?? 'regular',
            'agencyId': userData['agencyId'] ?? '',
          };
        }).toList();
      }

      // Search by profile ID or phone number
      final querySnapshot = await _firestore
          .collection('Users')
          .where('searchId', isGreaterThanOrEqualTo: query)
          .where('searchId', isLessThan: '$query\uf8ff')
          .limit(10)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Try searching by phone number
        final phoneQuery = await _firestore
            .collection('Users')
            .where('number', isGreaterThanOrEqualTo: query)
            .where('number', isLessThan: '$query\uf8ff')
            .limit(10)
            .get();
        
        return phoneQuery.docs.map((doc) {
          final userData = doc.data();
          return {
            'id': doc.id,
            'name': userData['fullname'] ?? 'Unknown',
            'profileId': userData['searchId'] ?? '',
            'phone': userData['number'] ?? '',
            'email': userData['email'] ?? '',
            'address': userData['address'] ?? '',
            'balance': (userData['diamonds'] ?? 0.0).toDouble(),
            'isAgency': userData['isAgency'] ?? false,
            'userType': userData['userType'] ?? 'regular',
            'agencyId': userData['agencyId'] ?? '',
          };
        }).toList();
      }

      return querySnapshot.docs.map((doc) {
        final userData = doc.data();
        return {
          'id': doc.id,
          'name': userData['fullname'] ?? 'Unknown',
          'profileId': userData['searchId'] ?? '',
          'phone': userData['number'] ?? '',
          'email': userData['email'] ?? '',
          'address': userData['address'] ?? '',
          'balance': (userData['diamonds'] ?? 0.0).toDouble(),
          'isAgency': userData['isAgency'] ?? false,
          'userType': userData['userType'] ?? 'regular',
          'agencyId': userData['agencyId'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error searching user: $e');
      return [];
    }
  }

  // Host Management
  static Future<String> addHostToAgency(HostModel host) async {
    try {
      final docRef = await _firestore.collection('hosts').add(host.toFirestore());
      
      // Update agency host count
      await _firestore.collection('agencies').doc(host.agencyId).update({
        'totalHosts': FieldValue.increment(1),
        'hostIds': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('Host added to agency successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding host to agency: $e');
      rethrow;
    }
  }

  static Future<List<HostModel>> getAgencyHosts(String agencyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('hosts')
          .where('agencyId', isEqualTo: agencyId)
          .orderBy('joinedDate', descending: true)
          .get();
      
      final List<HostModel> uniqueHosts = [];
      final Set<String> seenUserIds = {};
      for (var doc in querySnapshot.docs) {
        final host = HostModel.fromFirestore(doc);
        if (host.isActive && !seenUserIds.contains(host.userId)) {
          seenUserIds.add(host.userId);
          uniqueHosts.add(host);
        }
      }
      return uniqueHosts;
    } catch (e) {
      debugPrint('Error getting agency hosts: $e');
      return [];
    }
  }

  static Future<HostModel?> getHost(String hostId) async {
    try {
      final doc = await _firestore.collection('hosts').doc(hostId).get();
      if (doc.exists) {
        return HostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting host: $e');
      return null;
    }
  }

  static Future<bool> updateHost(String hostId, HostModel host) async {
    try {
      await _firestore.collection('hosts').doc(hostId).update(host.toFirestore());
      debugPrint('Host updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating host: $e');
      return false;
    }
  }

  static Future<bool> removeHostFromAgency(String hostId, String agencyId) async {
    try {
      // Fetch host and agency info before deactivating (for notification)
      String hostUserId = '';
      String hostName = '';
      String agencyName = '';
      try {
        final hostDoc = await _firestore.collection('hosts').doc(hostId).get();
        if (hostDoc.exists) {
          hostUserId = hostDoc.data()?['userId'] ?? '';
          hostName = hostDoc.data()?['hostName'] ?? '';
        }
        final agencyDoc = await _firestore.collection('agencies').doc(agencyId).get();
        if (agencyDoc.exists) {
          agencyName = agencyDoc.data()?['agencyName'] ?? '';
        }
      } catch (_) {}

      // Update host status
      await _firestore.collection('hosts').doc(hostId).update({
        'isActive': false,
        'status': 'terminated',
        'updatedAt': Timestamp.now(),
      });

      // Clear host user agency fields
      if (hostUserId.isNotEmpty) {
        await _firestore.collection('Users').doc(hostUserId).update({
          'agencyId': null,
          'agencyName': null,
          'userType': 'regular',
        });
      }
      
      // Update agency host count
      await _firestore.collection('agencies').doc(agencyId).update({
        'totalHosts': FieldValue.increment(-1),
        'hostIds': FieldValue.arrayRemove([hostId]),
        'updatedAt': Timestamp.now(),
      });

      // Send termination notice via imChat official team
      if (hostUserId.isNotEmpty) {
        try {
          await OfficialTeamHelper.sendHostTerminationNotice(
            userId: hostUserId,
            userName: hostName.isNotEmpty ? hostName : 'Host',
            agencyName: agencyName.isNotEmpty ? agencyName : 'the agency',
          );
        } catch (ex) {
          debugPrint('⚠️ Failed to send official team termination notice: $ex');
        }
      }
      
      debugPrint('Host removed from agency successfully');
      return true;
    } catch (e) {
      debugPrint('Error removing host from agency: $e');
      return false;
    }
  }

  // Host Invitation System
  static Future<String> sendHostInvitation(HostInvitationModel invitation) async {
    try {
      final docRef = await _firestore.collection('host_invitations').add(invitation.toFirestore());
      
      // Create notification for the host
      await _firestore.collection('notifications').add({
        'userId': invitation.hostUserId,
        'title': 'Agency Invitation',
        'message': 'You have been invited to join ${invitation.agencyName} agency',
        'type': 'host_invitation',
        'data': {
          'invitationId': docRef.id,
          'agencyId': invitation.agencyId,
          'agencyName': invitation.agencyName,
        },
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
      
      debugPrint('Host invitation sent successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending host invitation: $e');
      rethrow;
    }
  }

  static Future<bool> acceptHostInvitation(String invitationId) async {
    try {
      final invitationDoc = await _firestore.collection('host_invitations').doc(invitationId).get();
      if (!invitationDoc.exists) return false;
      
      final invitation = HostInvitationModel.fromFirestore(invitationDoc);
      
      // Update invitation status
      await _firestore.collection('host_invitations').doc(invitationId).update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });
      
      // Create host record
      final host = HostModel(
        id: '',
        userId: invitation.hostUserId,
        agencyId: invitation.agencyId,
        hostName: invitation.hostName,
        phone: invitation.hostPhone,
        email: invitation.hostEmail,
        joinedDate: DateTime.now(),
        performance: HostPerformance(lastUpdated: DateTime.now()),
      );
      
      await addHostToAgency(host);
      
      debugPrint('Host invitation accepted successfully');
      return true;
    } catch (e) {
      debugPrint('Error accepting host invitation: $e');
      return false;
    }
  }

  static Future<bool> rejectHostInvitation(String invitationId) async {
    try {
      await _firestore.collection('host_invitations').doc(invitationId).update({
        'status': 'rejected',
        'respondedAt': Timestamp.now(),
      });
      
      debugPrint('Host invitation rejected successfully');
      return true;
    } catch (e) {
      debugPrint('Error rejecting host invitation: $e');
      return false;
    }
  }

  // Commission and Earnings Management
  static Future<double> calculateWeeklyCommission(String agencyId, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final hosts = await getAgencyHosts(agencyId);
      double totalCommission = 0.0;
      
      for (final host in hosts) {
        // Get host earnings for the week
        final earningsQuery = await _firestore
            .collection('host_earnings')
            .where('hostId', isEqualTo: host.id)
            .where('earningDate', isGreaterThanOrEqualTo: weekStart)
            .where('earningDate', isLessThan: weekEnd)
            .get();
        
        double hostWeeklyDiamonds = 0.0;
        for (final doc in earningsQuery.docs) {
          final data = doc.data();
          hostWeeklyDiamonds += (data['diamondsEarned'] ?? 0.0).toDouble();
        }
        
        // Calculate 10% commission
        final commission = hostWeeklyDiamonds * 0.10;
        totalCommission += commission;
        
        // Record the commission
        await _firestore.collection('agency_commissions').add({
          'agencyId': agencyId,
          'hostId': host.id,
          'weekStart': Timestamp.fromDate(weekStart),
          'weekEnd': Timestamp.fromDate(weekEnd),
          'hostDiamondsEarned': hostWeeklyDiamonds,
          'commissionAmount': commission,
          'createdAt': Timestamp.now(),
        });
      }
      
      // Update agency total commission
      await _firestore.collection('agencies').doc(agencyId).update({
        'totalCommissionEarned': FieldValue.increment(totalCommission),
        'updatedAt': Timestamp.now(),
      });
      
      debugPrint('Weekly commission calculated: $totalCommission');
      return totalCommission;
    } catch (e) {
      debugPrint('Error calculating weekly commission: $e');
      return 0.0;
    }
  }

  static Future<List<HostEarning>> getHostEarnings(String hostId, EarningPeriod period) async {
    try {
      DateTime startDate;
      final now = DateTime.now();
      
      switch (period) {
        case EarningPeriod.daily:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case EarningPeriod.weekly:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case EarningPeriod.monthly:
          startDate = DateTime(now.year, now.month, 1);
          break;
      }
      
      final querySnapshot = await _firestore
          .collection('host_earnings')
          .where('hostId', isEqualTo: hostId)
          .where('earningDate', isGreaterThanOrEqualTo: startDate)
          .orderBy('earningDate', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => HostEarning.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting host earnings: $e');
      return [];
    }
  }

  // Notifications
  static Future<String> sendNotificationToHost(String hostId, String title, String message, NotificationType type) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': hostId,
        'title': title,
        'message': message,
        'type': type.name,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });
      
      debugPrint('Notification sent to host successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error sending notification to host: $e');
      rethrow;
    }
  }

  static Future<List<AgencyNotificationModel>> getAgencyNotifications(String agencyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('agency_notifications')
          .where('agencyId', isEqualTo: agencyId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      
      return querySnapshot.docs
          .map((doc) => AgencyNotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting agency notifications: $e');
      return [];
    }
  }

  // Analytics and Reports
  static Future<Map<String, dynamic>> getAgencyAnalytics(String agencyId) async {
    try {
      final hosts = await getAgencyHosts(agencyId);
      final agency = await getAgency(agencyId);
      
      if (agency == null) return {};
      
      double totalDiamonds = 0.0;
      int totalLiveHours = 0;
      int totalGifts = 0;
      double totalCommission = 0.0;
      
      for (final host in hosts) {
        totalDiamonds += host.performance.totalDiamonds;
        totalLiveHours += host.performance.totalLiveHours;
        totalGifts += host.performance.totalGiftsReceived;
      }
      
      // Calculate commission (10% of total diamonds)
      totalCommission = totalDiamonds * 0.10;
      
      return {
        'totalHosts': hosts.length,
        'activeHosts': hosts.where((h) => h.isActive).length,
        'totalDiamonds': totalDiamonds,
        'totalLiveHours': totalLiveHours,
        'totalGifts': totalGifts,
        'totalCommission': totalCommission,
        'averageHostRating': hosts.isNotEmpty 
            ? hosts.map((h) => h.performance.averageRating).reduce((a, b) => a + b) / hosts.length
            : 0.0,
      };
    } catch (e) {
      debugPrint('Error getting agency analytics: $e');
      return {};
    }
  }

  // Utility Methods
  static String generateAgencyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'AG${timestamp.toString().substring(8)}$random';
  }

  static Future<bool> isAgencyIdUnique(String agencyId) async {
    try {
      final querySnapshot = await _firestore
          .collection('agencies')
          .where('agencyIdNumber', isEqualTo: agencyId)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('Error checking agency ID uniqueness: $e');
      return false;
    }
  }
}
