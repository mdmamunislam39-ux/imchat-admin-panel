import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';
import '../widgets/media_preview_widget.dart';

class LevelSystemManagement extends StatefulWidget {
  const LevelSystemManagement({super.key});

  @override
  State<LevelSystemManagement> createState() => _LevelSystemManagementState();
}

class _LevelSystemManagementState extends State<LevelSystemManagement> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  List<UserProfileModel> _users = [];
  Map<String, dynamic> _levelStatistics = {};
  bool _isLoading = true;
  LevelType _selectedLevelType = LevelType.sending;
  final Map<String, List<Map<String, dynamic>>> _levelConfigurations = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      final users = await UserProfileService.getAllUserProfiles();
      await UserProfileService.getUserStatistics();
      await _loadLevelConfigurations();

      if (mounted) {
        setState(() {
          _users = users;
          _levelStatistics = _calculateLevelStatistics(users);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading level system data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load level system data');
      }
    }
  }

  Future<void> _loadLevelConfigurations() async {
    try {
      // Load sending, receiving and gifting level configurations
      final sendingDoc = await _firestore
          .collection('level_configurations')
          .doc('sending_config')
          .get();

      final receivingDoc = await _firestore
          .collection('level_configurations')
          .doc('receiving_config')
          .get();

      final giftingDoc = await _firestore
          .collection('level_configurations')
          .doc('gifting_config')
          .get();

      final roomDoc = await _firestore
          .collection('level_configurations')
          .doc('room_config')
          .get();

      if (sendingDoc.exists && sendingDoc.data() != null) {
        final data = sendingDoc.data()!;
        _levelConfigurations['sending'] = List<Map<String, dynamic>>.from(data['levels'] ?? []);
      }

      if (receivingDoc.exists && receivingDoc.data() != null) {
        final data = receivingDoc.data()!;
        _levelConfigurations['receiving'] = List<Map<String, dynamic>>.from(data['levels'] ?? []);
      }

      if (giftingDoc.exists && giftingDoc.data() != null) {
        final data = giftingDoc.data()!;
        _levelConfigurations['gifting'] = List<Map<String, dynamic>>.from(data['levels'] ?? []);
      }

      if (roomDoc.exists && roomDoc.data() != null) {
        final data = roomDoc.data()!;
        _levelConfigurations['room'] = List<Map<String, dynamic>>.from(data['levels'] ?? []);
      }

      debugPrint('Loaded level configurations: ${_levelConfigurations.keys}');
    } catch (e) {
      debugPrint('Error loading level configurations: $e');
    }
  }

  Map<String, dynamic> _calculateLevelStatistics(List<UserProfileModel> users) {
    int totalSendingLevels = 0;
    int totalReceivingLevels = 0;
    int totalGiftingLevels = 0;
    int maxSendingLevel = 0;
    int maxReceivingLevel = 0;
    int maxGiftingLevel = 0;
    double totalSendingProgress = 0;
    double totalReceivingProgress = 0;
    double totalGiftingProgress = 0;

    for (final user in users) {
      totalSendingLevels += user.sendingLevel.level;
      totalReceivingLevels += user.receivingLevel.level;
      totalGiftingLevels += user.giftingLevel.level;
      
      if (user.sendingLevel.level > maxSendingLevel) {
        maxSendingLevel = user.sendingLevel.level;
      }
      
      if (user.receivingLevel.level > maxReceivingLevel) {
        maxReceivingLevel = user.receivingLevel.level;
      }

      if (user.giftingLevel.level > maxGiftingLevel) {
        maxGiftingLevel = user.giftingLevel.level;
      }
      
      totalSendingProgress += user.sendingLevel.progressPercentage;
      totalReceivingProgress += user.receivingLevel.progressPercentage;
      totalGiftingProgress += user.giftingLevel.progressPercentage;
    }

    return {
      'totalUsers': users.length,
      'averageSendingLevel': users.isNotEmpty ? totalSendingLevels / users.length : 0,
      'averageReceivingLevel': users.isNotEmpty ? totalReceivingLevels / users.length : 0,
      'averageGiftingLevel': users.isNotEmpty ? totalGiftingLevels / users.length : 0,
      'maxSendingLevel': maxSendingLevel,
      'maxReceivingLevel': maxReceivingLevel,
      'maxGiftingLevel': maxGiftingLevel,
      'averageSendingProgress': users.isNotEmpty ? totalSendingProgress / users.length : 0,
      'averageReceivingProgress': users.isNotEmpty ? totalReceivingProgress / users.length : 0,
      'averageGiftingProgress': users.isNotEmpty ? totalGiftingProgress / users.length : 0,
    };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '⭐ Level System Management',
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
                _buildLevelTypeSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildLevelConfigTab(),
                      _buildUserLevelsTab(),
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
          Tab(icon: Icon(Icons.settings), text: 'Configuration'),
          Tab(icon: Icon(Icons.people), text: 'User Levels'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLevelConfigDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Configure Levels'),
      ),
    );
  }

  Widget _buildLevelTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Level Type:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildLevelTypeChip(
                    'Sending Levels',
                    LevelType.sending,
                    Icons.send,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLevelTypeChip(
                    'Receiving Levels',
                    LevelType.receiving,
                    Icons.call_received,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLevelTypeChip(
                    'Gifting Levels',
                    LevelType.gifting,
                    Icons.card_giftcard,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildLevelTypeChip(
                    'Room Levels',
                    LevelType.room,
                    Icons.mic,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTypeChip(String label, LevelType type, IconData icon, Color color) {
    final isSelected = _selectedLevelType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLevelType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.grey[800],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
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
          // Level Statistics
          const Text(
            'Level System Statistics',
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
                  value: _levelStatistics['totalUsers']?.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Sending Level',
                  value: '${(_levelStatistics['averageSendingLevel'] ?? 0.0).toStringAsFixed(1)}',
                  icon: Icons.send,
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
                  title: 'Avg Receiving Level',
                  value: '${(_levelStatistics['averageReceivingLevel'] ?? 0.0).toStringAsFixed(1)}',
                  icon: Icons.call_received,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Max Sending Level',
                  value: '${_levelStatistics['maxSendingLevel'] ?? 0}',
                  icon: Icons.trending_up,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Max Receiving Level',
                  value: '${_levelStatistics['maxReceivingLevel'] ?? 0}',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Avg Progress',
                  value: '${(_levelStatistics['averageSendingProgress'] ?? 0.0).toStringAsFixed(1)}%',
                  icon: Icons.analytics,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Level Distribution Chart
          const Text(
            'Level Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelDistributionChart(),

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
                  title: 'Configure Sending Levels',
                  subtitle: 'Set up sending level requirements',
                  icon: Icons.send,
                  color: Colors.blue,
                  onTap: () {
                    setState(() {
                      _selectedLevelType = LevelType.sending;
                    });
                    _tabController.animateTo(1);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Configure Receiving Levels',
                  subtitle: 'Set up receiving level requirements',
                  icon: Icons.call_received,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedLevelType = LevelType.receiving;
                    });
                    _tabController.animateTo(1);
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
                  title: 'View User Levels',
                  subtitle: 'Check individual user levels',
                  icon: Icons.people,
                  color: Colors.purple,
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  title: 'Level Analytics',
                  subtitle: 'View detailed level analytics',
                  icon: Icons.analytics,
                  color: Colors.orange,
                  onTap: _showLevelAnalytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Configuration
          Text(
            '${_getLevelTypeDisplayName(_selectedLevelType)} Configuration',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelConfigCard(),

          const SizedBox(height: 24),

          // Level Requirements
          const Text(
            'Level Requirements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildLevelRequirementsList(),

          const SizedBox(height: 24),

          // Custom Level Images
          const Text(
            'Custom Level Images',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildCustomLevelImagesCard(),
        ],
      ),
    );
  }

  Widget _buildUserLevelsTab() {
    if (_selectedLevelType == LevelType.room) {
      return const Center(
        child: Text(
          'Room levels are not associated with individual users.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final sortedUsers = List<UserProfileModel>.from(_users);
    sortedUsers.sort((a, b) {
      if (_selectedLevelType == LevelType.sending) {
        return b.sendingLevel.level.compareTo(a.sendingLevel.level);
      } else if (_selectedLevelType == LevelType.gifting) {
        return b.giftingLevel.level.compareTo(a.giftingLevel.level);
      } else {
        return b.receivingLevel.level.compareTo(a.receivingLevel.level);
      }
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        return _buildUserLevelCard(user);
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
                    fontSize: 24,
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

  Widget _buildLevelDistributionChart() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${_getLevelTypeDisplayName(_selectedLevelType)} Distribution',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildLevelBars(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBars() {
    if (_selectedLevelType == LevelType.room) {
      return const Center(
        child: Text(
          'No distribution data available for room levels.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final levelCounts = <int, int>{};
    
    for (final user in _users) {
      final level = _selectedLevelType == LevelType.sending 
          ? user.sendingLevel.level 
          : _selectedLevelType == LevelType.gifting
              ? user.giftingLevel.level
              : user.receivingLevel.level;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    final maxCount = levelCounts.values.isNotEmpty ? levelCounts.values.reduce((a, b) => a > b ? a : b) : 1;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: levelCounts.length,
      itemBuilder: (context, index) {
        final level = levelCounts.keys.elementAt(index);
        final count = levelCounts[level]!;
        final height = (count / maxCount) * 200;

        return Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: height,
                width: 30,
                decoration: BoxDecoration(
                  color: _selectedLevelType == LevelType.sending ? Colors.blue : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'L$level',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelConfigCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedLevelType == LevelType.sending ? Colors.blue : Colors.green,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_selectedLevelType == LevelType.sending ? Colors.blue : Colors.green).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedLevelType == LevelType.sending ? Icons.send : Icons.call_received,
                  color: _selectedLevelType == LevelType.sending ? Colors.blue : Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getLevelTypeDisplayName(_selectedLevelType),
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
            _getLevelTypeDescription(_selectedLevelType),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showEditLevelConfigDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Configuration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLevelType == LevelType.sending ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLevelImageDialog('Level 1', LevelType.sending),
                  icon: const Icon(Icons.image),
                  label: const Text('Custom Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRequirementsList() {
    final requirements = _getLevelRequirements(_selectedLevelType);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: requirements.asMap().entries.map((entry) {
          final index = entry.key;
          final requirement = entry.value;
          final isLast = index == requirements.length - 1;
          
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getLevelColor(index + 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _getLevelImageUrl(_selectedLevelType, index + 1) != null
                        ? MediaPreviewWidget(
                            url: _getLevelImageUrl(_selectedLevelType, index + 1)!,
                            width: 40,
                            height: 40,
                            borderRadius: BorderRadius.circular(20),
                          )
                        : Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Requires ${requirement.toStringAsFixed(0)} diamonds',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${requirement.toStringAsFixed(0)}💎',
                    style: TextStyle(
                      color: _getLevelColor(index + 1),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isLast) const Divider(color: Colors.grey),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomLevelImagesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Custom Level Images',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload custom images for each level to make them more visually appealing.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showLevelImageDialog('Level 1', LevelType.sending),
            icon: const Icon(Icons.upload),
            label: const Text('Upload Level Images'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserLevelCard(UserProfileModel user) {
    final level = _selectedLevelType == LevelType.sending 
        ? user.sendingLevel 
        : _selectedLevelType == LevelType.receiving
            ? user.receivingLevel
            : user.giftingLevel;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getLevelColor(level.level),
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
                  backgroundColor: _getLevelColor(level.level).withValues(alpha: 0.2),
                  child: user.profileImageUrl != null
                      ? MediaPreviewWidget(
                          url: user.profileImageUrl!,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(25),
                        )
                      : Icon(
                          Icons.person,
                          color: _getLevelColor(level.level),
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
                        '${_getLevelTypeDisplayName(_selectedLevelType)} Level ${level.level}',
                        style: TextStyle(
                          color: _getLevelColor(level.level),
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
                    color: _getLevelColor(level.level),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Level ${level.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (level.customImageUrl != null) ...[
                  const SizedBox(width: 8),
                  MediaPreviewWidget(
                    url: level.customImageUrl!,
                    width: 32,
                    height: 32,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Next Level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${level.progressPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getLevelColor(level.level),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: level.progressPercentage / 100,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor(level.level)),
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
                      '${level.requiredForNext.toStringAsFixed(0)} more needed',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUserLevelDetails(user),
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
                    onPressed: () => _showEditUserLevel(user),
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
                    onPressed: () => _showLevelHistory(user),
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
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

  String _getLevelTypeDisplayName(LevelType type) {
    switch (type) {
      case LevelType.sending:
        return 'Sending Levels';
      case LevelType.receiving:
        return 'Receiving Levels';
      case LevelType.gifting:
        return 'Gifting Levels';
      case LevelType.room:
        return 'Room Levels';
    }
  }

  String _getLevelTypeDescription(LevelType type) {
    switch (type) {
      case LevelType.sending:
        return 'Levels based on the total amount of diamonds sent to other users. Higher levels require more diamonds sent.';
      case LevelType.receiving:
        return 'Levels based on the total amount of diamonds received from other users. Higher levels require more diamonds received.';
      case LevelType.gifting:
        return 'Levels based on the total value of gifts sent in voice rooms. Higher levels represent more generous gifters.';
      case LevelType.room:
        return 'Levels based on the total revenue generated by the voice room.';
    }
  }

  List<double> _getLevelRequirements(LevelType type) {
    // If we have custom configurations, use them to define the number of levels
    // The actual values will be populated from _levelConfigurations
    if (_levelConfigurations[type.name] != null && _levelConfigurations[type.name]!.isNotEmpty) {
      return List.generate(
        _levelConfigurations[type.name]!.length,
        (i) => (_levelConfigurations[type.name]![i]['diamondRequirement'] ?? 1000).toDouble()
      );
    }
    
    // Default fallback values
    switch (type) {
      case LevelType.sending:
        return [1000, 5000, 10000, 50000, 100000];
      case LevelType.receiving:
        return [500, 2000, 5000, 20000, 50000];
      case LevelType.gifting:
        return [100, 500, 1000, 5000, 10000];
      case LevelType.room:
        return [5000, 10000, 15000, 20000, 25000];
    }
  }

  String? _getLevelImageUrl(LevelType type, int level) {
    final typeKey = type.name;
    final configs = _levelConfigurations[typeKey];
    
    if (configs != null && configs.isNotEmpty) {
      final sortedConfigs = List<Map<String, dynamic>>.from(configs);
      sortedConfigs.sort((a, b) => (a['levelNumber'] ?? 0).compareTo(b['levelNumber'] ?? 0));
      
      if (level - 1 < sortedConfigs.length) {
        return sortedConfigs[level - 1]['imageUrl'];
      }
    }
    
    return null;
  }

  Color _getLevelColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.blue;
    if (level <= 10) return Colors.purple;
    if (level <= 15) return Colors.orange;
    return Colors.red;
  }

  // Dialog Methods
  void _showLevelConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => LevelConfigDialog(
        levelType: _selectedLevelType,
        onConfigUpdated: () {
          _loadData();
          _showSuccessSnackBar('Level configuration updated');
        },
      ),
    );
  }

  void _showEditLevelConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Edit Level Configuration',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configure level requirements and rewards',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildLevelConfigForm(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Level configuration updated successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save Configuration'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelConfigForm() {
    return Column(
      children: [
        // Sending Level Configuration
        _buildLevelTypeSection('Sending Levels', LevelType.sending),
        const SizedBox(height: 20),
        // Receiving Level Configuration  
        _buildLevelTypeSection('Receiving Levels', LevelType.receiving),
        const SizedBox(height: 20),
        // Gifting Level Configuration
        _buildLevelTypeSection('Gifting Levels', LevelType.gifting),
        const SizedBox(height: 20),
        // Room Level Configuration
        _buildLevelTypeSection('Room Levels', LevelType.room),
      ],
    );
  }

  Widget _buildLevelTypeSection(String title, LevelType type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLevelRequirementInput('Level 1', '0 - 1000', type),
          _buildLevelRequirementInput('Level 2', '1001 - 5000', type),
          _buildLevelRequirementInput('Level 3', '5001 - 10000', type),
          _buildLevelRequirementInput('Level 4', '10001 - 25000', type),
          _buildLevelRequirementInput('Level 5', '25001+', type),
        ],
      ),
    );
  }

  Widget _buildLevelRequirementInput(String level, String range, LevelType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              level,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              range,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: () => _showLevelImageDialog(level, type),
            icon: const Icon(Icons.image, color: Colors.blue, size: 16),
            tooltip: 'Set custom image',
          ),
        ],
      ),
    );
  }

  void _showLevelImageDialog(String level, LevelType type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Set Image for $level',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload a custom image for this level',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, color: Colors.grey, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _selectLevelImage(level, type),
                    icon: const Icon(Icons.upload),
                    label: const Text('Select Image'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Level image updated successfully');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Save Image'),
          ),
        ],
      ),
    );
  }

  void _selectLevelImage(String level, LevelType type) async {
    try {
      // TODO: Implement file picker for level images
      _showSuccessSnackBar('Image selection feature coming soon');
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  void _showLevelAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Level Analytics',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              _buildAnalyticsChart('Sending Level Distribution', _getSendingLevelStats()),
              const SizedBox(height: 20),
              _buildAnalyticsChart('Receiving Level Distribution', _getReceivingLevelStats()),
              const SizedBox(height: 20),
              _buildAnalyticsChart('Gifting Level Distribution', _getGiftingLevelStats()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart(String title, Map<String, int> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) => _buildLevelBar(entry.key, entry.value, data.values.reduce((a, b) => a + b))),
        ],
      ),
    );
  }

  Widget _buildLevelBar(String level, int count, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              level,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Map<String, int> _getSendingLevelStats() {
    final stats = <String, int>{};
    for (final user in _users) {
      final level = 'Level ${user.sendingLevel.level}';
      stats[level] = (stats[level] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _getReceivingLevelStats() {
    final stats = <String, int>{};
    for (final user in _users) {
      final level = 'Level ${user.receivingLevel.level}';
      stats[level] = (stats[level] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _getGiftingLevelStats() {
    final stats = <String, int>{};
    for (final user in _users) {
      final level = 'Level ${user.giftingLevel.level}';
      stats[level] = (stats[level] ?? 0) + 1;
    }
    return stats;
  }

  void _showUserLevelDetails(UserProfileModel user) {
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
                    'Level Details',
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
              _buildLevelDetailsCard('Sending Level', user.sendingLevel),
              const SizedBox(height: 16),
              _buildLevelDetailsCard('Receiving Level', user.receivingLevel),
              const SizedBox(height: 16),
              _buildLevelDetailsCard('Gifting Level', user.giftingLevel),
              const SizedBox(height: 16),
              _buildActivityStatsCard(user),
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
              _showEditUserLevel(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Edit Levels'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelDetailsCard(String title, UserLevel level) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${level.level}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      level.levelName,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (level.customImageUrl != null)
                MediaPreviewWidget(
                  url: level.customImageUrl!,
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Progress: ${level.currentProgress.toStringAsFixed(0)} / ${level.requiredForNext.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level.progressPercentage / 100,
            backgroundColor: Colors.grey[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            '${level.progressPercentage.toStringAsFixed(1)}% Complete',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatsCard(UserProfileModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Statistics',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildStatRow('💎 Total Diamonds', user.totalDiamonds.toStringAsFixed(0)),
          _buildStatRow('📤 Diamonds Sent', user.diamondsSent.toStringAsFixed(0)),
          _buildStatRow('📥 Diamonds Received', user.diamondsReceived.toStringAsFixed(0)),
          _buildStatRow('📊 Daily Sent', user.activityStats.dailyDiamondsSent.toStringAsFixed(0)),
          _buildStatRow('📊 Daily Received', user.activityStats.dailyDiamondsReceived.toStringAsFixed(0)),
          _buildStatRow('📈 Weekly Sent', user.activityStats.weeklyDiamondsSent.toStringAsFixed(0)),
          _buildStatRow('📈 Weekly Received', user.activityStats.weeklyDiamondsReceived.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showEditUserLevel(UserProfileModel user) {
    final sendingLevelController = TextEditingController(text: user.sendingLevel.level.toString());
    final receivingLevelController = TextEditingController(text: user.receivingLevel.level.toString());
    final giftingLevelController = TextEditingController(text: user.giftingLevel.level.toString());
    final sendingProgressController = TextEditingController(text: user.sendingLevel.currentProgress.toString());
    final receivingProgressController = TextEditingController(text: user.receivingLevel.currentProgress.toString());
    final giftingProgressController = TextEditingController(text: user.giftingLevel.currentProgress.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit ${user.username}\'s Levels',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Modify user level settings',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildLevelEditSection('Sending Level', sendingLevelController, sendingProgressController),
              const SizedBox(height: 16),
              _buildLevelEditSection('Receiving Level', receivingLevelController, receivingProgressController),
              const SizedBox(height: 16),
              _buildLevelEditSection('Gifting Level', giftingLevelController, giftingProgressController),
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
                final updatedSendingLevel = user.sendingLevel.copyWith(
                  level: int.tryParse(sendingLevelController.text) ?? user.sendingLevel.level,
                  currentProgress: double.tryParse(sendingProgressController.text) ?? user.sendingLevel.currentProgress,
                  lastUpdated: DateTime.now(),
                );
                
                final updatedReceivingLevel = user.receivingLevel.copyWith(
                  level: int.tryParse(receivingLevelController.text) ?? user.receivingLevel.level,
                  currentProgress: double.tryParse(receivingProgressController.text) ?? user.receivingLevel.currentProgress,
                  lastUpdated: DateTime.now(),
                );
                
                final updatedGiftingLevel = user.giftingLevel.copyWith(
                  level: int.tryParse(giftingLevelController.text) ?? user.giftingLevel.level,
                  currentProgress: double.tryParse(giftingProgressController.text) ?? user.giftingLevel.currentProgress,
                  lastUpdated: DateTime.now(),
                );

                final updatedUser = user.copyWith(
                  sendingLevel: updatedSendingLevel,
                  receivingLevel: updatedReceivingLevel,
                  giftingLevel: updatedGiftingLevel,
                  updatedAt: DateTime.now(),
                );

                await UserProfileService.updateUserProfile(updatedUser);
                
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
                _showSuccessSnackBar('User levels updated successfully');
              } catch (e) {
                if (!mounted) return;
                _showErrorSnackBar('Error updating user levels: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelEditSection(String title, TextEditingController levelController, TextEditingController progressController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: levelController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Level Number',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: progressController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Current Progress',
              labelStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelHistory(UserProfileModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          '${user.username}\'s Level History',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              _buildHistorySection('Sending Level History', _getSendingLevelHistory(user)),
              const SizedBox(height: 16),
              _buildHistorySection('Receiving Level History', _getReceivingLevelHistory(user)),
              const SizedBox(height: 16),
              _buildHistorySection('Gifting Level History', _getGiftingLevelHistory(user)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String title, List<Map<String, dynamic>> history) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: history.isEmpty 
                ? const Center(
                    child: Text(
                      'No history available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return _buildHistoryEntry(entry);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryEntry(Map<String, dynamic> entry) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['description'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  entry['date'],
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            entry['change'],
            style: TextStyle(
              color: entry['positive'] ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSendingLevelHistory(UserProfileModel user) {
    // Mock history data - in real implementation, this would come from Firebase
    return [
      {
        'description': 'Level up to ${user.sendingLevel.level}',
        'date': _formatDate(user.sendingLevel.lastUpdated),
        'change': '+1 Level',
        'positive': true,
      },
      {
        'description': 'Diamonds sent: ${user.diamondsSent.toStringAsFixed(0)}',
        'date': _formatDate(user.updatedAt),
        'change': '+${user.diamondsSent.toStringAsFixed(0)} 💎',
        'positive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getReceivingLevelHistory(UserProfileModel user) {
    // Mock history data - in real implementation, this would come from Firebase
    return [
      {
        'description': 'Level up to ${user.receivingLevel.level}',
        'date': _formatDate(user.receivingLevel.lastUpdated),
        'change': '+1 Level',
        'positive': true,
      },
      {
        'description': 'Diamonds received: ${user.diamondsReceived.toStringAsFixed(0)}',
        'date': _formatDate(user.updatedAt),
        'change': '+${user.diamondsReceived.toStringAsFixed(0)} 💎',
        'positive': true,
      },
    ];
  }

  List<Map<String, dynamic>> _getGiftingLevelHistory(UserProfileModel user) {
    // Mock history data - in real implementation, this would come from Firebase
    return [
      {
        'description': 'Level up to ${user.giftingLevel.level}',
        'date': _formatDate(user.giftingLevel.lastUpdated),
        'change': '+1 Level',
        'positive': true,
      },
      {
        'description': 'Total gifted: ${user.totalDiamonds.toStringAsFixed(0)}',
        'date': _formatDate(user.updatedAt),
        'change': '+${user.totalDiamonds.toStringAsFixed(0)} 💎',
        'positive': true,
      },
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class LevelConfigDialog extends StatefulWidget {
  final LevelType levelType;
  final VoidCallback onConfigUpdated;

  const LevelConfigDialog({
    super.key,
    required this.levelType,
    required this.onConfigUpdated,
  });

  @override
  State<LevelConfigDialog> createState() => _LevelConfigDialogState();
}

class _LevelConfigDialogState extends State<LevelConfigDialog> {
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<String?> _levelImages = []; // Store image URLs
  final List<Uint8List?> _selectedImageBytes = []; // Store selected image bytes for web compatibility
  bool _isUploading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingConfiguration();
  }

  Future<void> _loadExistingConfiguration() async {
    try {
      final doc = await _firestore
          .collection('level_configurations')
          .doc('${widget.levelType.name}_config')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final levels = data['levels'] as List<dynamic>? ?? [];
        
        debugPrint('Found ${levels.length} levels in Firebase');
        
        if (levels.isNotEmpty) {
          // Clear existing controllers
          for (final controller in _controllers) {
            controller.dispose();
          }
          for (final focusNode in _focusNodes) {
            focusNode.dispose();
          }
          _controllers.clear();
          _focusNodes.clear();
          _levelImages.clear();
          _selectedImageBytes.clear();

          // Load existing configuration
          for (final level in levels) {
            final levelData = level as Map<String, dynamic>;
            final imageUrl = levelData['imageUrl'];
            debugPrint('Loading level ${levelData['levelNumber']}: imageUrl = $imageUrl');
            
            _controllers.add(TextEditingController(
              text: (levelData['diamondRequirement'] ?? 1000).toString(),
            ));
            _focusNodes.add(FocusNode());
            _levelImages.add(imageUrl);
            _selectedImageBytes.add(null);
          }

          setState(() {});
          _showSuccessSnackBar('Loaded existing level configuration');
        }
      } else {
        debugPrint('No existing configuration found in Firebase');
      }
    } catch (e) {
      debugPrint('Error loading existing configuration: $e');
      // Continue with default configuration if loading fails
    }
  }

  void _initializeControllers() {
    final requirements = _getLevelRequirements(widget.levelType);
    debugPrint('Initializing controllers with ${requirements.length} levels');
    for (int i = 0; i < requirements.length; i++) {
      _controllers.add(TextEditingController(text: requirements[i].toStringAsFixed(0)));
      _focusNodes.add(FocusNode());
      _levelImages.add(null);
      _selectedImageBytes.add(null);
    }
    debugPrint('Initialized _levelImages length: ${_levelImages.length}');
    debugPrint('Initialized _levelImages: $_levelImages');
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addNewLevel() {
    setState(() {
      _controllers.add(TextEditingController(text: '1000'));
      _focusNodes.add(FocusNode());
      _levelImages.add(null);
      _selectedImageBytes.add(null);
    });
    debugPrint('Added new level. _levelImages length: ${_levelImages.length}');
    debugPrint('_levelImages list: $_levelImages');
  }

  void _removeLevel(int index) {
    if (_controllers.length > 1) {
      setState(() {
        _controllers[index].dispose();
        _focusNodes[index].dispose();
        _controllers.removeAt(index);
        _focusNodes.removeAt(index);
        _levelImages.removeAt(index);
        _selectedImageBytes.removeAt(index);
      });
    }
  }

  Future<void> _selectLevelImage(int levelIndex) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes != null) {
          setState(() {
            _selectedImageBytes[levelIndex] = bytes;
          });
          
          // Upload to Firebase Storage
          await _uploadLevelImage(levelIndex, bytes);
        } else {
          _showErrorSnackBar('Failed to read image data');
        }
      }
    } catch (e) {
      debugPrint('Error selecting image: $e');
      _showErrorSnackBar('Error selecting image: $e');
    }
  }

  Future<void> _uploadLevelImage(int levelIndex, Uint8List imageBytes) async {
    try {
      setState(() {
        _isUploading = true;
      });

      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child(
        'level_images/${widget.levelType.name}/level_${levelIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );

      final uploadTask = await ref.putData(imageBytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        _levelImages[levelIndex] = downloadUrl;
        _isUploading = false;
      });

      debugPrint('Image uploaded successfully for level ${levelIndex + 1}: $downloadUrl');
      debugPrint('_levelImages list length: ${_levelImages.length}');
      debugPrint('_levelImages list: $_levelImages');
      debugPrint('_levelImages[$levelIndex]: ${_levelImages[levelIndex]}');
      _showSuccessSnackBar('Level image uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Error uploading image: $e');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Configure ${_getLevelTypeDisplayName(widget.levelType)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Level Requirements',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_controllers.length, (index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getLevelColor(index + 1), width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getLevelColor(index + 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Level ${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Diamond Requirement',
                                          labelStyle: const TextStyle(color: Colors.grey),
                                          filled: true,
                                          fillColor: Colors.grey[700],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          suffixText: '💎',
                                          suffixStyle: const TextStyle(color: Colors.cyan),
                                        ),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Image preview and upload button
                                Column(
                                  children: [
                                    // Image preview
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[700],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[600]!),
                                      ),
                                      child: _levelImages[index] != null
                                          ? MediaPreviewWidget(
                                              url: _levelImages[index]!,
                                              width: 60,
                                              height: 60,
                                              borderRadius: BorderRadius.circular(8),
                                            )
                                          : _selectedImageBytes[index] != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    _selectedImageBytes[index]!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                  size: 24,
                                                ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Upload button
                                    SizedBox(
                                      width: 60,
                                      child: ElevatedButton.icon(
                                        onPressed: _isUploading ? null : () => _selectLevelImage(index),
                                        icon: _isUploading 
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.upload, size: 12),
                                        label: const Text('', style: TextStyle(fontSize: 8)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                          minimumSize: const Size(0, 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // Remove level button (only show if more than 1 level)
                                if (_controllers.length > 1)
                                  IconButton(
                                    onPressed: () => _removeLevel(index),
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    tooltip: 'Remove Level',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    // Add new level button
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: _addNewLevel,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Level'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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
                    onPressed: _saveConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Configuration'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    try {
      // Validate all level requirements
      for (int i = 0; i < _controllers.length; i++) {
        final requirement = double.tryParse(_controllers[i].text);
        if (requirement == null || requirement < 0) {
          _showErrorSnackBar('Please enter valid diamond requirements for all levels');
          return;
        }
      }

      // Prepare level configuration data
      final now = DateTime.now();
      final levelConfig = {
        'levelType': widget.levelType.name,
        'levels': <Map<String, dynamic>>[],
        'createdAt': now,
        'updatedAt': now,
      };

      // Add each level configuration
      final levelsList = <Map<String, dynamic>>[];
      debugPrint('_levelImages list length: ${_levelImages.length}');
      debugPrint('_levelImages list content: ${_levelImages.length}');
      
      for (int i = 0; i < _controllers.length; i++) {
        final imageUrl = i < _levelImages.length ? _levelImages[i] : null;
        debugPrint('Level ${i + 1} image URL: $imageUrl (index $i)');
        
        final levelData = {
          'levelNumber': i + 1,
          'diamondRequirement': double.parse(_controllers[i].text),
          'imageUrl': imageUrl, // This will be null if no image was uploaded
          'createdAt': now,
        };
        levelsList.add(levelData);
      }
      levelConfig['levels'] = levelsList;

      // Save to Firebase Firestore
      debugPrint('Saving to Firebase: $levelConfig');
      await _firestore
          .collection('level_configurations')
          .doc('${widget.levelType.name}_config')
          .set(levelConfig, SetOptions(merge: true));

      debugPrint('Level configuration saved to Firebase:');
      for (int i = 0; i < _controllers.length; i++) {
        debugPrint('Level ${i + 1}: ${_controllers[i].text} diamonds, Image: ${_levelImages[i] ?? 'None'}');
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onConfigUpdated();
      _showSuccessSnackBar('Level configuration saved successfully');
    } catch (e) {
      debugPrint('Error saving configuration: $e');
      _showErrorSnackBar('Error saving configuration: $e');
    }
  }

  String _getLevelTypeDisplayName(LevelType type) {
    switch (type) {
      case LevelType.sending:
        return 'Sending Levels';
      case LevelType.receiving:
        return 'Receiving Levels';
      case LevelType.gifting:
        return 'Gifting Levels';
      case LevelType.room:
        return 'Room Levels';
    }
  }

  List<double> _getLevelRequirements(LevelType type) {
    // For the dialog, we'll use default values since we load from Firebase in initState
    switch (type) {
      case LevelType.sending:
        return [1000, 5000, 15000, 50000, 100000, 500000, 1000000];
      case LevelType.receiving:
        return [200, 1000, 5000, 15000, 50000, 100000, 500000];
      case LevelType.gifting:
        return [500, 2500, 10000, 30000, 75000, 200000, 500000];
      case LevelType.room:
        return [5000, 10000, 15000, 20000, 25000, 30000, 50000];
    }
  }

  Color _getLevelColor(int level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.blue;
    if (level <= 10) return Colors.purple;
    if (level <= 15) return Colors.orange;
    return Colors.red;
  }
}
