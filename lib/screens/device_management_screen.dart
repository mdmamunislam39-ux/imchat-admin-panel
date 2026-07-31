import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_session_model.dart';
import 'package:intl/intl.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchUserId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Device Session Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBox(),
            const SizedBox(height: 20),
            Expanded(
              child: _searchUserId.isEmpty 
                  ? const Center(child: Text('Enter User ID to view sessions', style: TextStyle(color: Colors.grey)))
                  : _buildSessionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by User ID',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search, color: Colors.blue),
          onPressed: () {
            setState(() {
              _searchUserId = _searchController.text.trim();
            });
          },
        ),
      ),
      onSubmitted: (value) {
        setState(() {
          _searchUserId = value.trim();
        });
      },
    );
  }

  Widget _buildSessionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('device_sessions')
          .where('userId', isEqualTo: _searchUserId)
          .orderBy('loginTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No device sessions found for this user.', style: TextStyle(color: Colors.grey)));
        }

        final sessions = snapshot.data!.docs.map((d) => DeviceSessionModel.fromFirestore(d)).toList();
        final activeCount = sessions.where((s) => s.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Total Logged-in Devices: $activeCount',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _buildSessionCard(session);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(DeviceSessionModel session) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  session.deviceType.toLowerCase() == 'web' ? Icons.computer : Icons.phone_android,
                  color: session.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    session.deviceName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (session.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 12)),
                  )
                else
                  const Text('Inactive', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Device Type: ${session.deviceType}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text('Login Time: ${DateFormat('MMM d, yyyy h:mm a').format(session.loginTime)}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text('Last Active: ${DateFormat('MMM d, yyyy h:mm a').format(session.lastActiveTime)}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            if (session.isActive) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _forceLogout(session),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Force Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _forceLogout(DeviceSessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Force Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out this device remotely?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Force Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('device_sessions').doc(session.deviceId).update({'isActive': false});
      
      // Log admin action
      FirebaseFirestore.instance.collection('security_logs').add({
        'userId': session.userId,
        'action': 'ADMIN_FORCE_LOGOUT',
        'targetDeviceId': session.deviceId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device logged out successfully', style: TextStyle(color: Colors.white))));
    }
  }
}
