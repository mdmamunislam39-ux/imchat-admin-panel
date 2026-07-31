import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiftHistoryScreen extends StatefulWidget {
  const GiftHistoryScreen({super.key});

  @override
  State<GiftHistoryScreen> createState() => _GiftHistoryScreenState();
}

class _GiftHistoryScreenState extends State<GiftHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Gift History'),
          bottom: const TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Total'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user_received_gifts').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading gift history.', style: TextStyle(color: Colors.red)));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.blue));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No gift history found.', style: TextStyle(color: Colors.white70)));
            }

            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
            final startOfMonth = DateTime(now.year, now.month, 1);

            final Map<String, Map<String, dynamic>> stats = {};

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final String giftId = data['giftId']?.toString() ?? 'N/A';
              final String giftName = data['giftName'] ?? 'Unknown';
              final double diamondAmount = (data['credits'] ?? 0.0).toDouble();

              DateTime createdAt;
              if (data['timestamp'] is Timestamp) {
                createdAt = (data['timestamp'] as Timestamp).toDate();
              } else {
                continue;
              }

              if (!stats.containsKey(giftName)) {
                stats[giftName] = {
                  'giftId': giftId,
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

              if (createdAt.isAfter(startOfDay) || createdAt.isAtSameMomentAs(startOfDay)) {
                stat['dailyCount'] += 1;
              }
              if (createdAt.isAfter(startOfWeek) || createdAt.isAtSameMomentAs(startOfWeek)) {
                stat['weeklyCount'] += 1;
              }
              if (createdAt.isAfter(startOfMonth) || createdAt.isAtSameMomentAs(startOfMonth)) {
                stat['monthlyCount'] += 1;
              }
            }

            final allStats = stats.values.toList();

            return TabBarView(
              children: [
                _buildList(allStats, 'dailyCount'),
                _buildList(allStats, 'weeklyCount'),
                _buildList(allStats, 'monthlyCount'),
                _buildList(allStats, 'totalCount'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> allStats, String countKey) {
    // Filter out gifts that have 0 count for this specific period
    final filteredStats = allStats.where((stat) => (stat[countKey] as int) > 0).toList();
    // Sort descending by count
    filteredStats.sort((a, b) => (b[countKey] as int).compareTo(a[countKey] as int));

    if (filteredStats.isEmpty) {
      return const Center(child: Text('No history for this period.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredStats.length,
      itemBuilder: (context, index) {
        final stat = filteredStats[index];
        final count = stat[countKey] as int;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF16162A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(stat['giftName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ID: ${stat['giftId']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Price: ${stat['diamondAmount']} 💎', style: const TextStyle(color: Colors.amber)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sent', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('$count times', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }
}
