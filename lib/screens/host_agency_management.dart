import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';
import '../widgets/media_preview_widget.dart';

class HostAgencyManagement extends StatefulWidget {
  const HostAgencyManagement({super.key});

  @override
  State<HostAgencyManagement> createState() => _HostAgencyManagementState();
}

class _HostAgencyManagementState extends State<HostAgencyManagement>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<UserProfileModel> _hosts = [];
  List<UserProfileModel> _regularUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showAgencyFilter = false;
  String? _selectedAgencyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final allUsers = await UserProfileService.getAllUserProfiles();
      await UserProfileService.getUserStatistics();

      if (mounted) {
        setState(() {
          _hosts = allUsers.where((user) => user.isHost).toList();
          _regularUsers = allUsers
              .where((user) => user.userType == UserType.regular)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading host/agency data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load host/agency data');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _searchUsers(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleAgencyFilter() {
    setState(() {
      _showAgencyFilter = !_showAgencyFilter;
    });
  }

  List<UserProfileModel> get _filteredHosts {
    var filtered = _hosts;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (host) => host.username.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    if (_selectedAgencyId != null) {
      filtered = filtered
          .where((host) => host.agencyId == _selectedAgencyId)
          .toList();
    }

    return filtered;
  }

  List<UserProfileModel> get _filteredRegularUsers {
    var filtered = _regularUsers;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (user) => user.username.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  Set<String> get _uniqueAgencies {
    return _hosts
        .where((host) => host.agencyId != null && host.agencyName != null)
        .map((host) => host.agencyId!)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '🎤 Host & Agency Management',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildHostsTab(),
                      _buildRegularUsersTab(),
                      _buildAgencyTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        indicatorColor: Colors.purple,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.mic), text: 'Hosts'),
          Tab(icon: Icon(Icons.people), text: 'Users'),
          Tab(icon: Icon(Icons.business), text: 'Agencies'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActionsMenu,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.flash_on),
        label: const Text('Quick Actions'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    onChanged: _searchUsers,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '🔍 Search hosts and users...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showAgencyFilter ? Icons.filter_list_off : Icons.filter_list,
                  color: _showAgencyFilter ? Colors.purple : Colors.grey,
                ),
                onPressed: _toggleAgencyFilter,
                tooltip: 'Agency Filter',
              ),
            ],
          ),

          // Agency Filter
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showAgencyFilter ? 50 : 0,
            child: _showAgencyFilter
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildAgencyFilterChip('All Agencies', null),
                          const SizedBox(width: 8),
                          ..._uniqueAgencies.map((agencyId) {
                            final agencyName = _hosts
                                .firstWhere((host) => host.agencyId == agencyId)
                                .agencyName!;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildAgencyFilterChip(
                                agencyName,
                                agencyId,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyFilterChip(String label, String? agencyId) {
    final isSelected = _selectedAgencyId == agencyId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedAgencyId = selected ? agencyId : null;
        });
      },
      selectedColor: Colors.purple.withValues(alpha: 0.3),
      checkmarkColor: Colors.purple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'Host & Agency Statistics',
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
                  value: _hosts.length.toString(),
                  icon: Icons.mic,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Regular Users',
                  value: _regularUsers.length.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Active Hosts',
                  value: _hosts
                      .where((h) => h.status == UserStatus.active)
                      .length
                      .toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Unique Agencies',
                  value: _uniqueAgencies.length.toString(),
                  icon: Icons.business,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Host vs Regular User Distribution
          const Text(
            'User Type Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildUserTypeDistributionChart(),

          const SizedBox(height: 24),

          // Agency Performance
          const Text(
            'Agency Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildAgencyPerformanceCard(),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Promote to Host',
                  subtitle: 'Convert regular user to host',
                  icon: Icons.mic,
                  color: Colors.purple,
                  onTap: _showPromoteToHostDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Assign to Agency',
                  subtitle: 'Assign host to agency',
                  icon: Icons.business,
                  color: Colors.orange,
                  onTap: _showAssignAgencyDialog,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'View Host Details',
                  subtitle: 'Check host performance',
                  icon: Icons.analytics,
                  color: Colors.blue,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Agency Management',
                  subtitle: 'Manage agencies',
                  icon: Icons.settings,
                  color: Colors.green,
                  onTap: () => _tabController.animateTo(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostsTab() {
    final filteredHosts = _filteredHosts;

    return filteredHosts.isEmpty
        ? const Center(
            child: Text(
              'No hosts found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredHosts.length,
            itemBuilder: (context, index) {
              final host = filteredHosts[index];
              return _buildHostCard(host);
            },
          );
  }

  Widget _buildRegularUsersTab() {
    final filteredUsers = _filteredRegularUsers;

    return filteredUsers.isEmpty
        ? const Center(
            child: Text(
              'No regular users found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildRegularUserCard(user);
            },
          );
  }

  Widget _buildAgencyTab() {
    final agencies = _getAgencyList();

    return agencies.isEmpty
        ? const Center(
            child: Text(
              'No agencies found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: agencies.length,
            itemBuilder: (context, index) {
              final agency = agencies[index];
              return _buildAgencyCard(agency);
            },
          );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeDistributionChart() {
    final totalUsers = _hosts.length + _regularUsers.length;
    final hostPercentage = totalUsers > 0
        ? ((_hosts.length / totalUsers) * 100).toDouble()
        : 0.0;
    final userPercentage = totalUsers > 0
        ? ((_regularUsers.length / totalUsers) * 100).toDouble()
        : 0.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDistributionItem(
                'Hosts',
                _hosts.length,
                Colors.purple,
                hostPercentage,
              ),
              _buildDistributionItem(
                'Regular Users',
                _regularUsers.length,
                Colors.blue,
                userPercentage,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: _hosts.length,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                flex: _regularUsers.length,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(
    String label,
    int count,
    Color color,
    double percentage,
  ) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAgencyPerformanceCard() {
    final agencies = _getAgencyList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        children: [
          if (agencies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No agencies found',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          else
            ...agencies.take(5).map((agency) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agency['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${agency['hostCount']} hosts',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${agency['activeHosts']} active',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHostCard(UserProfileModel host) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: host.status == UserStatus.active ? Colors.purple : Colors.red,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.purple.withValues(alpha: 0.2),
                  child: host.profileImageUrl != null
                      ? MediaPreviewWidget(
                          url: host.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : const Icon(Icons.mic, color: Colors.purple, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        host.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'HOST',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (host.agencyName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                host.agencyName!,
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: host.status == UserStatus.active
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    host.status == UserStatus.active ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Host Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diamonds',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${host.totalDiamonds.toStringAsFixed(0)}💎',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Sending Level',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        'Level ${host.sendingLevel.level}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Receiving Level',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        'Level ${host.receivingLevel.level}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showHostDetailsDialog(host),
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditHostDialog(host),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAgencyManagementDialog(host),
                    icon: const Icon(Icons.business),
                    label: const Text('Agency'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularUserCard(UserProfileModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.status == UserStatus.active ? Colors.blue : Colors.red,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: user.profileImageUrl != null
                      ? MediaPreviewWidget(
                          url: user.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : const Icon(Icons.person, color: Colors.blue, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'REGULAR USER',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: user.status == UserStatus.active
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.status == UserStatus.active ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diamonds',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${user.totalDiamonds.toStringAsFixed(0)}💎',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Beans',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        '${user.totalBeans.toStringAsFixed(0)}🫘',
                        style: const TextStyle(
                          color: Colors.brown,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Levels',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        'S:${user.sendingLevel.level} R:${user.receivingLevel.level}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUserDetailsDialog(user),
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPromoteToHostDialog(user),
                    icon: const Icon(Icons.mic),
                    label: const Text('Promote'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditUserDialog(user),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgencyCard(Map<String, dynamic> agency) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agency['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${agency['hostCount']} hosts • ${agency['activeHosts']} active',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'AGENCY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Agency Hosts
            if (agency['hosts'].isNotEmpty) ...[
              const Text(
                'Hosts:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (agency['hosts'] as List<UserProfileModel>).map((
                  host,
                ) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      host.username,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAgencyDetailsDialog(agency),
                    icon: const Icon(Icons.info),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditAgencyDialog(agency),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showManageAgencyHostsDialog(agency),
                    icon: const Icon(Icons.people),
                    label: const Text('Manage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAgencyList() {
    final agencyMap = <String, Map<String, dynamic>>{};

    for (final host in _hosts) {
      if (host.agencyId != null && host.agencyName != null) {
        if (!agencyMap.containsKey(host.agencyId)) {
          agencyMap[host.agencyId!] = {
            'id': host.agencyId,
            'name': host.agencyName,
            'hosts': <UserProfileModel>[],
            'hostCount': 0,
            'activeHosts': 0,
          };
        }

        agencyMap[host.agencyId!]!['hosts'].add(host);
        agencyMap[host.agencyId!]!['hostCount']++;

        if (host.status == UserStatus.active) {
          agencyMap[host.agencyId!]!['activeHosts']++;
        }
      }
    }

    return agencyMap.values.toList();
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              '🚀 Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActionTile(
              icon: Icons.mic,
              title: 'Promote to Host',
              subtitle: 'Convert regular user to host',
              onTap: () {
                Navigator.pop(context);
                _showPromoteToHostDialog();
              },
            ),
            _buildQuickActionTile(
              icon: Icons.business,
              title: 'Create Agency',
              subtitle: 'Create new agency',
              onTap: () {
                Navigator.pop(context);
                _showCreateAgencyDialog();
              },
            ),
            _buildQuickActionTile(
              icon: Icons.analytics,
              title: 'View Analytics',
              subtitle: 'Check host performance',
              onTap: () {
                Navigator.pop(context);
                _showHostAnalytics();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.purple),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  // Dialog Methods
  void _showPromoteToHostDialog([UserProfileModel? user]) {
    // TODO: Implement promote to host dialog
    _showSuccessSnackBar('Promote to host dialog coming soon');
  }

  void _showAssignAgencyDialog() {
    // TODO: Implement assign agency dialog
    _showSuccessSnackBar('Assign agency dialog coming soon');
  }

  void _showHostDetailsDialog(UserProfileModel host) {
    // TODO: Implement host details dialog
    _showSuccessSnackBar('Host details dialog coming soon');
  }

  void _showEditHostDialog(UserProfileModel host) {
    // TODO: Implement edit host dialog
    _showSuccessSnackBar('Edit host dialog coming soon');
  }

  void _showAgencyManagementDialog(UserProfileModel host) {
    // TODO: Implement agency management dialog
    _showSuccessSnackBar('Agency management dialog coming soon');
  }

  void _showUserDetailsDialog(UserProfileModel user) {
    // TODO: Implement user details dialog
    _showSuccessSnackBar('User details dialog coming soon');
  }

  void _showEditUserDialog(UserProfileModel user) {
    // TODO: Implement edit user dialog
    _showSuccessSnackBar('Edit user dialog coming soon');
  }

  void _showAgencyDetailsDialog(Map<String, dynamic> agency) {
    // TODO: Implement agency details dialog
    _showSuccessSnackBar('Agency details dialog coming soon');
  }

  void _showEditAgencyDialog(Map<String, dynamic> agency) {
    // TODO: Implement edit agency dialog
    _showSuccessSnackBar('Edit agency dialog coming soon');
  }

  void _showManageAgencyHostsDialog(Map<String, dynamic> agency) {
    // TODO: Implement manage agency hosts dialog
    _showSuccessSnackBar('Manage agency hosts dialog coming soon');
  }

  void _showCreateAgencyDialog() {
    // TODO: Implement create agency dialog
    _showSuccessSnackBar('Create agency dialog coming soon');
  }

  void _showHostAnalytics() {
    // TODO: Implement host analytics
    _showSuccessSnackBar('Host analytics coming soon');
  }
}
