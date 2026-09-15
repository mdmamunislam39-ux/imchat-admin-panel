import 'package:flutter/material.dart';
import '../models/store_item_model.dart';
import '../services/store_service.dart';
import 'assign_item_screen.dart';
import 'store_analytics_screen.dart';
import 'official_store_screen.dart';
import 'add_store_item_screen.dart';

class StoreManagement extends StatefulWidget {
  const StoreManagement({super.key});

  @override
  State<StoreManagement> createState() => _StoreManagementState();
}

class _StoreManagementState extends State<StoreManagement> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  List<StoreItemModel> _storeItems = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  StoreItemType? _selectedFilter;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final items = await StoreService.getAllStoreItems();
      final stats = await StoreService.getStoreStatistics();

      if (mounted) {
        setState(() {
          _storeItems = items;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading store data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load store data');
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

  void _filterItems(String query) {
    // TODO: Implement search functionality
    debugPrint('Search query: $query');
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  Widget _buildFilterChip(String label, StoreItemType? type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? type : null;
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

  String _getTypeDisplayName(StoreItemType type) {
    switch (type) {
      case StoreItemType.avatarFrame:
        return 'Avatar Frame';
      case StoreItemType.entryEffect:
        return 'Entry Effect';
      case StoreItemType.badge:
        return 'Badge';
      case StoreItemType.backgroundTheme:
        return 'Room Background Theme';
      case StoreItemType.roomTheme:
        return 'Profile Skin';
      case StoreItemType.seatDecor:
        return 'Seat Decor';
      case StoreItemType.micRefill:
        return 'Mic Refill';
      case StoreItemType.roomProfileBackground:
        return 'RP Background';
      case StoreItemType.shortProfileTheme:
        return 'Short Profile Theme';
      case StoreItemType.roomEntry:
        return 'Room Entry';
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: const Text(
                '🛍️ Store Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: IconButton(
                  icon: const Icon(Icons.analytics),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreAnalyticsScreen(),
                      ),
                    );
                  },
                  tooltip: 'Analytics',
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          onChanged: _filterItems,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: '🔍 Search items...',
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        icon: Icon(
                          _showFilters ? Icons.filter_list_off : Icons.filter_list,
                          color: _showFilters ? Colors.blue : Colors.grey,
                        ),
                        onPressed: _toggleFilters,
                        tooltip: 'Filters',
                      ),
                    ),
                  ],
                ),
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
                              _buildFilterChip('All', null),
                              const SizedBox(width: 8),
                              ...StoreItemType.values.map((type) => 
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterChip(
                                    _getTypeDisplayName(type),
                                    type,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                  Tab(icon: Icon(Icons.store), text: 'Store'),
                  Tab(icon: Icon(Icons.admin_panel_settings), text: 'Official'),
                  Tab(icon: Icon(Icons.person_add), text: 'Assign'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildStoreItemsTab(),
                _buildOfficialStoreTab(),
                _buildAssignItemsTab(),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () {
                _showQuickActionsMenu();
              },
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.flash_on),
              label: const Text('Quick Actions'),
            ),
          );
        },
      ),
    );
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
              icon: Icons.add_box,
              title: 'Add Store Item',
              subtitle: 'Create a new store item (Seat Decor, Frames, etc.)',
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStoreItemScreen(),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),
            _buildQuickActionTile(
              icon: Icons.person_add,
              title: 'Assign Items',
              subtitle: 'Assign items to users',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AssignItemScreen(),
                  ),
                );
              },
            ),
            _buildQuickActionTile(
              icon: Icons.analytics,
              title: 'View Analytics',
              subtitle: 'Check performance metrics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoreAnalyticsScreen(),
                  ),
                );
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          const Text(
            'Store Statistics',
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
                  title: 'Total Items',
                  value: _statistics['totalItems']?.toString() ?? '0',
                  icon: Icons.inventory,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Store Items',
                  value: _statistics['storeItems']?.toString() ?? '0',
                  icon: Icons.store,
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
                  title: 'Official Store',
                  value: _statistics['officialStoreItems']?.toString() ?? '0',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Assignments',
                  value: _statistics['totalAssignments']?.toString() ?? '0',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Item Type Statistics
          const Text(
            'Items by Type',
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
                child: _buildStatCard(
                  title: 'Avatar Frames',
                  value: _statistics['avatarFrames']?.toString() ?? '0',
                  icon: Icons.photo,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Entry Effects',
                  value: _statistics['entryEffects']?.toString() ?? '0',
                  icon: Icons.auto_awesome,
                  color: Colors.pink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Badges',
                  value: _statistics['badges']?.toString() ?? '0',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Background Themes',
                  value: _statistics['backgroundThemes']?.toString() ?? '0',
                  icon: Icons.palette,
                  color: Colors.teal,
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
                  title: 'Assign Items to Users',
                  subtitle: 'Assign official store items to users',
                  icon: Icons.person_add,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignItemScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Official Store',
                  subtitle: 'Manage official items',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfficialStoreScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Assign Items to Users',
                  subtitle: 'Assign official store items to users',
                  icon: Icons.person_add,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignItemScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Official Store',
                  subtitle: 'Manage official items',
                  icon: Icons.admin_panel_settings,
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfficialStoreScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Advanced Analytics',
                  subtitle: 'View detailed analytics and reports',
                  icon: Icons.analytics,
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreAnalyticsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoreItemsTab() {
    final storeItems = _storeItems.where((item) => item.category == StoreCategory.store).toList();
    
    return storeItems.isEmpty
        ? const Center(
            child: Text(
              'No store items found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: storeItems.length,
            itemBuilder: (context, index) {
              final item = storeItems[index];
              return _buildStoreItemCard(item);
            },
          );
  }

  Widget _buildOfficialStoreTab() {
    final officialItems = _storeItems.where((item) => item.category == StoreCategory.officialStore).toList();
    
    return officialItems.isEmpty
        ? const Center(
            child: Text(
              'No official store items found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: officialItems.length,
            itemBuilder: (context, index) {
              final item = officialItems[index];
              return _buildStoreItemCard(item);
            },
          );
  }

  Widget _buildAssignItemsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add,
            size: 64,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          Text(
            'Assign Items to Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Click the button below to assign official store items to users',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 24),
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[900]!,
                  Colors.grey[800]!,
                ],
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

  Widget _buildStoreItemCard(StoreItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.category == StoreCategory.officialStore ? Colors.purple : Colors.green,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.category == StoreCategory.officialStore 
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.typeIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.typeDisplayName,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item.categoryDisplayName,
                        style: TextStyle(
                          color: item.category == StoreCategory.officialStore 
                              ? Colors.purple 
                              : Colors.green,
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
                    color: item.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.isActive ? 'ACTIVE' : 'INACTIVE',
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
            
            // Price and Duration
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
                        'Price',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${item.diamondPrice.toStringAsFixed(0)}💎',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item.expirationText,
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
          ],
        ),
      ),
    );
  }
}
