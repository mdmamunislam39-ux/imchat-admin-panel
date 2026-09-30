import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/agency_model.dart';
import '../models/host_model.dart';
import '../models/agency_notification_model.dart';
import '../services/agency_service.dart';
import 'agency_profile_screen.dart';
import 'agency_hosts_screen.dart';
import 'agency_income_screen.dart';
import 'agency_reports_screen.dart';
import '../widgets/media_preview_widget.dart';

class AgencyDashboard extends StatefulWidget {
  final String agencyId;

  const AgencyDashboard({super.key, required this.agencyId});

  @override
  State<AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<AgencyDashboard> {
  AgencyModel? _agency;
  List<HostModel> _hosts = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  StreamSubscription<DocumentSnapshot>? _agencySub;
  StreamSubscription<QuerySnapshot>? _hostsSub;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _agencySub?.cancel();
    _hostsSub?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Cancel any existing subscriptions before creating new ones
    _agencySub?.cancel();
    _hostsSub?.cancel();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    // ── Agency real-time listener ────────────────────────────────────────
    _agencySub = FirebaseFirestore.instance
        .collection('agencies')
        .doc(widget.agencyId)
        .snapshots()
        .listen(
          (agencyDoc) {
            if (!mounted) return;
            if (agencyDoc.exists) {
              setState(() {
                _agency = AgencyModel.fromFirestore(agencyDoc);
                _recalculateAnalytics();
                // Always stop loading once agency data arrives,
                // even if hosts stream is slow or fails.
                _isLoading = false;
              });
            } else {
              setState(() => _isLoading = false);
            }
          },
          onError: (e) {
            debugPrint('Error listening to agency: $e');
            if (mounted) setState(() => _isLoading = false);
          },
        );

    // ── Hosts real-time listener ─────────────────────────────────────────
    _hostsSub = FirebaseFirestore.instance
        .collection('hosts')
        .where('agencyId', isEqualTo: widget.agencyId)
        .snapshots()
        .listen(
      (hostsQuery) {
        if (!mounted) return;
        final List<HostModel> uniqueHosts = [];
        final Set<String> seenUserIds = {};
        for (var doc in hostsQuery.docs) {
          try {
            final host = HostModel.fromFirestore(doc);
            if (host.isActive && !seenUserIds.contains(host.userId)) {
              seenUserIds.add(host.userId);
              uniqueHosts.add(host);
            }
          } catch (e) {
            debugPrint('Error parsing host ${doc.id}: $e');
          }
        }
        setState(() {
          _hosts = uniqueHosts;
          _recalculateAnalytics();
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to hosts: $e');
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }


  void _recalculateAnalytics() {
    double totalDiamonds = 0.0;
    int totalLiveHours = 0;
    int totalGifts = 0;
    double totalCommission = 0.0;

    for (final host in _hosts) {
      totalDiamonds += host.performance.totalDiamonds;
      totalLiveHours += host.performance.totalLiveHours;
      totalGifts += host.performance.totalGiftsReceived;
    }

    // Use agency's actual commission rate (default 10%)
    final rate = _agency?.commissionRate ?? 0.10;
    totalCommission = totalDiamonds * rate;

    _analytics = {
      'totalHosts': _hosts.length,
      'activeHosts': _hosts.where((h) => h.isActive).length,
      'totalDiamonds': totalDiamonds,
      'totalLiveHours': totalLiveHours,
      'totalGifts': totalGifts,
      'totalCommission': totalCommission,
      'commissionRate': rate,
      'isCommissionHeld': _agency?.isCommissionHeld ?? false,
      'averageHostRating': _hosts.isNotEmpty
          ? _hosts
                    .map((h) => h.performance.averageRating)
                    .fold(0.0, (a, b) => a + b) /
                _hosts.length
          : 0.0,
    };
  }

  Future<void> _loadAgencyData() async {
    // Left for refresh button compatibility or manual trigger
    _setupRealtimeListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _agency?.agencyName ?? 'Agency Dashboard',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAgencyData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _buildDashboard(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  _agency?.agencyName ?? 'Agency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ID: ${_agency?.agencyIdNumber ?? ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.business,
            title: 'Agency Profile',
            onTap: () {
              Navigator.pop(context);
              _navigateToAgencyProfile();
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Hosts Management',
            onTap: () {
              Navigator.pop(context);
              _navigateToHosts();
            },
          ),
          _buildDrawerItem(
            icon: Icons.monetization_on,
            title: 'Income & Payments',
            onTap: () {
              Navigator.pop(context);
              _navigateToIncome();
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Reports & Analytics',
            onTap: () {
              Navigator.pop(context);
              _navigateToReports();
            },
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            icon: Icons.add,
            title: 'Add New Host',
            onTap: () {
              Navigator.pop(context);
              _showAddHostDialog();
            },
          ),
          _buildDrawerItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              _showNotifications();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.grey[900],
        onTap: onTap,
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agency Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[900]!, Colors.purple[900]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agency?.agencyName ?? 'Agency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${_agency?.agencyIdNumber ?? ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Agency Status + Commission Rate + Hold status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _agency?.isActive == true
                                      ? Icons.circle
                                      : Icons.circle_outlined,
                                  color: _agency?.isActive == true
                                      ? Colors.green
                                      : Colors.red,
                                  size: 10,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _agency?.isActive == true
                                      ? 'Active'
                                      : 'Inactive',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Commission rate badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.percent,
                                  color: Colors.purple,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${((_agency?.commissionRate ?? 0.10) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_agency?.isCommissionHeld == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pause_circle,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Held',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.business, color: Colors.white, size: 64),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Cards
          const Text(
            'Agency Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Hosts',
                  value: '${_analytics['totalHosts'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Hosts',
                  value: '${_analytics['activeHosts'] ?? 0}',
                  icon: Icons.person,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Diamonds',
                  value:
                      '${(_analytics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}',
                  icon: Icons.diamond,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Commission',
                  value:
                      '${(_analytics['totalCommission'] ?? 0.0).toStringAsFixed(2)}',
                  icon: Icons.monetization_on,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Commission Rate & Hold Status Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Commission Rate',
                  value:
                      '${((_analytics['commissionRate'] ?? 0.10) * 100).toStringAsFixed(1)}%',
                  icon: Icons.percent,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Commission Status',
                  value: (_analytics['isCommissionHeld'] == true)
                      ? 'HELD'
                      : 'ACTIVE',
                  icon: (_analytics['isCommissionHeld'] == true)
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: (_analytics['isCommissionHeld'] == true)
                      ? Colors.orange
                      : Colors.teal,
                ),
              ),
            ],
          ),

          // Commission Hold Warning Banner
          if (_analytics['isCommissionHeld'] == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Commission payouts are currently HELD by admin. Agency will not receive commission until resumed.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Hosts',
                  subtitle: 'View and manage hosts',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: _navigateToHosts,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Income Report',
                  subtitle: 'View earnings and payments',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                  onTap: _navigateToIncome,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Add Host',
                  subtitle: 'Invite new host',
                  icon: Icons.person_add,
                  color: Colors.purple,
                  onTap: _showAddHostDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Analytics',
                  subtitle: 'View detailed reports',
                  icon: Icons.analytics,
                  color: Colors.orange,
                  onTap: _navigateToReports,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Hosts
          const Text(
            'Recent Hosts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentHostsCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Icon(icon, color: color, size: 32)],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHostsCard() {
    final recentHosts = _hosts.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          if (recentHosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No hosts found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else
            ...recentHosts.asMap().entries.map((entry) {
              final index = entry.key;
              final host = entry.value;
              return Column(
                children: [
                  _buildHostItem(host),
                  if (index < recentHosts.length - 1)
                    const Divider(color: Colors.grey, height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHostItem(HostModel host) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(host.userId)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = host.hostName;
        String? photoUrl;
        String searchId = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final ud = snapshot.data!.data() as Map<String, dynamic>;
          displayName = ud['fullname'] ?? ud['username'] ?? displayName;
          photoUrl = ud['photoUrl'] ?? ud['profileImageUrl'];
          searchId = ud['searchId']?.toString() ?? '';
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              photoUrl != null && photoUrl.isNotEmpty
                  ? MediaPreviewWidget(
                      url: photoUrl,
                      width: 40,
                      height: 40,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (searchId.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'ID: $searchId',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${host.status.name}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: host.isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  host.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: host.isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAgencyProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgencyProfileScreen(agencyId: widget.agencyId),
      ),
    );
  }

  void _navigateToHosts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgencyHostsScreen(agencyId: widget.agencyId),
      ),
    );
  }

  void _navigateToIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgencyIncomeScreen(agencyId: widget.agencyId),
      ),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgencyReportsScreen(agencyId: widget.agencyId),
      ),
    );
  }

  void _showAddHostDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddHostDialog(agencyId: widget.agencyId),
    );
  }

  void _showNotifications() {
    // TODO: Implement notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class _AddHostDialog extends StatefulWidget {
  final String agencyId;

  const _AddHostDialog({required this.agencyId});

  @override
  State<_AddHostDialog> createState() => _AddHostDialogState();
}

class _AddHostDialogState extends State<_AddHostDialog> {
  final _profileIdController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;

  Map<String, dynamic>? _foundUser;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _profileIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    try {
      setState(() => _isSearching = true);
      final results = await AgencyService.searchUser(_profileIdController.text);
      setState(() {
        _allUsers = results;
        _filteredUsers = _allUsers;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() => _isSearching = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        return user['profileId'].toLowerCase().contains(query.toLowerCase()) ||
            user['name'].toLowerCase().contains(query.toLowerCase()) ||
            user['phone'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _selectUser(Map<String, dynamic> user) {
    final isAlreadyHost =
        user['userType'] == 'host' ||
        (user['agencyId'] != null && user['agencyId'].toString().isNotEmpty);
    if (isAlreadyHost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user['name']} is already a Host of another agency. They must leave their agency first.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _foundUser = user;
      _profileIdController.text = user['profileId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text('Invite Host', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search User by Profile ID',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _profileIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter Profile ID...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  suffixIcon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: Colors.blue),
                          onPressed: _loadAllUsers,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                onChanged: _filterUsers,
              ),

              const SizedBox(height: 16),

              if (_filteredUsers.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _foundUser?['id'] == user['id'];
                      final isAlreadyHost =
                          user['userType'] == 'host' ||
                          (user['agencyId'] != null &&
                              user['agencyId'].toString().isNotEmpty);

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              (user['name'] as String).isNotEmpty
                                  ? user['name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAlreadyHost) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.red,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Text(
                                    'Already Host',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            'ID: ${user['profileId']}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: isAlreadyHost
                              ? const Icon(
                                  Icons.block,
                                  color: Colors.red,
                                  size: 20,
                                )
                              : (isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.radio_button_unchecked,
                                        color: Colors.grey,
                                        size: 20,
                                      )),
                          onTap: () => _selectUser(user),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              if (_foundUser != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 16,
                        child: Text(
                          _foundUser!['name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _foundUser!['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Profile ID: ${_foundUser!['profileId']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            _foundUser = null;
                            _profileIdController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Invitation Message (Optional)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendInvitation,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Send Invitation'),
        ),
      ],
    );
  }

  Future<void> _sendInvitation() async {
    if (_foundUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final invitation = HostInvitationModel(
        id: '',
        agencyId: widget.agencyId,
        hostUserId: _foundUser!['id'],
        hostName: _foundUser!['name'],
        hostEmail: _foundUser!['email'] ?? '',
        hostPhone: _foundUser!['phone'],
        sentAt: DateTime.now(),
        message: _messageController.text.trim(),
      );

      await AgencyService.sendHostInvitation(invitation);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
