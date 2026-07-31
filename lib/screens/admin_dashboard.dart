import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/firebase_data_service.dart';
import 'users_management.dart';
import 'rooms_management.dart';
import 'gift_management.dart';
import 'emoji_management.dart';
import 'diamonds_management.dart';
import 'reports_analytics.dart';
import 'settings_screen.dart';
import 'agency_management.dart';
import 'commission_management.dart';
import 'seller_management.dart';
import 'store_management.dart';
import 'user_profile_management.dart';
import 'daily_checkin_management.dart';
import 'market_management.dart';
import 'user_history_stats.dart';
import 'blocked_users_management.dart';
import 'user_ban_management_screen.dart';
import 'room_ban_management_screen.dart';
import 'level_system_management.dart';
import 'host_agency_management.dart';
import 'gift_transactions_screen.dart';
import 'withdrawal_management.dart';
import 'official_items_screen.dart';
import 'banner_management_screen.dart';
import 'official_channels_screen.dart';
import 'event_management_screen.dart';
import 'room_event_portal_management.dart';
import 'game_management_screen.dart';
import 'fruit_wheel_game_screen.dart';
import 'room_id_customization_screen.dart';
import 'super_admin_management_screen.dart';
import 'svip_management_screen.dart';
import 'device_management_screen.dart';
import 'add_store_item_screen.dart';
import 'feedback_management_screen.dart';
import 'family_management_screen.dart';
import '../models/admin_permission_model.dart';
import '../services/admin_permission_service.dart';
import '../services/admin_auth_service.dart';
import 'admin_accounts_screen.dart';
import 'login_screen.dart';
import 'invitation_reward_screen.dart';
import 'app_theme_management_screen.dart';
import 'family_level_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Statistics
  int _totalUsers = 0;
  int _totalRooms = 0;
  int _totalGifts = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Load real statistics from Firebase
      final stats = await FirebaseDataService.getSystemStatistics();
      
      if (!mounted) return;
      setState(() {
        _totalUsers = stats['totalUsers'] ?? 0;
        _totalRooms = stats['totalRooms'] ?? 0;
        _totalGifts = stats['totalGifts'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'IMChat Admin Panel',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
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
          // Enhanced Header with Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue, Colors.purple],
              ),
            ),
            child: const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IMChat Admin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Management Panel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Dashboard
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // User Management Section
          if (_hasPermission('Users Management') || _hasPermission('User Profiles') || _hasPermission('Hosts & Agencies') || _hasPermission('Blocked Users') || _hasPermission('Family Management'))
            _buildSectionHeader('👥 USER MANAGEMENT'),
          if (_hasPermission('Users Management'))
            _buildDrawerItem(
              icon: Icons.people,
              title: 'Users',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Users Management');
              },
            ),
          if (_hasPermission('User Profiles'))
            _buildDrawerItem(
              icon: Icons.person,
              title: 'User Profiles',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('User Profile Management');
              },
            ),
          if (_hasPermission('Hosts & Agencies'))
            _buildDrawerItem(
              icon: Icons.mic,
              title: 'Hosts & Agencies',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Host Agency Management');
              },
            ),
          if (_hasPermission('Blocked Users'))
            _buildDrawerItem(
              icon: Icons.block,
              title: 'Blocked Users',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Blocked Users Management');
              },
            ),
          if (_hasPermission('Blocked Users')) // Using same permission for now
            _buildDrawerItem(
              icon: Icons.gavel,
              title: 'Ban Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Ban Management');
              },
            ),
          if (_hasPermission('Blocked Users')) // Using same permission for now
            _buildDrawerItem(
              icon: Icons.no_meeting_room,
              title: 'Room Bans',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Room Ban Management');
              },
            ),
          if (_hasPermission('Family Management'))
            _buildDrawerItem(
              icon: Icons.family_restroom,
              title: 'Family Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Family Management');
              },
            ),
          if (_hasPermission('Family Management'))
            _buildDrawerItem(
              icon: Icons.star_border_purple500,
              title: 'Family Levels',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Family Levels');
              },
            ),

          // Content & Store Section
          if (_hasPermission('Banner Management') || _hasPermission('Event Management') || _hasPermission('Official Channels') || _hasPermission('Market Management') || _hasPermission('Gifts Management') || _hasPermission('Emojis Management'))
            _buildSectionHeader('🛍️ CONTENT & STORE'),
          if (_hasPermission('Banner Management'))
            _buildDrawerItem(
              icon: Icons.view_carousel,
              title: 'Banner Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Banner Management');
              },
            ),
          if (_hasPermission('Event Management'))
            _buildDrawerItem(
              icon: Icons.event,
              title: 'Event Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Event Management');
              },
            ),
          if (_hasPermission('Event Management')) // Room Event Portal falls under Event Management
            _buildDrawerItem(
              icon: Icons.app_shortcut,
              title: 'Room Event Portal',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Room Event Portal');
              },
            ),
          if (_hasPermission('Official Channels'))
            _buildDrawerItem(
              icon: Icons.campaign,
              title: 'Official Channels',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Official Channels');
              },
            ),
          if (_hasPermission('Market Management'))
            _buildDrawerItem(
              icon: Icons.storefront,
              title: 'Market Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Market Management');
              },
            ),
          if (_hasPermission('Market Management'))
            _buildDrawerItem(
              icon: Icons.add_box,
              title: '🪑 Add Store Item',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Add Store Item');
              },
            ),
          if (_hasPermission('Gifts Management'))
            _buildDrawerItem(
              icon: Icons.card_giftcard,
              title: 'Gifts',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Gifts Management');
              },
            ),
          if (_hasPermission('Emojis Management'))
            _buildDrawerItem(
              icon: Icons.emoji_emotions,
              title: 'Emojis',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Emojis Management');
              },
            ),

          // Levels & Progression Section
          if (_hasPermission('Level System') || _hasPermission('User History & Stats') || _hasPermission('SVIP Management'))
            _buildSectionHeader('⭐ LEVELS & PROGRESSION'),
          if (_hasPermission('Level System'))
            _buildDrawerItem(
              icon: Icons.trending_up,
              title: 'Level System',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Level System Management');
              },
            ),
          if (_hasPermission('User History & Stats'))
            _buildDrawerItem(
              icon: Icons.history,
              title: 'User History & Stats',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('User History Stats');
              },
            ),
          if (_hasPermission('SVIP Management'))
            _buildDrawerItem(
              icon: Icons.star_border,
              title: 'SVIP Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('SVIP Management');
              },
            ),

          // Business & Analytics Section
          if (_hasPermission('Agency Management') || _hasPermission('Seller Management') || _hasPermission('Commission Management') || _hasPermission('Official Items') || _hasPermission('Gift Economy') || _hasPermission('Withdrawal Management') || _hasPermission('Diamonds Management') || _hasPermission('Daily Check-in') || _hasPermission('Reports & Analytics'))
            _buildSectionHeader('💼 BUSINESS & ANALYTICS'),
          if (_hasPermission('Agency Management'))
            _buildDrawerItem(
              icon: Icons.business,
              title: 'Agency Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Agency Management');
              },
            ),
          if (_hasPermission('Seller Management'))
            _buildDrawerItem(
              icon: Icons.store,
              title: 'Seller Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Seller Management');
              },
            ),
          if (_hasPermission('Commission Management'))
            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              title: 'Commission Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Commission Management');
              },
            ),
          if (_hasPermission('Official Items'))
            _buildDrawerItem(
              icon: Icons.verified,
              title: 'Official Items',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Official Items');
              },
            ),
          if (_hasPermission('Gift Economy'))
            _buildDrawerItem(
              icon: Icons.card_giftcard,
              title: 'Gift Economy',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Gift Economy');
              },
            ),
          if (_hasPermission('Withdrawal Management'))
            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              title: 'Withdrawals',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Withdrawal Management');
              },
            ),
          if (_hasPermission('Diamonds Management'))
            _buildDrawerItem(
              icon: Icons.monetization_on,
              title: 'Diamonds Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Diamonds Management');
              },
            ),
          if (_hasPermission('Daily Check-in'))
            _buildDrawerItem(
              icon: Icons.calendar_month,
              title: 'Daily Check-in',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Daily Check-in');
              },
            ),
          if (_hasPermission('Reports & Analytics'))
            _buildDrawerItem(
              icon: Icons.analytics,
              title: 'Analytics',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Reports & Analytics');
              },
            ),

          // Platform Management Section
          if (_hasPermission('Game Management') || _hasPermission('Rooms Management') || _hasPermission('Custom Room IDs') || _hasPermission('Settings'))
            _buildSectionHeader('🎵 PLATFORM MANAGEMENT'),
          if (_hasPermission('Game Management'))
            _buildDrawerItem(
              icon: Icons.games,
              title: 'Game Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Game Management');
              },
            ),
          if (_hasPermission('Rooms Management'))
            _buildDrawerItem(
              icon: Icons.room,
              title: 'Audio Rooms',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Rooms Management');
              },
            ),
          if (_hasPermission('Custom Room IDs'))
            _buildDrawerItem(
              icon: Icons.vpn_key,
              title: 'Custom Room IDs',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Custom Room IDs');
              },
            ),
          if (_hasPermission('Settings'))
            _buildDrawerItem(
              icon: Icons.color_lens,
              title: 'App Theme & Assets',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('App Theme & Assets');
              },
            ),
          if (_hasPermission('Settings'))
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Settings');
              },
            ),
          if (_hasPermission('Settings'))
            _buildDrawerItem(
              icon: Icons.card_giftcard,
              title: 'Invitation Referral Reward',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Invitation Referral Reward');
              },
            ),

          // Support & Feedback Section
          _buildSectionHeader('📩 SUPPORT'),
          _buildDrawerItem(
            icon: Icons.feedback,
            title: 'User Feedbacks',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen('Feedback Management');
            },
          ),

          if (AdminAuthService.isMainAdmin()) ...[
            _buildSectionHeader('🛡️ SYSTEM ADMIN'),
            _buildDrawerItem(
              icon: Icons.security,
              title: 'Super Admins',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Super Admins');
              },
            ),
            _buildDrawerItem(
              icon: Icons.manage_accounts,
              title: 'Admin Accounts',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Admin Accounts');
              },
            ),
            _buildDrawerItem(
              icon: Icons.devices_other,
              title: 'Device Sessions',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Device Sessions');
              },
            ),
          ],

          const Divider(color: Colors.grey),
          _buildLogoutItem(),
        ],
      ),
    );
  }

  bool _hasPermission(String module) {
    return AdminAuthService.hasPermission(module);
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey,
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
        selectedTileColor: Colors.transparent,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _navigateToScreen(String screenName) {
    Widget screen;

    switch (screenName) {
      // Original screens
      case 'Users Management':
        screen = const UsersManagement();
        break;
      case 'Rooms Management':
        screen = const RoomsManagement();
        break;
      case 'Gifts Management':
        screen = const GiftManagement();
        break;
      case 'Emojis Management':
        screen = const EmojiManagement();
        break;
      case 'Diamonds Management':
        screen = const DiamondsManagement();
        break;
      case 'Daily Check-in':
        screen = const DailyCheckInManagementScreen();
        break;
      case 'Reports & Analytics':
        screen = const ReportsAnalytics();
        break;
      case 'Settings':
        screen = const SettingsScreen();
        break;
      case 'Agency Management':
        screen = const AgencyManagement();
        break;
      case 'Commission Management':
        screen = const CommissionManagement();
        break;
      case 'Seller Management':
        screen = const SellerManagement();
        break;
      case 'Store Management':
        screen = const StoreManagement();
        break;
      case 'Add Store Item':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddStoreItemScreen()));
        return;

      // New User Profile & Features screens
      case 'User Profile Management':
        screen = const UserProfileManagement();
        break;
      case 'Market Management':
        screen = const MarketManagement();
        break;
      case 'User History Stats':
        // For now, navigate to a general screen - in real app, you'd select a user first
        screen = const UserHistoryStats(userId: 'demo', username: 'Demo User');
        break;
      case 'Blocked Users Management':
        screen = const BlockedUsersManagement();
        break;
      case 'Ban Management':
        screen = const UserBanManagementScreen();
        break;
      case 'Level System Management':
        screen = const LevelSystemManagement();
        break;
      case 'Admin Accounts':
        screen = const AdminAccountsScreen();
        break;
      case 'Room Ban Management':
        screen = const RoomBanManagementScreen();
        break;
      case 'Family Management':
        screen = const FamilyManagementScreen();
        break;
      case 'Family Levels':
        screen = const FamilyLevelManagementScreen();
        break;
      case 'SVIP Management':
        screen = const SvipManagementScreen();
        break;
      case 'Host Agency Management':
        screen = const HostAgencyManagement();
        break;
      case 'Official Items':
        screen = const OfficialItemsScreen();
        break;
      case 'Banner Management':
        screen = const BannerManagementScreen();
        break;
      case 'Event Management':
        screen = const EventManagementScreen();
        break;
      case 'Room Event Portal':
        screen = const RoomEventPortalManagement();
        break;
      case 'Official Channels':
        screen = const OfficialChannelsScreen();
        break;
      case 'Game Management':
        screen = const GameManagementScreen();
        break;
      case 'Fruit Wheel Game':
        screen = const FruitWheelGameScreen();
        break;
      case 'Custom Room IDs':
        screen = const RoomIdCustomizationScreen();
        break;
      case 'Gift Economy':
        screen = const GiftTransactionsScreen();
        break;
      case 'Invitation Referral Reward':
        screen = const InvitationRewardScreen();
        break;
      case 'App Theme & Assets':
        screen = const AppThemeManagementScreen();
        break;
      case 'Withdrawal Management':
        screen = const WithdrawalManagement();
        break;
      case 'Super Admins':
        screen = const SuperAdminManagementScreen();
        break;
      case 'Device Sessions':
        screen = const DeviceManagementScreen();
        break;
      case 'Feedback Management':
        screen = const FeedbackManagementScreen();
        break;

      default:
        _showErrorSnackBar('Screen not found: $screenName');
        return; // Don't navigate if screen not found
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _handleLogout() async {
    await AdminAuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Widget _buildLogoutItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.withValues(alpha: 0.1),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red, size: 24),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          _showLogoutDialog();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
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
                      const Text(
                        'Welcome to IMChat Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your chat platform with ease',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'System Online',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 64,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Cards
          const Text(
            'Platform Statistics',
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
                  value: _totalUsers.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Rooms',
                  value: _totalRooms.toString(),
                  icon: Icons.room,
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
                  title: 'Total Gifts',
                  value: _totalGifts.toString(),
                  icon: Icons.card_giftcard,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Diamonds',
                  value: (_totalUsers * 100).toString(),
                  icon: Icons.monetization_on,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

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

          // First row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Users',
                  subtitle: 'View and manage users',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () {
                    _navigateToScreen('Users Management');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Rooms',
                  subtitle: 'Control audio rooms',
                  icon: Icons.room,
                  color: Colors.green,
                  onTap: () {
                    _navigateToScreen('Rooms Management');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Second row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Gifts',
                  subtitle: 'Add and edit gifts',
                  icon: Icons.card_giftcard,
                  color: Colors.purple,
                  onTap: () {
                    _navigateToScreen('Gifts Management');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Manage Emojis',
                  subtitle: 'Upload and organize emojis',
                  icon: Icons.emoji_emotions,
                  color: Colors.orange,
                  onTap: () {
                    _navigateToScreen('Emojis Management');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Third row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Diamonds Management',
                  subtitle: 'Manage user Diamonds',
                  icon: Icons.monetization_on,
                  color: Colors.amber,
                  onTap: () {
                    _navigateToScreen('Diamonds Management');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Agency Management',
                  subtitle: 'Manage agencies and hosts',
                  icon: Icons.business,
                  color: Colors.indigo,
                  onTap: () {
                    _navigateToScreen('Agency Management');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fourth row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Commission Management',
                  subtitle: 'Manage agency commissions',
                  icon: Icons.account_balance_wallet,
                  color: Colors.teal,
                  onTap: () {
                    _navigateToScreen('Commission Management');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Seller Management',
                  subtitle: 'Manage sellers and recharges',
                  icon: Icons.store,
                  color: Colors.indigo,
                  onTap: () {
                    _navigateToScreen('Seller Management');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fifth row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Store Management',
                  subtitle: 'Manage store items and assignments',
                  icon: Icons.shopping_cart,
                  color: Colors.indigo,
                  onTap: () {
                    _navigateToScreen('Store Management');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Reports & Analytics',
                  subtitle: 'View detailed analytics',
                  icon: Icons.analytics,
                  color: Colors.cyan,
                  onTap: () {
                    _navigateToScreen('Reports & Analytics');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sixth row of actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Settings',
                  subtitle: 'Configure system settings',
                  icon: Icons.settings,
                  color: Colors.grey,
                  onTap: () {
                    _navigateToScreen('Settings');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(), // Empty space for symmetry
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Activity
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? trend,
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
            children: [
              Icon(icon, color: color, size: 32),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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

  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          _buildActivityItem(
            icon: Icons.dashboard,
            title: 'Dashboard Loaded',
            subtitle: 'Admin panel initialized successfully',
            time: 'Just now',
            color: Colors.blue,
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildActivityItem(
            icon: Icons.sync,
            title: 'Data Synchronized',
            subtitle: 'All collections loaded from Firebase',
            time: '1 minute ago',
            color: Colors.green,
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildActivityItem(
            icon: Icons.analytics,
            title: 'Statistics Updated',
            subtitle: 'Platform metrics refreshed',
            time: '2 minutes ago',
            color: Colors.purple,
          ),
          const Divider(color: Colors.grey, height: 1),
          _buildActivityItem(
            icon: Icons.admin_panel_settings,
            title: 'Admin Panel Active',
            subtitle: 'Management system running normally',
            time: '3 minutes ago',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
