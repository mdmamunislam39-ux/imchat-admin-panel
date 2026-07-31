import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../widgets/media_preview_widget.dart';
import '../services/user_profile_service.dart';

class UserHistoryStats extends StatefulWidget {
  final String userId;
  final String username;

  const UserHistoryStats({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserHistoryStats> createState() => _UserHistoryStatsState();
}

class _UserHistoryStatsState extends State<UserHistoryStats> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  UserProfileModel? _userProfile;
  List<UserHistoryEntry> _historyEntries = [];
  bool _isLoading = true;
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
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

      final profile = await UserProfileService.getUserProfile(widget.userId);
      final history = await UserProfileService.getUserHistory(widget.userId);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _historyEntries = history;
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '📊 ${widget.username} - History & Stats',
          style: const TextStyle(
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
          : _userProfile == null
              ? const Center(
                  child: Text(
                    'User profile not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : Column(
                  children: [
                    _buildPeriodSelector(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildActivityTab(),
                          _buildLevelsTab(),
                          _buildHistoryTab(),
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
          Tab(icon: Icon(Icons.trending_up), text: 'Activity'),
          Tab(icon: Icon(Icons.star), text: 'Levels'),
          Tab(icon: Icon(Icons.history), text: 'History'),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Period:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Today', 'This Week', 'This Month', 'All Time'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPeriod = period;
                        });
                      },
                      selectedColor: Colors.blue.withValues(alpha: 0.3),
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          _buildUserProfileCard(),
          const SizedBox(height: 24),

          // Current Stats
          const Text(
            'Current Stats',
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
                  title: 'Diamonds',
                  value: '${_userProfile!.totalDiamonds.toStringAsFixed(0)}💎',
                  icon: Icons.diamond,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Beans',
                  value: '${_userProfile!.totalBeans.toStringAsFixed(0)}🫘',
                  icon: Icons.coffee,
                  color: Colors.brown,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Sending Level',
                  value: 'Level ${_userProfile!.sendingLevel.level}',
                  icon: Icons.send,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Receiving Level',
                  value: 'Level ${_userProfile!.receivingLevel.level}',
                  icon: Icons.call_received,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Activity Summary
          const Text(
            'Activity Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildActivitySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Charts
          const Text(
            'Activity Charts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildActivityChart(),
          const SizedBox(height: 24),

          // Voice Room Activity
          const Text(
            'Voice Room Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildVoiceRoomStats(),
        ],
      ),
    );
  }

  Widget _buildLevelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sending Level
          const Text(
            'Sending Level Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelProgressCard(
            level: _userProfile!.sendingLevel,
            type: 'Sending',
            color: Colors.blue,
            icon: Icons.send,
          ),

          const SizedBox(height: 24),

          // Receiving Level
          const Text(
            'Receiving Level Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelProgressCard(
            level: _userProfile!.receivingLevel,
            type: 'Receiving',
            color: Colors.green,
            icon: Icons.call_received,
          ),

          const SizedBox(height: 24),

          // Level History
          const Text(
            'Level History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelHistoryChart(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final filteredHistory = _getFilteredHistory();
    
    return filteredHistory.isEmpty
        ? const Center(
            child: Text(
              'No history found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredHistory.length,
            itemBuilder: (context, index) {
              final entry = filteredHistory[index];
              return _buildHistoryEntryCard(entry);
            },
          );
  }

  Widget _buildUserProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[800]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            child: _userProfile!.profileImageUrl != null
                ? MediaPreviewWidget(
                    url: _userProfile!.profileImageUrl!,
                    width: 80,
                    height: 80,
                    borderRadius: BorderRadius.circular(40),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 40,
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile!.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getUserTypeDisplayName(_userProfile!.userType),
                  style: TextStyle(
                    color: _getUserTypeColor(_userProfile!.userType),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userProfile!.isHost && _userProfile!.agencyName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Agency: ${_userProfile!.agencyName}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Joined: ${_formatDate(_userProfile!.createdAt)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
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
                    fontSize: 20,
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

  Widget _buildActivitySummaryCard() {
    final stats = _userProfile!.activityStats;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildActivityRow('Diamonds Sent Today', '${stats.dailyDiamondsSent.toStringAsFixed(0)}💎', Colors.blue),
          const Divider(color: Colors.grey),
          _buildActivityRow('Diamonds Received Today', '${stats.dailyDiamondsReceived.toStringAsFixed(0)}💎', Colors.green),
          const Divider(color: Colors.grey),
          _buildActivityRow('Voice Room Time Today', '${stats.dailyVoiceRoomMinutes} min', Colors.purple),
          const Divider(color: Colors.grey),
          _buildActivityRow('Weekly Diamonds Sent', '${stats.weeklyDiamondsSent.toStringAsFixed(0)}💎', Colors.blue),
          const Divider(color: Colors.grey),
          _buildActivityRow('Monthly Diamonds Sent', '${stats.monthlyDiamondsSent.toStringAsFixed(0)}💎', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String label, String value, Color color) {
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
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Activity Chart\n(Chart library not available)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVoiceRoomStats() {
    final stats = _userProfile!.activityStats;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVoiceRoomStat('Today', '${stats.dailyVoiceRoomMinutes} min', Colors.purple),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildVoiceRoomStat('This Week', '${stats.weeklyVoiceRoomMinutes} min', Colors.purple),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[700],
              ),
              Expanded(
                child: _buildVoiceRoomStat('This Month', '${stats.monthlyVoiceRoomMinutes} min', Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRoomStat(String period, String value, Color color) {
    return Column(
      children: [
        Text(
          period,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgressCard({
    required UserLevel level,
    required String type,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                '$type Level ${level.level}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            level.levelName,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level.progressPercentage / 100,
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${level.currentProgress.toStringAsFixed(0)} / ${(level.currentProgress + level.requiredForNext).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                '${level.progressPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelHistoryChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Level History Chart\n(Chart library not available)',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHistoryEntryCard(UserHistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getHistoryTypeColor(entry.type).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getHistoryTypeIcon(entry.type),
              color: _getHistoryTypeColor(entry.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getHistoryTypeDisplayName(entry.type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (entry.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.description!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(entry.timestamp),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _getHistoryAmountText(entry),
            style: TextStyle(
              color: _getHistoryTypeColor(entry.type),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<UserHistoryEntry> _getFilteredHistory() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    return _historyEntries.where((entry) {
      switch (_selectedPeriod) {
        case 'Today':
          return entry.timestamp.isAfter(today);
        case 'This Week':
          return entry.timestamp.isAfter(weekStart);
        case 'This Month':
          return entry.timestamp.isAfter(monthStart);
        case 'All Time':
        default:
          return true;
      }
    }).toList();
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

  Color _getHistoryTypeColor(HistoryType type) {
    switch (type) {
      case HistoryType.diamondSent:
        return Colors.blue;
      case HistoryType.diamondReceived:
        return Colors.green;
      case HistoryType.beanEarned:
        return Colors.brown;
      case HistoryType.beanSpent:
        return Colors.orange;
      case HistoryType.voiceRoomTime:
        return Colors.purple;
      case HistoryType.levelUp:
        return Colors.amber;
      case HistoryType.itemPurchased:
        return Colors.cyan;
      case HistoryType.itemAssigned:
        return Colors.teal;
    }
  }

  IconData _getHistoryTypeIcon(HistoryType type) {
    switch (type) {
      case HistoryType.diamondSent:
        return Icons.send;
      case HistoryType.diamondReceived:
        return Icons.call_received;
      case HistoryType.beanEarned:
        return Icons.coffee;
      case HistoryType.beanSpent:
        return Icons.shopping_cart;
      case HistoryType.voiceRoomTime:
        return Icons.mic;
      case HistoryType.levelUp:
        return Icons.trending_up;
      case HistoryType.itemPurchased:
        return Icons.store;
      case HistoryType.itemAssigned:
        return Icons.card_giftcard;
    }
  }

  String _getHistoryTypeDisplayName(HistoryType type) {
    switch (type) {
      case HistoryType.diamondSent:
        return 'Diamond Sent';
      case HistoryType.diamondReceived:
        return 'Diamond Received';
      case HistoryType.beanEarned:
        return 'Bean Earned';
      case HistoryType.beanSpent:
        return 'Bean Spent';
      case HistoryType.voiceRoomTime:
        return 'Voice Room Time';
      case HistoryType.levelUp:
        return 'Level Up';
      case HistoryType.itemPurchased:
        return 'Item Purchased';
      case HistoryType.itemAssigned:
        return 'Item Assigned';
    }
  }

  String _getHistoryAmountText(UserHistoryEntry entry) {
    switch (entry.type) {
      case HistoryType.diamondSent:
      case HistoryType.diamondReceived:
        return '${entry.amount.toStringAsFixed(0)}💎';
      case HistoryType.beanEarned:
      case HistoryType.beanSpent:
        return '${entry.amount.toStringAsFixed(0)}🫘';
      case HistoryType.voiceRoomTime:
        return '${entry.amount.toStringAsFixed(0)} min';
      case HistoryType.levelUp:
        return 'Level ${entry.amount.toStringAsFixed(0)}';
      case HistoryType.itemPurchased:
      case HistoryType.itemAssigned:
        return '${entry.amount.toStringAsFixed(0)}💎';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
