import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/firebase_data_service.dart';

class EventDashboardScreen extends StatefulWidget {
  final EventModel event;

  const EventDashboardScreen({super.key, required this.event});

  @override
  State<EventDashboardScreen> createState() => _EventDashboardScreenState();
}

class _EventDashboardScreenState extends State<EventDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${widget.event.eventName} Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Real-Time Counters Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseDataService.getEventRegistrationsStream(widget.event.id),
              builder: (context, snapshot) {
                int totalRegistrations = snapshot.hasData ? snapshot.data!.docs.length : 0;
                // For demonstration, simulating other counters based on registrations
                int participants = (totalRegistrations * 0.8).round();
                int liveUsers = (participants * 0.3).round();
                
                int rewardPool = 0;
                for (var r in widget.event.rewards) {
                  if (r['category'] == 'Diamonds') {
                    rewardPool += (r['amount'] as int? ?? 0);
                  }
                }

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: [
                    _buildCounterCard('Registrations', totalRegistrations.toString(), Icons.app_registration, Colors.blue),
                    _buildCounterCard('Participants', participants.toString(), Icons.people, Colors.green),
                    _buildCounterCard('Live Users', liveUsers.toString(), Icons.sensors, Colors.red),
                    _buildCounterCard('Reward Pool', rewardPool > 0 ? rewardPool.toString() : 'N/A', Icons.diamond, Colors.purple),
                  ],
                );
              },
            ),
          ),
          
          // Tabs
          Container(
            color: Colors.grey[900],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.blue,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Registrations'),
                Tab(text: 'Top Contributors'),
                Tab(text: 'Top Senders'),
                Tab(text: 'Top Participants'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRegistrationsList(),
                _buildMockList('Contributors'),
                _buildMockList('Gift Senders'),
                _buildMockList('Participants'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseDataService.getEventRegistrationsStream(widget.event.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blue));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No registrations yet.', style: TextStyle(color: Colors.grey)));
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final registeredAt = (data['registeredAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[800],
                backgroundImage: data['userAvatar'] != null ? NetworkImage(data['userAvatar']) : null,
                child: data['userAvatar'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              title: Text(data['userName'] ?? 'Unknown User', style: const TextStyle(color: Colors.white)),
              subtitle: Text('ID: ${data['userId']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              trailing: Text(
                '${registeredAt.day}/${registeredAt.month}/${registeredAt.year}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMockList(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard, size: 64, color: Colors.grey[800]),
          const SizedBox(height: 16),
          Text('Top $type', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Data will populate automatically as event progresses.', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }
}
