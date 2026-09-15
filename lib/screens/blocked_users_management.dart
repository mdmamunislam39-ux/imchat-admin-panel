import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';
import '../widgets/media_preview_widget.dart';

class BlockedUsersManagement extends StatefulWidget {
  const BlockedUsersManagement({super.key});

  @override
  State<BlockedUsersManagement> createState() => _BlockedUsersManagementState();
}

class _BlockedUsersManagementState extends State<BlockedUsersManagement> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  List<UserProfileModel> _allUsers = [];
  List<UserProfileModel> _blockedUsers = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
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

      debugPrint('Loading user data...');
      final allUsers = await UserProfileService.getAllUserProfiles();
      debugPrint('Loaded ${allUsers.length} users');
      
      final stats = await UserProfileService.getUserStatistics();

      if (mounted) {
        setState(() {
          _allUsers = allUsers;
          _blockedUsers = allUsers.where((user) => user.blockedUserIds.isNotEmpty).toList();
          _statistics = stats;
          _isLoading = false;
        });
        
        if (allUsers.isEmpty) {
          _showErrorSnackBar('No users found. Demo users will be created automatically.');
        } else {
          _showSuccessSnackBar('Loaded ${allUsers.length} users successfully');
        }
      }
    } catch (e) {
      debugPrint('Error loading blocked users data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load blocked users data: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
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

  List<UserProfileModel> get _filteredUsers {
    var filtered = _allUsers;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) =>
          user.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '🚫 Blocked Users Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildBlockedUsersTab(),
                      _buildPunishmentsTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        indicatorColor: Colors.red,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.block), text: 'Blocked Users'),
          Tab(icon: Icon(Icons.gavel), text: 'Punishments'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBlockUserDialog,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.block),
        label: const Text('Block User'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          onChanged: _searchUsers,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '🔍 Search users...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
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
            'Blocked Users Statistics',
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
                  title: 'Total Users',
                  value: _statistics['totalUsers']?.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Blocked Users',
                  value: _statistics['blockedUsers']?.toString() ?? '0',
                  icon: Icons.block,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Active Users',
                  value: _statistics['activeUsers']?.toString() ?? '0',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Suspended Users',
                  value: _allUsers.where((u) => u.isSuspended).length.toString(),
                  icon: Icons.pause_circle,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Punishments
          const Text(
            'Recent Punishments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildRecentPunishmentsCard(),

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
                  title: 'Block User',
                  subtitle: 'Block a user account',
                  icon: Icons.block,
                  color: Colors.red,
                  onTap: _showBlockUserDialog,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Issue Warning',
                  subtitle: 'Issue a warning to user',
                  icon: Icons.warning,
                  color: Colors.orange,
                  onTap: () => _showPunishmentDialog(PunishmentType.warning),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Suspend User',
                  subtitle: 'Temporarily suspend user',
                  icon: Icons.pause_circle,
                  color: Colors.orange,
                  onTap: () => _showPunishmentDialog(PunishmentType.suspension),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'View All Punishments',
                  subtitle: 'Manage all punishments',
                  icon: Icons.gavel,
                  color: Colors.purple,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersTab() {
    return _blockedUsers.isEmpty
        ? const Center(
            child: Text(
              'No blocked users found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _blockedUsers.length,
            itemBuilder: (context, index) {
              final user = _blockedUsers[index];
              return _buildBlockedUserCard(user);
            },
          );
  }

  Widget _buildPunishmentsTab() {
    final usersWithPunishments = _allUsers.where((user) => user.punishments.isNotEmpty).toList();
    
    return usersWithPunishments.isEmpty
        ? const Center(
            child: Text(
              'No punishments found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: usersWithPunishments.length,
            itemBuilder: (context, index) {
              final user = usersWithPunishments[index];
              return _buildPunishmentCard(user);
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
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPunishmentsCard() {
    final recentPunishments = <UserPunishment>[];
    
    for (final user in _allUsers) {
      for (final punishment in user.punishments) {
        if (punishment.isActive && !punishment.isExpired) {
          recentPunishments.add(punishment);
        }
      }
    }
    
    recentPunishments.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    final topPunishments = recentPunishments.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          if (topPunishments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No recent punishments',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          else
            ...topPunishments.map((punishment) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPunishmentTypeColor(punishment.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPunishmentTypeIcon(punishment.type),
                        color: _getPunishmentTypeColor(punishment.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPunishmentTypeDisplayName(punishment.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            punishment.reason,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(punishment.issuedAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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

  Widget _buildBlockedUserCard(UserProfileModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
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
                  backgroundColor: Colors.red.withValues(alpha: 0.2),
                  child: user.profileImageUrl != null
                      ? MediaPreviewWidget(
                          url: user.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : const Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 30,
                        ),
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
                      Text(
                        _getUserTypeDisplayName(user.userType),
                        style: TextStyle(
                          color: _getUserTypeColor(user.userType),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.isHost && user.agencyName != null)
                        Text(
                          'Agency: ${user.agencyName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'BLOCKED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            if (user.punishments.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Punishments:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...user.punishments.map((punishment) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getPunishmentTypeColor(punishment.type).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getPunishmentTypeIcon(punishment.type),
                          color: _getPunishmentTypeColor(punishment.type),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPunishmentTypeDisplayName(punishment.type),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              punishment.reason,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDate(punishment.issuedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
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
                    onPressed: () => _showUnblockUserDialog(user),
                    icon: const Icon(Icons.check),
                    label: const Text('Unblock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddPunishmentDialog(user),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Punishment'),
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

  Widget _buildPunishmentCard(UserProfileModel user) {
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
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: user.profileImageUrl != null
                      ? MediaPreviewWidget(
                          url: user.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.orange,
                          size: 30,
                        ),
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
                      Text(
                        '${user.punishments.length} punishment${user.punishments.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getUserStatusColor(user.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getUserStatusDisplayName(user.status),
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
            
            // Punishments List
            ...user.punishments.map((punishment) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getPunishmentTypeColor(punishment.type),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getPunishmentTypeColor(punishment.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getPunishmentTypeIcon(punishment.type),
                        color: _getPunishmentTypeColor(punishment.type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPunishmentTypeDisplayName(punishment.type),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            punishment.reason,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Issued by: ${punishment.issuedBy}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(punishment.issuedAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        if (punishment.expiresAt != null)
                          Text(
                            'Expires: ${_formatDate(punishment.expiresAt!)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: punishment.isActive 
                                ? (punishment.isExpired ? Colors.red : Colors.green)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            punishment.isActive 
                                ? (punishment.isExpired ? 'Expired' : 'Active')
                                : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getUserTypeDisplayName(UserType type) {
    switch (type) {
      case UserType.regular:
        return 'Regular User';
      case UserType.host:
        return 'Host';
      case UserType.seller:
        return 'Seller';
      case UserType.admin:
        return 'Admin';
      case UserType.agency:
        return 'Agency';
      case UserType.agency_owner:
        return 'Agency Owner';
    }
  }

  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.regular:
        return Colors.blue;
      case UserType.host:
        return Colors.purple;
      case UserType.seller:
        return Colors.orange;
      case UserType.admin:
        return Colors.red;
      case UserType.agency:
        return Colors.teal;
      case UserType.agency_owner:
        return Colors.cyan;
    }
  }

  Color _getUserStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.blocked:
        return Colors.red;
      case UserStatus.suspended:
        return Colors.orange;
      case UserStatus.pending:
        return Colors.yellow;
    }
  }

  String _getUserStatusDisplayName(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.blocked:
        return 'Blocked';
      case UserStatus.suspended:
        return 'Suspended';
      case UserStatus.pending:
        return 'Pending';
    }
  }

  Color _getPunishmentTypeColor(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return Colors.purpleAccent;
      case PunishmentType.postBan:
        return Colors.orangeAccent;
      case PunishmentType.accountBan:
        return Colors.redAccent;
      case PunishmentType.deviceBan:
        return Colors.deepOrange;
      case PunishmentType.warning:
        return Colors.yellow;
      case PunishmentType.temporaryBlock:
        return Colors.orange;
      case PunishmentType.permanentBlock:
        return Colors.red;
      case PunishmentType.suspension:
        return Colors.purple;
    }
  }

  IconData _getPunishmentTypeIcon(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return Icons.mic_off;
      case PunishmentType.postBan:
        return Icons.edit_off;
      case PunishmentType.accountBan:
        return Icons.no_accounts;
      case PunishmentType.deviceBan:
        return Icons.phonelink_erase;
      case PunishmentType.warning:
        return Icons.warning;
      case PunishmentType.temporaryBlock:
        return Icons.block;
      case PunishmentType.permanentBlock:
        return Icons.block;
      case PunishmentType.suspension:
        return Icons.pause_circle;
    }
  }

  String _getPunishmentTypeDisplayName(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return 'Voiceroom Ban';
      case PunishmentType.postBan:
        return 'Post Ban';
      case PunishmentType.accountBan:
        return 'Account Ban';
      case PunishmentType.deviceBan:
        return 'Device Ban';
      case PunishmentType.warning:
        return 'Warning';
      case PunishmentType.temporaryBlock:
        return 'Temporary Block';
      case PunishmentType.permanentBlock:
        return 'Permanent Block';
      case PunishmentType.suspension:
        return 'Suspension';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Dialog Methods
  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => BlockUserDialog(
        users: _filteredUsers,
        onUserBlocked: (user) {
          setState(() {
            _blockedUsers.add(user);
          });
          _showSuccessSnackBar('User blocked successfully');
        },
      ),
    );
  }

  void _showPunishmentDialog(PunishmentType type) {
    showDialog(
      context: context,
      builder: (context) => PunishmentDialog(
        users: _filteredUsers,
        punishmentType: type,
        onPunishmentAdded: (user) {
          _loadData(); // Reload to get updated punishments
          _showSuccessSnackBar('Punishment added successfully');
        },
      ),
    );
  }

  void _showUserDetailsDialog(UserProfileModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            user.profileImageUrl != null
                ? MediaPreviewWidget(
                    url: user.profileImageUrl!,
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadius.circular(20),
                  )
                : const CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'ID: ${user.userId}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('💎 Diamonds', user.totalDiamonds.toStringAsFixed(0)),
              _buildDetailRow('🫘 Beans', user.totalBeans.toStringAsFixed(0)),
              _buildDetailRow('📊 Status', user.status.name.toUpperCase()),
              _buildDetailRow('📅 Created', _formatDate(user.createdAt)),
              if (user.punishments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Punishments',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${user.punishments.length} punishment(s) issued',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showUnblockUserDialog(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Unblock User'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }


  void _showUnblockUserDialog(UserProfileModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Unblock User',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to unblock "${user.username}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final updatedProfile = user.copyWith(
                  status: UserStatus.active,
                  punishments: user.punishments.map((p) => p.copyWith(isActive: false)).toList(),
                  updatedAt: DateTime.now(),
                );

                await UserProfileService.updateUserProfile(updatedProfile);
                _loadData();
                _showSuccessSnackBar('User unblocked successfully');
              } catch (e) {
                _showErrorSnackBar('Error unblocking user: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  void _showAddPunishmentDialog(UserProfileModel user) {
    showDialog(
      context: context,
      builder: (context) => PunishmentDialog(
        users: [user],
        punishmentType: PunishmentType.warning,
        onPunishmentAdded: (user) {
          _loadData(); // Reload to get updated punishments
          _showSuccessSnackBar('Punishment added successfully');
        },
      ),
    );
  }
}

class BlockUserDialog extends StatefulWidget {
  final List<UserProfileModel> users;
  final Function(UserProfileModel) onUserBlocked;

  const BlockUserDialog({
    super.key,
    required this.users,
    required this.onUserBlocked,
  });

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  UserProfileModel? _selectedUser;
  final _reasonController = TextEditingController();
  PunishmentType _selectedType = PunishmentType.temporaryBlock;
  DateTime? _expiryDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Block User',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Selection
                    const Text(
                      'Select User',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: ListView.builder(
                        itemCount: widget.users.length,
                        itemBuilder: (context, index) {
                          final user = widget.users[index];
                          final isSelected = _selectedUser?.id == user.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.blue : Colors.grey[700],
                              child: Text(
                                user.username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              _getUserTypeDisplayName(user.userType),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                            onTap: () {
                              setState(() {
                                _selectedUser = user;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Punishment Type
                    const Text(
                      'Block Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PunishmentType>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white),
                      items: [
                        PunishmentType.voiceRoomBan,
                        PunishmentType.postBan,
                        PunishmentType.accountBan,
                        PunishmentType.deviceBan,
                        PunishmentType.temporaryBlock,
                        PunishmentType.permanentBlock,
                      ].map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getPunishmentTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          if (value == PunishmentType.permanentBlock) {
                            _expiryDate = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expiry Date (for timed bans)
                    if (_selectedType != PunishmentType.permanentBlock) ...[
                      const Text(
                        'Expiry Date',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                _expiryDate != null 
                                    ? _formatDate(_expiryDate!)
                                    : 'Select expiry date',
                                style: TextStyle(
                                  color: _expiryDate != null ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reason
                    const Text(
                      'Reason',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason for blocking...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedUser != null && _reasonController.text.isNotEmpty
                        ? _blockUser
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Block User'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  void _blockUser() async {
    if (_selectedUser != null) {
      try {
        final punishment = UserPunishment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          reason: _reasonController.text,
          type: _selectedType,
          issuedAt: DateTime.now(),
          expiresAt: _expiryDate,
          issuedBy: 'Admin',
        );

        final bool shouldBlockAccount = _selectedType == PunishmentType.accountBan ||
            _selectedType == PunishmentType.deviceBan ||
            _selectedType == PunishmentType.permanentBlock ||
            _selectedType == PunishmentType.temporaryBlock;

        final updatedProfile = _selectedUser!.copyWith(
          status: shouldBlockAccount ? UserStatus.blocked : _selectedUser!.status,
          punishments: [..._selectedUser!.punishments, punishment],
          updatedAt: DateTime.now(),
        );

        if (_selectedType == PunishmentType.deviceBan) {
          try {
            final docSnap = await FirebaseFirestore.instance.collection('Users').doc(_selectedUser!.id).get();
            final deviceId = docSnap.data()?['deviceId']?.toString() ?? _selectedUser!.id;

            await FirebaseFirestore.instance.collection('banned_devices').doc(deviceId).set({
              'deviceId': deviceId,
              'userId': _selectedUser!.userId,
              'reason': punishment.reason,
              'isPermanent': _expiryDate == null,
              'expiresAt': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
              'bannedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint('Error saving device ban to banned_devices: $e');
          }
        }

        await UserProfileService.updateUserProfile(updatedProfile);
        widget.onUserBlocked(_selectedUser!);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ban applied successfully (Real-time enforced)!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error blocking user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  String _getUserTypeDisplayName(UserType type) {
    switch (type) {
      case UserType.regular:
        return 'Regular User';
      case UserType.host:
        return 'Host';
      case UserType.seller:
        return 'Seller';
      case UserType.admin:
        return 'Admin';
      case UserType.agency:
        return 'Agency';
      case UserType.agency_owner:
        return 'Agency Owner';
    }
  }

  String _getPunishmentTypeDisplayName(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return 'Voiceroom Ban';
      case PunishmentType.postBan:
        return 'Post Ban';
      case PunishmentType.accountBan:
        return 'Account Ban';
      case PunishmentType.deviceBan:
        return 'Device Ban';
      case PunishmentType.warning:
        return 'Warning';
      case PunishmentType.temporaryBlock:
        return 'Temporary Block';
      case PunishmentType.permanentBlock:
        return 'Permanent Block';
      case PunishmentType.suspension:
        return 'Suspension';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class PunishmentDialog extends StatefulWidget {
  final List<UserProfileModel> users;
  final PunishmentType punishmentType;
  final Function(UserProfileModel) onPunishmentAdded;

  const PunishmentDialog({
    super.key,
    required this.users,
    required this.punishmentType,
    required this.onPunishmentAdded,
  });

  @override
  State<PunishmentDialog> createState() => _PunishmentDialogState();
}

class _PunishmentDialogState extends State<PunishmentDialog> {
  UserProfileModel? _selectedUser;
  final _reasonController = TextEditingController();
  DateTime? _expiryDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Issue ${_getPunishmentTypeDisplayName(widget.punishmentType)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Selection (if multiple users)
                    if (widget.users.length > 1) ...[
                      const Text(
                        'Select User',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[700]!),
                        ),
                        child: ListView.builder(
                          itemCount: widget.users.length,
                          itemBuilder: (context, index) {
                            final user = widget.users[index];
                            final isSelected = _selectedUser?.id == user.id;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? Colors.blue : Colors.grey[700],
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user.username,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                _getUserTypeDisplayName(user.userType),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                              onTap: () {
                                setState(() {
                                  _selectedUser = user;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Expiry Date (for temporary punishments)
                    if (widget.punishmentType == PunishmentType.temporaryBlock ||
                        widget.punishmentType == PunishmentType.suspension) ...[
                      const Text(
                        'Expiry Date',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectExpiryDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                _expiryDate != null 
                                    ? _formatDate(_expiryDate!)
                                    : 'Select expiry date',
                                style: TextStyle(
                                  color: _expiryDate != null ? Colors.white : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reason
                    const Text(
                      'Reason',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter reason for punishment...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedUser != null && _reasonController.text.isNotEmpty
                        ? _issuePunishment
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getPunishmentTypeColor(widget.punishmentType),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Issue ${_getPunishmentTypeDisplayName(widget.punishmentType)}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  void _issuePunishment() async {
    if (_selectedUser != null) {
      try {
        final punishment = UserPunishment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          reason: _reasonController.text,
          type: widget.punishmentType,
          issuedAt: DateTime.now(),
          expiresAt: _expiryDate,
          issuedBy: 'Admin',
        );

        final updatedProfile = _selectedUser!.copyWith(
          punishments: [..._selectedUser!.punishments, punishment],
          updatedAt: DateTime.now(),
        );

        await UserProfileService.updateUserProfile(updatedProfile);
        widget.onPunishmentAdded(_selectedUser!);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punishment issued successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error issuing punishment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getUserTypeDisplayName(UserType type) {
    switch (type) {
      case UserType.regular:
        return 'Regular User';
      case UserType.host:
        return 'Host';
      case UserType.seller:
        return 'Seller';
      case UserType.admin:
        return 'Admin';
      case UserType.agency:
        return 'Agency';
      case UserType.agency_owner:
        return 'Agency Owner';
    }
  }

  String _getPunishmentTypeDisplayName(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return 'Voiceroom Ban';
      case PunishmentType.postBan:
        return 'Post Ban';
      case PunishmentType.accountBan:
        return 'Account Ban';
      case PunishmentType.deviceBan:
        return 'Device Ban';
      case PunishmentType.warning:
        return 'Warning';
      case PunishmentType.temporaryBlock:
        return 'Temporary Block';
      case PunishmentType.permanentBlock:
        return 'Permanent Block';
      case PunishmentType.suspension:
        return 'Suspension';
    }
  }

  Color _getPunishmentTypeColor(PunishmentType type) {
    switch (type) {
      case PunishmentType.voiceRoomBan:
        return Colors.purpleAccent;
      case PunishmentType.postBan:
        return Colors.orangeAccent;
      case PunishmentType.accountBan:
        return Colors.redAccent;
      case PunishmentType.deviceBan:
        return Colors.deepOrange;
      case PunishmentType.warning:
        return Colors.yellow;
      case PunishmentType.temporaryBlock:
        return Colors.orange;
      case PunishmentType.permanentBlock:
        return Colors.red;
      case PunishmentType.suspension:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
