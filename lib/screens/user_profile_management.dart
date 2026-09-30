import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../widgets/media_preview_widget.dart';
import '../models/store_item_model.dart';
import '../services/user_profile_service.dart';

class UserProfileManagement extends StatefulWidget {
  const UserProfileManagement({super.key});

  @override
  State<UserProfileManagement> createState() => _UserProfileManagementState();
}

class _UserProfileManagementState extends State<UserProfileManagement> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  StreamSubscription<List<UserProfileModel>>? _userProfilesSubscription;
  StreamSubscription<DocumentSnapshot>? _themeSubscription;
  
  String? _diamondIconUrl;
  String? _beansIconUrl;

  List<UserProfileModel> _userProfiles = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String _searchQuery = '';
  UserType? _selectedUserType;
  UserStatus? _selectedStatus;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
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
    _startRealtimeListener();
    _startThemeListener();
    _animationController.forward();
  }

  void _startRealtimeListener() {
    _userProfilesSubscription?.cancel();
    _userProfilesSubscription = UserProfileService.getUserProfilesStream().listen((profiles) {
      if (mounted) {
        setState(() {
          _userProfiles = profiles;
          _isLoading = false;
        });
      }
    }, onError: (e) {
      debugPrint('Realtime user profiles stream error: $e');
    });
  }

  void _startThemeListener() {
    _themeSubscription?.cancel();
    _themeSubscription = FirebaseFirestore.instance
        .collection('global_settings')
        .doc('app_theme')
        .snapshots()
        .listen((docSnap) {
      if (docSnap.exists && mounted) {
        final data = docSnap.data() ?? {};
        setState(() {
          _diamondIconUrl = data['diamondIconUrl']?.toString();
          _beansIconUrl = data['beansIconUrl']?.toString();
        });
      }
    }, onError: (e) {
      debugPrint('Realtime theme listener error: $e');
    });
  }

  Widget _buildDiamondsDisplay(double amount, {double fontSize = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          amount.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.cyan,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _diamondIconUrl != null && _diamondIconUrl!.trim().isNotEmpty
            ? MediaPreviewWidget(
                url: _diamondIconUrl!,
                width: fontSize + 2,
                height: fontSize + 2,
                borderRadius: BorderRadius.circular(4),
              )
            : Text(
                '💎',
                style: TextStyle(fontSize: fontSize - 2),
              ),
      ],
    );
  }

  Widget _buildBeansDisplay(double amount, {double fontSize = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          amount.toStringAsFixed(0),
          style: TextStyle(
            color: Colors.amber[600] ?? Colors.orange,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        _beansIconUrl != null && _beansIconUrl!.trim().isNotEmpty
            ? MediaPreviewWidget(
                url: _beansIconUrl!,
                width: fontSize + 2,
                height: fontSize + 2,
                borderRadius: BorderRadius.circular(4),
              )
            : Text(
                '🫘',
                style: TextStyle(fontSize: fontSize - 2),
              ),
      ],
    );
  }

  @override
  void dispose() {
    _userProfilesSubscription?.cancel();
    _themeSubscription?.cancel();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profiles = await UserProfileService.getAllUserProfiles();
      final stats = await UserProfileService.getUserStatistics();

      if (mounted) {
        setState(() {
          _userProfiles = profiles;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load user data');
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

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  List<UserProfileModel> get _filteredProfiles {
    var filtered = _userProfiles;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((profile) =>
          profile.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (profile.searchId != null && profile.searchId!.contains(_searchQuery)) ||
          (profile.phone != null && profile.phone!.contains(_searchQuery))).toList();
    }

    if (_selectedUserType != null) {
      filtered = filtered.where((profile) => profile.userType == _selectedUserType).toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered.where((profile) => profile.status == _selectedStatus).toList();
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
          '👤 User Profile Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildUserProfilesTab(),
                      _buildLevelsTab(),
                      _buildCustomizationTab(),
                      _buildBlockedUsersTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.people), text: 'Users'),
          Tab(icon: Icon(Icons.trending_up), text: 'Levels'),
          Tab(icon: Icon(Icons.palette), text: 'Customization'),
          Tab(icon: Icon(Icons.block), text: 'Blocked'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActionsMenu,
        backgroundColor: Colors.blue,
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
                      hintText: '🔍 Search by name or searchId...',
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
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilters ? Colors.blue : Colors.grey,
                ),
                onPressed: _toggleFilters,
                tooltip: 'Filters',
              ),
            ],
          ),
          
          // Filter Chips
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 50 : 0,
            child: _showFilters
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All Types', null, UserType.regular),
                          const SizedBox(width: 8),
                          ...UserType.values.map((type) => 
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildFilterChip(
                                _getUserTypeDisplayName(type),
                                type,
                                type,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildStatusFilterChip('All Status', null),
                          const SizedBox(width: 8),
                          ...UserStatus.values.map((status) => 
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildStatusFilterChip(
                                _getUserStatusDisplayName(status),
                                status,
                              ),
                            ),
                          ),
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

  Widget _buildFilterChip(String label, UserType? type, UserType chipType) {
    final isSelected = _selectedUserType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedUserType = selected ? type : null;
        });
      },
      selectedColor: Colors.blue.withValues(alpha: 0.3),
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, UserStatus? status) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      selectedColor: Colors.red.withValues(alpha: 0.3),
      checkmarkColor: Colors.red,
      labelStyle: TextStyle(
        color: isSelected ? Colors.red : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getUserTypeDisplayName(UserType type) {
    switch (type) {
      case UserType.regular:
        return 'Regular';
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'User Statistics',
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
                  title: 'Active Users',
                  value: _statistics['activeUsers']?.toString() ?? '0',
                  icon: Icons.check_circle,
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
                  title: 'Hosts',
                  value: _statistics['hosts']?.toString() ?? '0',
                  icon: Icons.mic,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Sellers',
                  value: _statistics['sellers']?.toString() ?? '0',
                  icon: Icons.store,
                  color: Colors.orange,
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
                  value: '${(_statistics['totalDiamonds'] ?? 0.0).toStringAsFixed(0)}💎',
                  icon: Icons.diamond,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Beans',
                  value: '${(_statistics['totalBeans'] ?? 0.0).toStringAsFixed(0)}🫘',
                  icon: Icons.coffee,
                  color: Colors.brown,
                ),
              ),
            ],
          ),

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
                  title: 'Add User Profile',
                  subtitle: 'Create new user profile',
                  icon: Icons.person_add,
                  color: Colors.green,
                  onTap: () => _showAddUserDialog(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Manage Levels',
                  subtitle: 'Configure level system',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Market Items',
                  subtitle: 'Manage frames, badges, effects',
                  icon: Icons.storefront,
                  color: Colors.blue,
                  onTap: () => _showMarketManagement(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Blocked Users',
                  subtitle: 'Manage user blocks and punishments',
                  icon: Icons.block,
                  color: Colors.red,
                  onTap: () => _tabController.animateTo(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfilesTab() {
    final filteredProfiles = _filteredProfiles;
    
    return filteredProfiles.isEmpty
        ? const Center(
            child: Text(
              'No users found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredProfiles.length,
            itemBuilder: (context, index) {
              final profile = filteredProfiles[index];
              return _buildUserProfileCard(profile);
            },
          );
  }

  Widget _buildLevelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Level System Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelConfigCard(
            title: 'Sending Levels',
            description: 'Levels based on diamonds sent',
            icon: Icons.send,
            color: Colors.blue,
            onTap: () => _showLevelConfigDialog(LevelType.sending),
          ),

          const SizedBox(height: 16),

          _buildLevelConfigCard(
            title: 'Receiving Levels',
            description: 'Levels based on diamonds received',
            icon: Icons.call_received,
            color: Colors.green,
            onTap: () => _showLevelConfigDialog(LevelType.receiving),
          ),

          const SizedBox(height: 16),

          _buildLevelConfigCard(
            title: 'Gifting Levels',
            description: 'Levels based on gifting activity',
            icon: Icons.card_giftcard,
            color: Colors.purple,
            onTap: () => _showLevelConfigDialog(LevelType.gifting),
          ),

          const SizedBox(height: 24),

          const Text(
            'Level Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelStats(),
        ],
      ),
    );
  }

  Widget _buildCustomizationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customization Management',
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
                child: _buildCustomizationCard(
                  title: 'Badges',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  onTap: () => _showMarketItemsDialog(StoreItemType.badge),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCustomizationCard(
                  title: 'Frames',
                  icon: Icons.photo,
                  color: Colors.cyan,
                  onTap: () => _showMarketItemsDialog(StoreItemType.avatarFrame),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildCustomizationCard(
                  title: 'Entry Effects',
                  icon: Icons.auto_awesome,
                  color: Colors.pink,
                  onTap: () => _showMarketItemsDialog(StoreItemType.entryEffect),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCustomizationCard(
                  title: 'Backgrounds',
                  icon: Icons.palette,
                  color: Colors.teal,
                  onTap: () => _showMarketItemsDialog(StoreItemType.backgroundTheme),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _showAddMarketItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add New Market Item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersTab() {
    final blockedProfiles = _userProfiles.where((p) => p.isBlocked).toList();
    
    return blockedProfiles.isEmpty
        ? const Center(
            child: Text(
              'No blocked users found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blockedProfiles.length,
            itemBuilder: (context, index) {
              final profile = blockedProfiles[index];
              return _buildBlockedUserCard(profile);
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

  Widget _buildUserProfileCard(UserProfileModel profile) {
    final String displayName = profile.username.trim().isNotEmpty
        ? profile.username
        : ((profile.searchId != null && profile.searchId!.isNotEmpty)
            ? 'User ${profile.searchId}'
            : 'User ${profile.userId}');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getUserTypeColor(profile.userType),
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
                  backgroundColor: _getUserTypeColor(profile.userType).withValues(alpha: 0.2),
                  child: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                      ? MediaPreviewWidget(
                          url: profile.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : Icon(
                          Icons.person,
                          color: _getUserTypeColor(profile.userType),
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getUserTypeDisplayName(profile.userType),
                        style: TextStyle(
                          color: _getUserTypeColor(profile.userType),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${profile.searchId ?? profile.userId}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (profile.phone != null && profile.phone!.isNotEmpty)
                        Text(
                          '📱 Phone: ${profile.phone}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      if (profile.email != null && profile.email!.isNotEmpty)
                        Text(
                          '🌐 Google/Email: ${profile.email}',
                          style: const TextStyle(
                            color: Color(0xFFFCA5A5),
                            fontSize: 12,
                          ),
                        ),
                      if (profile.isHost && profile.agencyName != null)
                        Text(
                          'Agency: ${profile.agencyName}',
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
                    color: _getUserStatusColor(profile.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getUserStatusDisplayName(profile.status),
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
            
            // Diamonds and Beans
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
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      _buildDiamondsDisplay(profile.totalDiamonds, fontSize: 18),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Beans',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      _buildBeansDisplay(profile.totalBeans, fontSize: 18),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Levels',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'S:${profile.sendingLevel.level} R:${profile.receivingLevel.level}',
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
                    onPressed: () => _showUserDetailsDialog(profile),
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
                    onPressed: () => _showEditUserDialog(profile),
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
                    onPressed: () => _showBlockUserDialog(profile),
                    icon: const Icon(Icons.block),
                    label: const Text('Block'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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

  Widget _buildLevelConfigCard({
    required String title,
    required String description,
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
          border: Border.all(color: color, width: 2),
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
                    description,
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

  Widget _buildLevelStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildLevelStatRow('Average Sending Level', '5.2'),
          const Divider(color: Colors.grey),
          _buildLevelStatRow('Average Receiving Level', '3.8'),
          const Divider(color: Colors.grey),
          _buildLevelStatRow('Highest Sending Level', '25'),
          const Divider(color: Colors.grey),
          _buildLevelStatRow('Highest Receiving Level', '18'),
        ],
      ),
    );
  }

  Widget _buildLevelStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationCard({
    required String title,
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
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(UserProfileModel profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              child: const Icon(
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
                    profile.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Blocked since: ${_formatDate(profile.updatedAt)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (profile.punishments.isNotEmpty)
                    Text(
                      'Punishments: ${profile.punishments.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUnblockUserDialog(profile),
              icon: const Icon(Icons.check),
              label: const Text('Unblock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
              icon: Icons.person_add,
              title: 'Add User Profile',
              subtitle: 'Create a new user profile',
              onTap: () {
                Navigator.pop(context);
                _showAddUserDialog();
              },
            ),
            _buildQuickActionTile(
              icon: Icons.storefront,
              title: 'Add Market Item',
              subtitle: 'Add frames, badges, effects',
              onTap: () {
                Navigator.pop(context);
                _showAddMarketItemDialog();
              },
            ),
            _buildQuickActionTile(
              icon: Icons.trending_up,
              title: 'Configure Levels',
              subtitle: 'Set up level system',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            _buildQuickActionTile(
              icon: Icons.analytics,
              title: 'View Statistics',
              subtitle: 'Check user analytics',
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
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
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // Dialog Methods
  void _showAddUserDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final bioController = TextEditingController();
    final diamondsController = TextEditingController();
    final beansController = TextEditingController();
    
    UserType selectedUserType = UserType.regular;
    UserStatus selectedStatus = UserStatus.active;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add New User',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: diamondsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diamonds',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: beansController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Beans',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserType>(
                  initialValue: selectedUserType,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    labelText: 'User Type',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  items: UserType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserStatus>(
                  initialValue: selectedStatus,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  items: UserStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newUser = UserProfileModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: DateTime.now().millisecondsSinceEpoch.toString(),
                    username: usernameController.text,
                    profileImageUrl: null,
                    bio: bioController.text,
                    phone: phoneController.text,
                    userType: selectedUserType,
                    status: selectedStatus,
                    totalDiamonds: double.tryParse(diamondsController.text) ?? 0.0,
                    totalBeans: double.tryParse(beansController.text) ?? 0.0,
                    diamondsSent: 0.0,
                    diamondsReceived: 0.0,
                    sendingLevel: UserLevel(
                      level: 1,
                      currentProgress: 0.0,
                      requiredForNext: 1000.0,
                      levelName: 'Level 1',
                      lastUpdated: DateTime.now(),
                    ),
                    receivingLevel: UserLevel(
                      level: 1,
                      currentProgress: 0.0,
                      requiredForNext: 1000.0,
                      levelName: 'Level 1',
                      lastUpdated: DateTime.now(),
                    ),
                    giftingLevel: UserLevel(
                      level: 1,
                      currentProgress: 0.0,
                      requiredForNext: 1000.0,
                      levelName: 'Level 1',
                      lastUpdated: DateTime.now(),
                    ),
                    customization: UserCustomization(),
                    activityStats: UserActivityStats(lastUpdated: DateTime.now()),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await UserProfileService.createUserProfile(newUser);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  _showSuccessSnackBar('User created successfully');
                } catch (e) {
                  _showErrorSnackBar('Error creating user: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(UserProfileModel profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                ? MediaPreviewWidget(
                    url: profile.profileImageUrl!,
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
                    profile.username.trim().isNotEmpty
                        ? profile.username
                        : ((profile.searchId != null && profile.searchId!.isNotEmpty)
                            ? 'User ${profile.searchId}'
                            : 'User ${profile.userId}'),
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    'ID: ${profile.searchId ?? profile.userId}',
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
              if (profile.phone != null && profile.phone!.isNotEmpty)
                _buildDetailRow('📱 Phone', profile.phone!),
              if (profile.email != null && profile.email!.isNotEmpty)
                _buildDetailRow('🌐 Google / Email', profile.email!),
              _buildDetailRow('💎 Diamonds', profile.totalDiamonds.toStringAsFixed(0)),
              _buildDetailRow('🫘 Beans', profile.totalBeans.toStringAsFixed(0)),
              _buildDetailRow('📤 Sending Level', 'Level ${profile.sendingLevel.level}'),
              _buildDetailRow('📥 Receiving Level', 'Level ${profile.receivingLevel.level}'),
              _buildDetailRow('🎁 Gifting Level', 'Level ${profile.giftingLevel.level}'),
              _buildDetailRow('👤 User Type', profile.userType.name.toUpperCase()),
              _buildDetailRow('📊 Status', profile.status.name.toUpperCase()),
              if (profile.isHost) ...[
                _buildDetailRow('🏢 Agency ID', profile.agencyId ?? 'None'),
                _buildDetailRow('🏢 Agency Name', profile.agencyName ?? 'None'),
              ],
              _buildDetailRow('📅 Created', _formatDate(profile.createdAt)),
              _buildDetailRow('🔄 Updated', _formatDate(profile.updatedAt)),
              if (profile.lastActiveAt != null)
                _buildDetailRow('🟢 Last Active', _formatDate(profile.lastActiveAt!)),
              const SizedBox(height: 16),
              const Text(
                'Activity Stats',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('📤 Daily Sent', '${profile.activityStats.dailyDiamondsSent.toStringAsFixed(0)} 💎'),
              _buildDetailRow('📥 Daily Received', '${profile.activityStats.dailyDiamondsReceived.toStringAsFixed(0)} 💎'),
              _buildDetailRow('📊 Weekly Sent', '${profile.activityStats.weeklyDiamondsSent.toStringAsFixed(0)} 💎'),
              _buildDetailRow('📊 Weekly Received', '${profile.activityStats.weeklyDiamondsReceived.toStringAsFixed(0)} 💎'),
              _buildDetailRow('📈 Monthly Sent', '${profile.activityStats.monthlyDiamondsSent.toStringAsFixed(0)} 💎'),
              _buildDetailRow('📈 Monthly Received', '${profile.activityStats.monthlyDiamondsReceived.toStringAsFixed(0)} 💎'),
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
              _showEditUserDialog(profile);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Edit User'),
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


  void _showEditUserDialog(UserProfileModel profile) {
    final usernameController = TextEditingController(text: profile.username);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final emailController = TextEditingController(text: profile.email ?? '');
    final diamondsController = TextEditingController(text: profile.totalDiamonds.toString());
    final beansController = TextEditingController(text: profile.totalBeans.toString());
    final sendingLevelController = TextEditingController(text: profile.sendingLevel.level.toString());
    final receivingLevelController = TextEditingController(text: profile.receivingLevel.level.toString());
    
    UserType selectedUserType = profile.userType;
    UserStatus selectedStatus = profile.status;
    String? selectedAgencyId = profile.agencyId;
    String? selectedAgencyName = profile.agencyName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Edit User Profile',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Google / Email Account',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: diamondsController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Diamonds',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: beansController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Beans',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sendingLevelController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sending Level',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: receivingLevelController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Receiving Level',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserType>(
                  initialValue: selectedUserType,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    labelText: 'User Type',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  items: UserType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserStatus>(
                  initialValue: selectedStatus,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.grey[800],
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                  items: UserStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(
                        status.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                if (selectedUserType == UserType.host) ...[
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Agency ID',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => selectedAgencyId = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Agency Name',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => selectedAgencyName = value,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Determine new levels
                  final newSendingLevelInt = int.tryParse(sendingLevelController.text) ?? profile.sendingLevel.level;
                  final newReceivingLevelInt = int.tryParse(receivingLevelController.text) ?? profile.receivingLevel.level;

                  // Define requirements
                  final Map<int, int> sendingReqs = {
                    1: 0, 2: 100, 3: 500, 4: 1000, 5: 2500,
                    6: 5000, 7: 10000, 8: 25000, 9: 50000, 10: 100000,
                  };
                  final Map<int, int> receivingReqs = {
                    1: 0, 2: 50, 3: 250, 4: 500, 5: 1250,
                    6: 2500, 7: 5000, 8: 12500, 9: 25000, 10: 50000,
                  };

                  // Calculate Sending Progress
                  double newSendingProgress = profile.sendingLevel.currentProgress;
                  if (newSendingLevelInt != profile.sendingLevel.level) {
                    newSendingProgress = (sendingReqs[newSendingLevelInt] ?? 0).toDouble();
                  }
                  final double reqForNextSending = (sendingReqs[newSendingLevelInt + 1] ?? sendingReqs[10] ?? 100000).toDouble();

                  // Calculate Receiving Progress
                  double newReceivingProgress = profile.receivingLevel.currentProgress;
                  if (newReceivingLevelInt != profile.receivingLevel.level) {
                    newReceivingProgress = (receivingReqs[newReceivingLevelInt] ?? 0).toDouble();
                  }
                  final double reqForNextReceiving = (receivingReqs[newReceivingLevelInt + 1] ?? receivingReqs[10] ?? 50000).toDouble();

                  // Update user profile
                  final updatedProfile = profile.copyWith(
                    username: usernameController.text,
                    phone: phoneController.text,
                    email: emailController.text.trim(),
                    totalDiamonds: double.tryParse(diamondsController.text) ?? profile.totalDiamonds,
                    totalBeans: double.tryParse(beansController.text) ?? profile.totalBeans,
                    diamondsSent: newSendingProgress,
                    diamondsReceived: newReceivingProgress,
                    sendingLevel: UserLevel(
                      level: newSendingLevelInt,
                      currentProgress: newSendingProgress,
                      requiredForNext: reqForNextSending,
                      levelName: 'Level $newSendingLevelInt',
                      lastUpdated: DateTime.now(),
                    ),
                    receivingLevel: UserLevel(
                      level: newReceivingLevelInt,
                      currentProgress: newReceivingProgress,
                      requiredForNext: reqForNextReceiving,
                      levelName: 'Level $newReceivingLevelInt',
                      lastUpdated: DateTime.now(),
                    ),
                    userType: selectedUserType,
                    status: selectedStatus,
                    agencyId: selectedAgencyId,
                    agencyName: selectedAgencyName,
                    updatedAt: DateTime.now(),
                  );

                  await UserProfileService.updateUserProfile(updatedProfile);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  _showSuccessSnackBar('User profile updated successfully');
                } catch (e) {
                  _showErrorSnackBar('Error updating user: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockUserDialog(UserProfileModel profile) {
    final reasonController = TextEditingController();
    PunishmentType selectedPunishmentType = PunishmentType.voiceRoomBan;
    bool isPermanent = false;
    int selectedDuration = 1;
    String selectedDurationUnit = 'days';

    final banCategories = [
      {
        'type': PunishmentType.voiceRoomBan,
        'title': '🎤 Voiceroom Ban',
        'desc': 'User cannot take a mic or seat in voicerooms',
        'color': Colors.purpleAccent,
      },
      {
        'type': PunishmentType.postBan,
        'title': '📝 Post Ban',
        'desc': 'User cannot create or publish news feed posts',
        'color': Colors.orangeAccent,
      },
      {
        'type': PunishmentType.accountBan,
        'title': '👤 Account Ban',
        'desc': 'User gets logged out & cannot sign in with this number',
        'color': Colors.redAccent,
      },
      {
        'type': PunishmentType.deviceBan,
        'title': '📱 Device Ban',
        'desc': 'User gets logged out & this device is completely banned',
        'color': Colors.deepOrange,
      },
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.block, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ban User: ${profile.username}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Ban Category:',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Category Selector
                  ...banCategories.map((category) {
                    final isSelected = selectedPunishmentType == category['type'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedPunishmentType = category['type'] as PunishmentType;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (category['color'] as Color).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? (category['color'] as Color)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: isSelected ? (category['color'] as Color) : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['title'] as String,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      category['desc'] as String,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 14),

                  // Reason
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Reason for Ban',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. Inappropriate behavior / rules violation',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 14),

                  // Permanent or Timed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Permanent Ban:',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Switch(
                        value: isPermanent,
                        activeColor: Colors.redAccent,
                        onChanged: (val) {
                          setState(() {
                            isPermanent = val;
                          });
                        },
                      ),
                    ],
                  ),

                  if (!isPermanent) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Duration',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            controller: TextEditingController(text: selectedDuration.toString()),
                            onChanged: (value) => selectedDuration = int.tryParse(value) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDurationUnit,
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF252538),
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: ['hours', 'days', 'weeks', 'months'].map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedDurationUnit = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.gavel, size: 18),
              onPressed: () async {
                try {
                  final DateTime? expiresAt = isPermanent
                      ? null
                      : _calculateExpiryDate(selectedDuration, selectedDurationUnit);

                  final punishment = UserPunishment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    reason: reasonController.text.trim().isNotEmpty
                        ? reasonController.text.trim()
                        : 'Violation of Community Guidelines',
                    type: selectedPunishmentType,
                    issuedAt: DateTime.now(),
                    expiresAt: expiresAt,
                    issuedBy: 'Admin',
                    isActive: true,
                  );

                  // If account ban or device ban, set overall user status to blocked
                  final bool shouldBlockAccount = selectedPunishmentType == PunishmentType.accountBan ||
                      selectedPunishmentType == PunishmentType.deviceBan;

                  final updatedProfile = profile.copyWith(
                    status: shouldBlockAccount ? UserStatus.blocked : profile.status,
                    punishments: [...profile.punishments, punishment],
                    updatedAt: DateTime.now(),
                  );

                  // If device ban, record to banned_devices collection in Firestore
                  if (selectedPunishmentType == PunishmentType.deviceBan) {
                    try {
                      final docSnap = await FirebaseFirestore.instance.collection('Users').doc(profile.id).get();
                      final deviceId = docSnap.data()?['deviceId']?.toString() ?? profile.id;

                      await FirebaseFirestore.instance.collection('banned_devices').doc(deviceId).set({
                        'deviceId': deviceId,
                        'userId': profile.userId,
                        'reason': punishment.reason,
                        'isPermanent': isPermanent,
                        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
                        'bannedAt': FieldValue.serverTimestamp(),
                      });
                    } catch (e) {
                      debugPrint('Error saving device ban to banned_devices: $e');
                    }
                  }

                  await UserProfileService.updateUserProfile(updatedProfile);

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadData();
                  _showSuccessSnackBar('Ban applied successfully (Real-time enforced)!');
                } catch (e) {
                  _showErrorSnackBar('Error applying ban: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: const Text('Apply Ban', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnblockUserDialog(UserProfileModel profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Unblock User: ${profile.username}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove all active bans and restore full access for ${profile.username}?',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 12),
            if (profile.punishments.any((p) => p.isActive)) ...[
              const Text(
                'Active Restrictions to Clear:',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...profile.punishments.where((p) => p.isActive).map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${p.type.name} - ${p.reason}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedProfile = profile.copyWith(
                  status: UserStatus.active,
                  punishments: profile.punishments.map((p) => p.copyWith(isActive: false)).toList(),
                  updatedAt: DateTime.now(),
                );

                // Clean device ban if any
                try {
                  final docSnap = await FirebaseFirestore.instance.collection('Users').doc(profile.id).get();
                  final deviceId = docSnap.data()?['deviceId']?.toString() ?? profile.id;
                  await FirebaseFirestore.instance.collection('banned_devices').doc(deviceId).delete();
                } catch (_) {}

                await UserProfileService.updateUserProfile(updatedProfile);

                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('All bans lifted successfully!');
              } catch (e) {
                _showErrorSnackBar('Error unblocking user: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Unblock All Restrictions', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DateTime? _calculateExpiryDate(int duration, String unit) {
    final now = DateTime.now();
    switch (unit) {
      case 'hours':
        return now.add(Duration(hours: duration));
      case 'days':
        return now.add(Duration(days: duration));
      case 'weeks':
        return now.add(Duration(days: duration * 7));
      case 'months':
        return now.add(Duration(days: duration * 30));
      default:
        return null;
    }
  }

  void _showLevelConfigDialog(LevelType type) {
    // TODO: Implement level config dialog
    _showSuccessSnackBar('Level config dialog coming soon');
  }

  void _showMarketItemsDialog(StoreItemType type) {
    // TODO: Implement market items dialog
    _showSuccessSnackBar('Market items dialog coming soon');
  }

  void _showAddMarketItemDialog() {
    // TODO: Implement add market item dialog
    _showSuccessSnackBar('Add market item dialog coming soon');
  }

  void _showMarketManagement() {
    // TODO: Implement market management
    _showSuccessSnackBar('Market management coming soon');
  }
}
