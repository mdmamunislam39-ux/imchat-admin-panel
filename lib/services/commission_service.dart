import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/agency_model.dart';
import '../models/host_model.dart';
import 'agency_service.dart';

class CommissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Commission calculation constants
  static const double commissionRate = 0.10; // 10%
  static const int commissionDay = 7; // Sunday (0 = Sunday, 1 = Monday, etc.)
  static const int commissionHour = 22; // 10 PM
  static const String commissionTimezone = 'Asia/Dhaka'; // Bangladesh Time

  /// Calculate and process weekly commissions for all agencies
  static Future<Map<String, dynamic>> processWeeklyCommissions() async {
    try {
      debugPrint('Starting weekly commission processing...');
      
      final results = {
        'totalAgencies': 0,
        'processedAgencies': 0,
        'totalCommission': 0.0,
        'errors': <String>[],
        'processedAgencyNames': <String>[],
      };

      // Get all active agencies
      final agenciesQuery = await _firestore
          .collection('agencies')
          .where('isActive', isEqualTo: true)
          .get();
      
      results['totalAgencies'] = agenciesQuery.docs.length;
      
      for (final agencyDoc in agenciesQuery.docs) {
        try {
          final agency = AgencyModel.fromFirestore(agencyDoc);
          final commission = await _calculateAgencyCommission(agency.id);
          
          if (commission > 0) {
            await _recordCommissionPayment(agency.id, commission);
            results['processedAgencies'] = (results['processedAgencies'] as int) + 1;
            results['totalCommission'] = (results['totalCommission'] as double) + commission;
            (results['processedAgencyNames'] as List<String>).add(agency.agencyName);
          }
        } catch (e) {
          debugPrint('Error processing commission for agency ${agencyDoc.id}: $e');
          (results['errors'] as List<String>).add('Agency ${agencyDoc.id}: $e');
        }
      }
      
      // Record the commission run
      await _recordCommissionRun(results);
      
      debugPrint('Weekly commission processing completed: $results');
      return results;
    } catch (e) {
      debugPrint('Error in weekly commission processing: $e');
      rethrow;
    }
  }

  /// Calculate commission for a specific agency
  static Future<double> _calculateAgencyCommission(String agencyId) async {
    try {
      // Get the start of the current week (Sunday)
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      debugPrint('Calculating commission for agency $agencyId from $weekStart to $weekEnd');
      
      // Get all hosts for this agency
      final hosts = await AgencyService.getAgencyHosts(agencyId);
      double totalCommission = 0.0;
      
      for (final host in hosts) {
        if (!host.isActive) continue;
        
        // Get host earnings for the week
        final hostCommission = await _calculateHostCommission(host, weekStart, weekEnd);
        totalCommission += hostCommission;
        
        // Record individual host commission
        if (hostCommission > 0) {
          await _recordHostCommission(host, weekStart, weekEnd, hostCommission);
        }
      }
      
      debugPrint('Total commission for agency $agencyId: $totalCommission');
      return totalCommission;
    } catch (e) {
      debugPrint('Error calculating agency commission: $e');
      return 0.0;
    }
  }

  /// Calculate commission for a specific host
  static Future<double> _calculateHostCommission(HostModel host, DateTime weekStart, DateTime weekEnd) async {
    try {
      // Get host earnings from the earnings collection
      final earningsQuery = await _firestore
          .collection('host_earnings')
          .where('hostId', isEqualTo: host.id)
          .where('earningDate', isGreaterThanOrEqualTo: weekStart)
          .where('earningDate', isLessThan: weekEnd)
          .get();
      
      double totalDiamonds = 0.0;
      
      for (final doc in earningsQuery.docs) {
        final data = doc.data();
        totalDiamonds += (data['diamondsEarned'] ?? 0.0).toDouble();
      }
      
      // Calculate commission (10% of diamonds)
      final commission = totalDiamonds * commissionRate;
      
      debugPrint('Host ${host.hostName} earned $totalDiamonds diamonds, commission: $commission');
      return commission;
    } catch (e) {
      debugPrint('Error calculating host commission: $e');
      return 0.0;
    }
  }

  /// Record commission payment for an agency
  static Future<void> _recordCommissionPayment(String agencyId, double amount) async {
    try {
      // Update agency total commission
      await _firestore.collection('agencies').doc(agencyId).update({
        'totalCommissionEarned': FieldValue.increment(amount),
        'updatedAt': Timestamp.now(),
      });
      
      // Record the payment
      await _firestore.collection('commission_payments').add({
        'agencyId': agencyId,
        'amount': amount,
        'paymentDate': Timestamp.now(),
        'weekStart': Timestamp.fromDate(_getWeekStart(DateTime.now())),
        'weekEnd': Timestamp.fromDate(_getWeekStart(DateTime.now()).add(const Duration(days: 7))),
        'status': 'completed',
        'createdAt': Timestamp.now(),
      });
      
      debugPrint('Recorded commission payment of $amount for agency $agencyId');
    } catch (e) {
      debugPrint('Error recording commission payment: $e');
      rethrow;
    }
  }

  /// Record individual host commission
  static Future<void> _recordHostCommission(HostModel host, DateTime weekStart, DateTime weekEnd, double commission) async {
    try {
      await _firestore.collection('host_commissions').add({
        'hostId': host.id,
        'agencyId': host.agencyId,
        'weekStart': Timestamp.fromDate(weekStart),
        'weekEnd': Timestamp.fromDate(weekEnd),
        'commissionAmount': commission,
        'commissionRate': commissionRate,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error recording host commission: $e');
    }
  }

  /// Record commission run details
  static Future<void> _recordCommissionRun(Map<String, dynamic> results) async {
    try {
      await _firestore.collection('commission_runs').add({
        'runDate': Timestamp.now(),
        'totalAgencies': results['totalAgencies'],
        'processedAgencies': results['processedAgencies'],
        'totalCommission': results['totalCommission'],
        'errors': results['errors'],
        'processedAgencyNames': results['processedAgencyNames'],
        'status': results['errors'].isEmpty ? 'success' : 'partial_success',
      });
    } catch (e) {
      debugPrint('Error recording commission run: $e');
    }
  }

  /// Get the start of the week (Sunday)
  static DateTime _getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  /// Check if it's time to process commissions
  static bool shouldProcessCommissions() {
    final now = DateTime.now();
    return now.weekday == commissionDay && now.hour == commissionHour;
  }

  /// Get commission history for an agency
  static Future<List<Map<String, dynamic>>> getAgencyCommissionHistory(String agencyId, {int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('commission_payments')
          .where('agencyId', isEqualTo: agencyId)
          .orderBy('paymentDate', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'amount': data['amount'],
          'paymentDate': (data['paymentDate'] as Timestamp).toDate(),
          'weekStart': (data['weekStart'] as Timestamp).toDate(),
          'weekEnd': (data['weekEnd'] as Timestamp).toDate(),
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting commission history: $e');
      return [];
    }
  }

  /// Get commission statistics
  static Future<Map<String, dynamic>> getCommissionStatistics() async {
    try {
      // Get total commission paid
      final totalQuery = await _firestore
          .collection('commission_payments')
          .get();
      
      double totalPaid = 0.0;
      for (final doc in totalQuery.docs) {
        totalPaid += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      
      // Get this month's commission
      final thisMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final thisMonthQuery = await _firestore
          .collection('commission_payments')
          .where('paymentDate', isGreaterThanOrEqualTo: thisMonth)
          .get();
      
      double thisMonthPaid = 0.0;
      for (final doc in thisMonthQuery.docs) {
        thisMonthPaid += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      
      // Get total agencies
      final agenciesQuery = await _firestore
          .collection('agencies')
          .where('isActive', isEqualTo: true)
          .get();
      
      return {
        'totalCommissionPaid': totalPaid,
        'thisMonthCommission': thisMonthPaid,
        'totalActiveAgencies': agenciesQuery.docs.length,
        'commissionRate': commissionRate,
      };
    } catch (e) {
      debugPrint('Error getting commission statistics: $e');
      return {};
    }
  }

  /// Manual commission calculation for a specific week
  static Future<Map<String, dynamic>> calculateCommissionForWeek(DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final results = {
        'weekStart': weekStart,
        'weekEnd': weekEnd,
        'totalCommission': 0.0,
        'agencyCommissions': <Map<String, dynamic>>[],
      };
      
      // Get all active agencies
      final agenciesQuery = await _firestore
          .collection('agencies')
          .where('isActive', isEqualTo: true)
          .get();
      
      for (final agencyDoc in agenciesQuery.docs) {
        final agency = AgencyModel.fromFirestore(agencyDoc);
        final hosts = await AgencyService.getAgencyHosts(agency.id);
        
        double agencyCommission = 0.0;
        final hostCommissions = <Map<String, dynamic>>[];
        
        for (final host in hosts) {
          if (!host.isActive) continue;
          
          // Get host earnings for the week
          final earningsQuery = await _firestore
              .collection('host_earnings')
              .where('hostId', isEqualTo: host.id)
              .where('earningDate', isGreaterThanOrEqualTo: weekStart)
              .where('earningDate', isLessThan: weekEnd)
              .get();
          
          double hostDiamonds = 0.0;
          for (final doc in earningsQuery.docs) {
            hostDiamonds += (doc.data()['diamondsEarned'] ?? 0.0).toDouble();
          }
          
          final hostCommission = hostDiamonds * commissionRate;
          agencyCommission += hostCommission;
          
          hostCommissions.add({
            'hostId': host.id,
            'hostName': host.hostName,
            'diamondsEarned': hostDiamonds,
            'commission': hostCommission,
          });
        }
        
      results['totalCommission'] = (results['totalCommission'] as double) + agencyCommission;
      (results['agencyCommissions'] as List<Map<String, dynamic>>).add({
          'agencyId': agency.id,
          'agencyName': agency.agencyName,
          'totalCommission': agencyCommission,
          'hostCommissions': hostCommissions,
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('Error calculating commission for week: $e');
      return {};
    }
  }
}
