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
import 'game_profit_analysis_screen.dart';
import 'settings_screen.dart';
import 'agency_management.dart';
import 'commission_management.dart';
import 'seller_management.dart';
import 'store_management.dart';
import 'user_profile_management.dart';
import 'daily_checkin_management.dart';
import 'market_management.dart';
import 'users_history_screen.dart';
import 'blocked_users_management.dart';
import 'user_ban_management_screen.dart';
import 'room_ban_management_screen.dart';
import 'level_system_management.dart';
import 'intimacy_level_management.dart';
import 'couple_level_management.dart';
import 'host_agency_management.dart';
import 'gift_transactions_screen.dart';
import 'withdrawal_management.dart';
import 'official_items_screen.dart';
import 'banner_management_screen.dart';
import 'official_channels_screen.dart';
import 'official_notifications_screen.dart';
import 'event_management_screen.dart';
import 'room_event_portal_management.dart';
import 'game_management_screen.dart';
import 'fruit_wheel_game_screen.dart';
import 'room_id_customization_screen.dart';
import 'user_id_customization_screen.dart';
import 'super_admin_management_screen.dart';
import 'svip_management_screen.dart';
import 'vip_management_screen.dart';
import 'add_store_item_screen.dart';
import 'feedback_management_screen.dart';
import 'family_management_screen.dart';
import 'grab_the_top_management.dart';
import 'moment_management_screen.dart';
import 'realtime_server_setup_screen.dart';
import '../services/admin_auth_service.dart';
import 'admin_accounts_screen.dart';
import 'login_screen.dart';
import 'invitation_reward_screen.dart';
import 'app_theme_management_screen.dart';
import 'family_level_management.dart';
import 'website_landing_management_screen.dart';
import 'sub_official_admin_screen.dart';
import 'html5_game_management_screen.dart';
import 'room_create_decoration_screen.dart';
import 'room_game_management_screen.dart';
import 'user_position_management_screen.dart';
import 'agency_commission_tier_management.dart';
import 'agency_transfer_management_screen.dart';
import 'seller_requests_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics/audio_video_analytics_screen.dart';
import 'analytics/user_registration_analytics_screen.dart';
import 'analytics/recharge_analytics_screen.dart';
import 'analytics/gift_analytics_screen.dart';
import 'analytics/seller_recharge_analytics_screen.dart';
import '../services/dashboard_analytics_service.dart';
import '../widgets/media_preview_widget.dart';
import 'recharge_wallet_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Statistics & Real-time Analytics
  int _totalUsers = 0;
  int _totalRooms = 0;
  int _totalGifts = 0;
  bool _isLoading = true;

  StreamSubscription<DashboardTodayStats>? _todayStatsSubscription;
  StreamSubscription<DocumentSnapshot>? _themeSubscription;
  DashboardTodayStats _todayStats = const DashboardTodayStats();
  String? _diamondIconUrl;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    DashboardAnalyticsService.syncAndInitializeAgoraMinutesToFirestore();
    _startRealtimeListeners();
    AdminAuthService.permissionNotifier.addListener(_handlePermissionUpdate);
  }

  void _handlePermissionUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startRealtimeListeners() {
    _todayStatsSubscription?.cancel();
    _todayStatsSubscription = DashboardAnalyticsService.getTodayStatsStream().listen(
      (stats) {
        if (!mounted) return;
        setState(() {
          _todayStats = stats;
          _totalUsers = stats.totalUsers > 0 ? stats.totalUsers : _totalUsers;
          _totalRooms = stats.activeRooms > 0 ? stats.activeRooms : _totalRooms;
          _totalGifts = stats.totalGifts > 0 ? stats.totalGifts : _totalGifts;
          _isLoading = false;
        });
      },
      onError: (e) {
        debugPrint('Error listening to today stats: $e');
      },
    );

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
        });
      }
    }, onError: (e) {
      debugPrint('Theme listener error: $e');
    });
  }

  Widget _buildDiamondIcon({double size = 22}) {
    if (_diamondIconUrl != null && _diamondIconUrl!.trim().isNotEmpty) {
      return MediaPreviewWidget(
        url: _diamondIconUrl!,
        width: size,
        height: size,
        borderRadius: BorderRadius.circular(4),
      );
    }
    return Icon(Icons.diamond, color: const Color(0xFFF59E0B), size: size);
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
    AdminAuthService.permissionNotifier.removeListener(_handlePermissionUpdate);
    _todayStatsSubscription?.cancel();
    _themeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMain = AdminAuthService.isMainAdmin();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          isMain ? 'IMChat Admin Panel' : 'Sub Official Admin Panel',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    final isMain = AdminAuthService.isMainAdmin();
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Enhanced Header with Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isMain ? [Colors.blue, Colors.purple] : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
            ),
            child: DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMain ? Icons.admin_panel_settings : Icons.security,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMain ? 'IMChat Admin' : 'Sub Official Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isMain ? 'Management Panel' : (AdminAuthService.currentUserName ?? 'Official Admin'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
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
          if (_hasPermission('Users Management') ||
              _hasPermission('User Profiles') ||
              _hasPermission('Hosts & Agencies') ||
              _hasPermission('Blocked Users') ||
              _hasPermission('Family Management'))
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
          if (_hasPermission('Users Management') || _hasPermission('Custom User IDs'))
            _buildDrawerItem(
              icon: Icons.badge,
              title: 'Custom User IDs',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Custom User IDs');
              },
            ),
          if (_hasPermission('Users Management') || _hasPermission('User Positions'))
            _buildDrawerItem(
              icon: Icons.workspace_premium,
              title: 'User Position',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('User Position');
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
          if (_hasPermission('Banner Management') ||
              _hasPermission('Event Management') ||
              _hasPermission('Official Channels') ||
              _hasPermission('Market Management') ||
              _hasPermission('Gifts Management') ||
              _hasPermission('Emojis Management') ||
              _hasPermission('imChat Moment Management'))
            _buildSectionHeader('🛍️ CONTENT & STORE'),
          if (_hasPermission('imChat Moment Management'))
            _buildDrawerItem(
              icon: Icons.dynamic_feed,
              title: 'imChat Moment Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('imChat Moment Management');
              },
            ),
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
          if (_hasPermission(
            'Event Management',
          )) // Room Event Portal falls under Event Management
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
          if (_hasPermission('Official Channels'))
            _buildDrawerItem(
              icon: Icons.notification_important,
              title: 'Official Notifications',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Official Notifications');
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
          if (_hasPermission('Level System') ||
              _hasPermission('Intimacy Levels') ||
              _hasPermission('Couple Levels') ||
              _hasPermission('User History & Stats') ||
              _hasPermission('VIP Management') ||
              _hasPermission('SVIP Management'))
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
          if (_hasPermission('Intimacy Levels') || _hasPermission('Level System'))
            _buildDrawerItem(
              icon: Icons.favorite_border,
              title: 'Intimacy Level',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Intimacy Level');
              },
            ),
          if (_hasPermission('Couple Levels') || _hasPermission('Level System'))
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'Couple Level',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Couple Level');
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
          if (_hasPermission('VIP Management'))
            _buildDrawerItem(
              icon: Icons.star_border_outlined,
              title: 'VIP Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('VIP Management');
              },
            ),
          if (_hasPermission('SVIP Management'))
            _buildDrawerItem(
              icon: Icons.star,
              title: 'SVIP Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('SVIP Management');
              },
            ),

          // Business & Analytics Section
          if (_hasPermission('Agency Management') ||
              _hasPermission('Seller Management') ||
              _hasPermission('Commission Management') ||
              _hasPermission('Official Items') ||
              _hasPermission('Gift Economy') ||
              _hasPermission('Withdrawal Management') ||
              _hasPermission('Diamonds Management') ||
              _hasPermission('Daily Check-in') ||
              _hasPermission('Reports & Analytics'))
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
          if (_hasPermission('Agency Management') || _hasPermission('Hosts & Agencies'))
            _buildDrawerItem(
              icon: Icons.published_with_changes_rounded,
              title: 'Agency Transfer Approvals',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Agency Transfer Approvals');
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
          if (_hasPermission('Seller Management'))
            _buildDrawerItem(
              icon: Icons.diamond_outlined,
              title: 'Seller Diamond Requests',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Seller Diamond Requests');
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
          if (_hasPermission('Diamonds Management'))
            _buildDrawerItem(
              icon: Icons.account_balance_wallet,
              title: 'Recharge Wallet Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Recharge Wallet Management');
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
          if (_hasPermission('Reports & Analytics'))
            _buildDrawerItem(
              icon: Icons.pie_chart,
              title: 'Game Profit & Analysis',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Game Profit & Analysis');
              },
            ),

          // Platform Management Section
          if (_hasPermission('Game Management') ||
              _hasPermission('Rooms Management') ||
              _hasPermission('Custom Room IDs') ||
              _hasPermission('Settings'))
            _buildSectionHeader('🎵 PLATFORM MANAGEMENT'),
          if (_hasPermission('Game Management'))
            _buildDrawerItem(
              icon: Icons.sports_esports,
              title: '🎮 HTML 5 Game',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('HTML 5 Game');
              },
            ),
          if (_hasPermission('Game Management'))
            _buildDrawerItem(
              icon: Icons.games,
              title: 'Game Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Game Management');
              },
            ),
          if (_hasPermission('Game Management'))
            _buildDrawerItem(
              icon: Icons.meeting_room_rounded,
              title: 'Room Game Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Room Game Management');
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
          if (_hasPermission('Rooms Management') || _hasPermission('Settings'))
            _buildDrawerItem(
              icon: Icons.auto_awesome,
              title: '🎨 Room Create Decoration',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Room Create Decoration');
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
          if (_hasPermission('Rooms Management') || _hasPermission('Settings'))
            _buildDrawerItem(
              icon: Icons.event_seat_rounded,
              title: '🪑 Grab the Top Management',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Grab the Top Management');
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
              icon: Icons.dns,
              title: 'রিয়েল টাইম সার্ভার সেটআপ',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Realtime Server Setup');
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
              icon: Icons.admin_panel_settings,
              title: '👑 Sub Official Admin',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Sub Official Admin');
              },
            ),
            _buildDrawerItem(
              icon: Icons.language,
              title: '🌐 Website Landing (imchatapp.com)',
              onTap: () {
                Navigator.pop(context);
                _navigateToScreen('Website Landing');
              },
            ),
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
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
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
    if (!AdminAuthService.isMainAdmin()) {
      // Map screenName to module
      String requiredModule = screenName;
      if (screenName == 'User Profile Management' ||
          screenName == 'Custom User IDs' ||
          screenName == 'User Position' ||
          screenName == 'User Positions') {
        requiredModule = 'Users Management';
      } else if (screenName == 'Host Agency Management' ||
          screenName == 'Agency Transfer Approvals' ||
          screenName == 'Agency Transfers' ||
          screenName == 'Agency Change Approvals') {
        requiredModule = 'Hosts & Agencies';
      } else if (screenName == 'Blocked Users Management' ||
          screenName == 'Ban Management' ||
          screenName == 'Room Ban Management') {
        requiredModule = 'Blocked Users';
      } else if (screenName == 'Family Levels') {
        requiredModule = 'Family Management';
      } else if (screenName == 'Room Event Portal') {
        requiredModule = 'Event Management';
      } else if (screenName == 'Add Store Item' || screenName == 'Official Store') {
        requiredModule = 'Market Management';
      } else if (screenName == 'Game Profit & Analysis' || screenName == 'Fruit Wheel Game' || screenName == 'Room Game Management' || screenName == 'HTML 5 Game') {
        requiredModule = 'Game Management';
      } else if (screenName == 'Recharge Wallet Management' || screenName == 'Recharge Analytics' || screenName == 'Today Recharge Diamond') {
        requiredModule = 'Recharge Wallet Management';
      } else if (screenName == 'User Registration Analytics' || screenName == 'Today Registered Users') {
        requiredModule = 'Users Management';
      } else if (screenName == 'Gift Analytics' || screenName == 'Today Gift Send') {
        requiredModule = 'Gifts Management';
      } else if (screenName == 'Seller Recharge Analytics' || screenName == 'Today Seller Recharge' || screenName == 'Seller Management' || screenName == 'Seller Diamond Requests' || screenName == 'Seller Requests') {
        requiredModule = 'Seller Management';
      } else if (screenName == 'Agora Audio & Video Analytics' || screenName == 'Audio & Video Minutes Analytics' || screenName == 'Audio Video Analytics') {
        requiredModule = 'Rooms Management';
      } else if (screenName == 'Sub Official Admin' ||
          screenName == 'Sub Admins' ||
          screenName == 'Super Admins' ||
          screenName == 'Admin Accounts' ||
          screenName == 'Device Sessions' ||
          screenName == 'Website Landing') {
        _showErrorSnackBar('Access Denied: Main Super Admin authorization required.');
        return;
      }

      if (!_hasPermission(requiredModule) && !_hasPermission(screenName)) {
        _showErrorSnackBar('Access Denied: You do not have permission for $screenName.');
        return;
      }
    }

    Widget screen;

    switch (screenName) {
      // Original screens
      case 'Users Management':
        screen = const UsersManagement();
        break;
      case 'Rooms Management':
        screen = const RoomsManagement();
        break;
      case 'Room Create Decoration':
        screen = const RoomCreateDecorationScreen();
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
      case 'Recharge Wallet Management':
      case 'Recharge Management':
        screen = const RechargeWalletManagementScreen();
        break;
      case 'Daily Check-in':
        screen = const DailyCheckInManagementScreen();
        break;
      case 'Reports & Analytics':
        screen = const ReportsAnalytics();
        break;
      case 'Game Profit & Analysis':
        screen = const GameProfitAnalysisScreen();
        break;
      case 'Settings':
        screen = const SettingsScreen();
        break;
      case 'Website Landing':
        screen = const WebsiteLandingManagementScreen();
        break;
      case 'Realtime Server Setup':
        screen = const RealtimeServerSetupScreen();
        break;
      case 'Agency Management':
        screen = const AgencyManagement();
        break;
      case 'Agency Transfer Approvals':
      case 'Agency Transfers':
      case 'Agency Change Approvals':
        screen = const AgencyTransferManagementScreen();
        break;
      case 'Agency Commission Tiers':
      case 'Level-Based Commission':
      case 'Agency Level Commission':
        screen = const AgencyCommissionTierManagementScreen();
        break;
      case 'Commission Management':
        screen = const CommissionManagement();
        break;
      case 'Seller Management':
        screen = const SellerManagement();
        break;
      case 'Seller Diamond Requests':
      case 'Seller Requests':
      case 'Admin Seller Requests':
        screen = const SellerRequestsScreen();
        break;
      case 'Store Management':
        screen = const StoreManagement();
        break;
      case 'Add Store Item':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddStoreItemScreen()),
        );
        return;

      // New User Profile & Features screens
      case 'User Position':
      case 'User Position Management':
      case 'User Positions':
        screen = const UserPositionManagementScreen();
        break;
      case 'User Profile Management':
        screen = const UserProfileManagement();
        break;
      case 'Grab the Top Management':
        screen = const GrabTheTopManagementScreen();
        break;
      case 'Market Management':
        screen = const MarketManagement();
        break;
      case 'User History Stats':
      case 'Users History':
        screen = const UsersHistoryScreen();
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
      case 'Intimacy Level':
        screen = const IntimacyLevelManagementScreen();
        break;
      case 'Couple Level':
        screen = const CoupleLevelManagementScreen();
        break;
      case 'Sub Official Admin':
      case 'Sub Admins':
        screen = const SubOfficialAdminScreen();
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
      case 'VIP Management':
        screen = const VipManagementScreen();
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
      case 'imChat Moment Management':
        screen = const MomentManagementScreen();
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
      case 'Official Notifications':
        screen = const OfficialNotificationsScreen();
        break;
      case 'HTML 5 Game':
        screen = const Html5GameManagementScreen();
        break;
      case 'Game Management':
        screen = const GameManagementScreen();
        break;
      case 'Room Game Management':
        screen = const RoomGameManagementScreen();
        break;
      case 'Fruit Wheel Game':
        screen = const FruitWheelGameScreen();
        break;
      case 'Custom Room IDs':
        screen = const RoomIdCustomizationScreen();
        break;
      case 'Custom User IDs':
      case 'User ID Customization':
        screen = const UserIdCustomizationScreen();
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
      case 'Feedback Management':
        screen = const FeedbackManagementScreen();
        break;

      // Analytics Screens
      case 'Agora Audio & Video Analytics':
      case 'Audio & Video Minutes Analytics':
      case 'Audio Video Analytics':
        screen = const AudioVideoAnalyticsScreen();
        break;

      case 'User Registration Analytics':
      case 'Today Registered Users':
        screen = const UserRegistrationAnalyticsScreen();
        break;

      case 'Recharge Analytics':
      case 'Today Recharge Diamond':
        screen = const RechargeAnalyticsScreen();
        break;

      case 'Gift Analytics':
      case 'Today Gift Send':
        screen = const GiftAnalyticsScreen();
        break;

      case 'Seller Recharge Analytics':
      case 'Today Seller Recharge':
        screen = const SellerRechargeAnalyticsScreen();
        break;

      default:
        _showErrorSnackBar('Screen not found: $screenName');
        return; // Don't navigate if screen not found
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout from Admin Panel?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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

  List<Widget> _buildPermittedQuickActionCards() {
    final List<Widget> cards = [];

    if (_hasPermission('Users Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Manage Users',
          subtitle: 'View and manage users',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => _navigateToScreen('Users Management'),
        ),
      );
    }

    if (_hasPermission('Rooms Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Manage Rooms',
          subtitle: 'Control audio rooms',
          icon: Icons.room,
          color: Colors.green,
          onTap: () => _navigateToScreen('Rooms Management'),
        ),
      );
    }

    if (_hasPermission('Gifts Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Manage Gifts',
          subtitle: 'Add and edit gifts',
          icon: Icons.card_giftcard,
          color: Colors.purple,
          onTap: () => _navigateToScreen('Gifts Management'),
        ),
      );
    }

    if (_hasPermission('Emojis Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Manage Emojis',
          subtitle: 'Upload and organize emojis',
          icon: Icons.emoji_emotions,
          color: Colors.orange,
          onTap: () => _navigateToScreen('Emojis Management'),
        ),
      );
    }

    if (_hasPermission('Recharge Wallet Management') || _hasPermission('Diamonds Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Recharge Wallet Management',
          subtitle: 'Packages, payment channels & TrxID verification',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF8B5CF6),
          onTap: () => _navigateToScreen('Recharge Wallet Management'),
        ),
      );
    }

    if (_hasPermission('Diamonds Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Diamonds Management',
          subtitle: 'Manage user Diamonds',
          icon: Icons.monetization_on,
          color: Colors.amber,
          onTap: () => _navigateToScreen('Diamonds Management'),
        ),
      );
    }

    if (_hasPermission('Agency Management') || _hasPermission('Hosts & Agencies')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Agency Management',
          subtitle: 'Manage agencies and hosts',
          icon: Icons.business,
          color: Colors.indigo,
          onTap: () => _navigateToScreen('Agency Management'),
        ),
      );
      cards.add(
        _buildQuickActionCard(
          title: 'Agency Transfer Approvals',
          subtitle: 'Approve & track host agency change requests',
          icon: Icons.published_with_changes_rounded,
          color: const Color(0xFF6C5CE7),
          onTap: () => _navigateToScreen('Agency Transfer Approvals'),
        ),
      );
    }

    if (_hasPermission('Commission Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Commission Management',
          subtitle: 'Manage agency commissions',
          icon: Icons.account_balance_wallet,
          color: Colors.teal,
          onTap: () => _navigateToScreen('Commission Management'),
        ),
      );
    }

    if (_hasPermission('Seller Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Seller Management',
          subtitle: 'Manage sellers and recharges',
          icon: Icons.store,
          color: Colors.indigo,
          onTap: () => _navigateToScreen('Seller Management'),
        ),
      );
    }

    if (_hasPermission('Store Management') || _hasPermission('Official Items') || _hasPermission('Market Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Store Management',
          subtitle: 'Manage store items and assignments',
          icon: Icons.shopping_cart,
          color: Colors.indigo,
          onTap: () => _navigateToScreen('Store Management'),
        ),
      );
    }

    if (_hasPermission('Reports & Analytics')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Reports & Analytics',
          subtitle: 'View detailed analytics',
          icon: Icons.analytics,
          color: Colors.cyan,
          onTap: () => _navigateToScreen('Reports & Analytics'),
        ),
      );
    }

    if (_hasPermission('Settings')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Settings',
          subtitle: 'Configure system settings',
          icon: Icons.settings,
          color: Colors.grey,
          onTap: () => _navigateToScreen('Settings'),
        ),
      );
    }

    if (_hasPermission('Game Management') || _hasPermission('Game Profit Analysis')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Game Profit & Analysis',
          subtitle: 'View real-time game logs and stats',
          icon: Icons.pie_chart,
          color: Colors.deepPurple,
          onTap: () => _navigateToScreen('Game Profit & Analysis'),
        ),
      );
    }

    if (_hasPermission('imChat Moment Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'imChat Moment Management',
          subtitle: 'Notices, Reports, Moderation & AdSense',
          icon: Icons.dynamic_feed,
          color: Colors.purpleAccent,
          onTap: () => _navigateToScreen('imChat Moment Management'),
        ),
      );
    }

    if (_hasPermission('Banner Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Banner Management',
          subtitle: 'Home & Room banner promotions',
          icon: Icons.view_carousel,
          color: Colors.deepOrange,
          onTap: () => _navigateToScreen('Banner Management'),
        ),
      );
    }

    if (_hasPermission('Event Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Event Management',
          subtitle: 'Platform campaigns & room events',
          icon: Icons.event,
          color: Colors.pinkAccent,
          onTap: () => _navigateToScreen('Event Management'),
        ),
      );
    }

    if (_hasPermission('Official Channels')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Official Channels',
          subtitle: 'Broadcast notifications & channel posts',
          icon: Icons.campaign,
          color: Colors.tealAccent,
          onTap: () => _navigateToScreen('Official Channels'),
        ),
      );
    }

    if (_hasPermission('Official Notifications')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Official Notifications',
          subtitle: 'Send direct in-app system messages',
          icon: Icons.notification_important,
          color: Colors.amberAccent,
          onTap: () => _navigateToScreen('Official Notifications'),
        ),
      );
    }

    if (_hasPermission('Blocked Users') || _hasPermission('Ban Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Ban Management',
          subtitle: 'User device & account suspensions',
          icon: Icons.gavel,
          color: Colors.redAccent,
          onTap: () => _navigateToScreen('Ban Management'),
        ),
      );
    }

    if (_hasPermission('Family Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Family Management',
          subtitle: 'Clan badges, ranking & settings',
          icon: Icons.family_restroom,
          color: Colors.deepPurpleAccent,
          onTap: () => _navigateToScreen('Family Management'),
        ),
      );
    }

    if (_hasPermission('Withdrawal Management')) {
      cards.add(
        _buildQuickActionCard(
          title: 'Withdrawal Management',
          subtitle: 'Host & seller payout requests',
          icon: Icons.currency_exchange,
          color: Colors.greenAccent,
          onTap: () => _navigateToScreen('Withdrawal Management'),
        ),
      );
    }

    if (AdminAuthService.isMainAdmin()) {
      cards.add(
        _buildQuickActionCard(
          title: '👑 Sub Official Admin',
          subtitle: 'Manage sub-admin credentials & module permissions',
          icon: Icons.admin_panel_settings,
          color: Colors.blueAccent,
          onTap: () => _navigateToScreen('Sub Official Admin'),
        ),
      );
    }

    return cards;
  }

  Widget _buildQuickActionsGrid(List<Widget> cards) {
    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: const Center(
          child: Text(
            'No management module permissions assigned yet. Please contact Super Admin.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < cards.length; i += 2) {
      if (i + 1 < cards.length) {
        rows.add(
          Row(
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 16),
              Expanded(child: cards[i + 1]),
            ],
          ),
        );
      } else {
        rows.add(
          Row(
            children: [
              Expanded(child: cards[i]),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }
      if (i + 2 < cards.length) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return Column(children: rows);
  }

  Widget _buildDashboard() {
    final isMain = AdminAuthService.isMainAdmin();
    final currentName = AdminAuthService.currentUserName ?? 'Admin';
    final quickActionCards = _buildPermittedQuickActionCards();

    // If Sub Official Admin, display strictly the dedicated Sub Official Portal View
    if (!isMain) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub Official Dedicated Welcome & Status Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                '🔐 OFFICIAL SUB-ADMIN PORTAL',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome, $currentName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'You have real-time access to ${quickActionCards.length} assigned management modules.',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Colors.greenAccent, size: 10),
                                  SizedBox(width: 6),
                                  Text(
                                    'Real-time Live Sync Active',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.blueAccent,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Permitted Modules Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Sub Official Modules',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${quickActionCards.length} Modules Authorized',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Permitted Action Cards Grid
            _buildQuickActionsGrid(quickActionCards),
          ],
        ),
      );
    }

    // Main Super Admin View: Full Analytics, Revenue, Agora Usage & Platform Stats
    final List<Widget> liveStatCards = [
      _buildInteractiveStatCard(
        title: 'Total Users',
        value: _todayStats.totalUsers > 0 ? _todayStats.totalUsers.toString() : _totalUsers.toString(),
        icon: Icons.people_alt,
        color: const Color(0xFF3B82F6),
        subtitle: 'Registered Accounts',
        onTap: () => _navigateToScreen('Users Management'),
      ),
      _buildInteractiveStatCard(
        title: 'Active Rooms',
        value: _todayStats.activeRooms > 0 ? _todayStats.activeRooms.toString() : _totalRooms.toString(),
        icon: Icons.meeting_room,
        color: const Color(0xFF10B981),
        subtitle: 'Live Audio Channels',
        onTap: () => _navigateToScreen('Rooms Management'),
      ),
      _buildInteractiveStatCard(
        title: 'Total Gifts',
        value: _todayStats.totalGifts > 0 ? _todayStats.totalGifts.toString() : _totalGifts.toString(),
        icon: Icons.card_giftcard,
        color: const Color(0xFFA855F7),
        subtitle: 'App Gift Catalog',
        onTap: () => _navigateToScreen('Gifts Management'),
      ),
      _buildInteractiveStatCard(
        title: 'Total Diamonds',
        value: '${_todayStats.totalDiamonds > 0 ? _todayStats.totalDiamonds.toStringAsFixed(0) : (_totalUsers * 100).toString()} 💎',
        icon: Icons.diamond,
        customIconWidget: _buildDiamondIcon(size: 28),
        color: const Color(0xFFF59E0B),
        subtitle: 'App Diamond Circulation',
        onTap: () => _navigateToScreen('Recharge Analytics'),
      ),
    ];

    final List<Widget> activityCards = [
      _buildActivityAnalyticsCard(
        title: 'Today Registered User',
        value: '${_todayStats.todayRegisteredUsers} Users',
        subtitle: 'New registrations today',
        icon: Icons.person_add_alt_1,
        badgeText: 'Daily Growth',
        color: const Color(0xFF3B82F6),
        bgGradient: const [Color(0xFF1E3A8A), Color(0xFF172554)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserRegistrationAnalyticsScreen(initialPeriod: 'daily'),
            ),
          );
        },
      ),
      _buildActivityAnalyticsCard(
        title: 'Today Recharge Diamond',
        value: '${_todayStats.todayRechargeDiamonds.toStringAsFixed(0)} 💎',
        subtitle: 'Purchased by users',
        icon: Icons.monetization_on,
        badgeText: 'Recharge Inflow',
        color: const Color(0xFFF59E0B),
        bgGradient: const [Color(0xFF78350F), Color(0xFF451A03)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RechargeAnalyticsScreen(initialPeriod: 'daily'),
            ),
          );
        },
      ),
      _buildActivityAnalyticsCard(
        title: 'Today Gift Send',
        value: '${_todayStats.todayGiftCount} Gifts',
        subtitle: '${_todayStats.todayGiftDiamonds.toStringAsFixed(0)} 💎 Sent',
        icon: Icons.card_giftcard,
        badgeText: 'Gift Economy',
        color: const Color(0xFFA855F7),
        bgGradient: const [Color(0xFF581C87), Color(0xFF3B0764)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GiftAnalyticsScreen(initialPeriod: 'daily'),
            ),
          );
        },
      ),
      _buildActivityAnalyticsCard(
        title: 'Today Game Profit',
        value: '${_todayStats.todayGameProfit >= 0 ? '+' : ''}${_todayStats.todayGameProfit.toStringAsFixed(0)} 💎',
        subtitle: 'Greedy & Fruit Wheel Net',
        icon: Icons.sports_esports,
        badgeText: 'Game Profit',
        color: const Color(0xFFEC4899),
        bgGradient: const [Color(0xFF831843), Color(0xFF500724)],
        onTap: () => _navigateToScreen('Game Profit & Analysis'),
      ),
      _buildActivityAnalyticsCard(
        title: 'Today Seller Recharge',
        value: '${_todayStats.todaySellerRecharge.toStringAsFixed(0)} 💎',
        subtitle: 'Vendor distribution',
        icon: Icons.storefront,
        badgeText: 'Seller Sales',
        color: const Color(0xFF10B981),
        bgGradient: const [Color(0xFF064E3B), Color(0xFF022C22)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SellerRechargeAnalyticsScreen(initialPeriod: 'daily'),
            ),
          );
        },
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Super Admin Welcome Header
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
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Manage your chat platform with ease (Main Super Admin)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 12,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'System Online (Master Admin)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Platform Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Live Real-Time',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(liveStatCards),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Activity & Revenue Analysis",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Click card for Daily/Weekly/Monthly history',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildQuickActionsGrid(activityCards),

          const SizedBox(height: 28),
          _buildAgoraUsageShowcaseCard(),

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
          _buildQuickActionsGrid(quickActionCards),

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

  Widget _buildInteractiveStatCard({
    required String title,
    required String value,
    required IconData icon,
    Widget? customIconWidget,
    required Color color,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: color.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customIconWidget ??
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityAnalyticsCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required Color color,
    required List<Color> bgGradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white54, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgoraUsageShowcaseCard() {
    final totalMins = _todayStats.todayAudioMinutes +
        _todayStats.todayVideoMinutes +
        _todayStats.todayAudioRoomMinutes +
        _todayStats.todayLiveRoomMinutes;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AudioVideoAnalyticsScreen(initialPeriod: 'daily'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        hoverColor: Colors.indigo.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.graphic_eq, color: Colors.cyanAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today Agora Audio & Video Minutes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'RTC Voice Calls, Video Calls, Audio Rooms & Live Streams',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total: $totalMins min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4 Metrics Pills
              LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 700;
                  final pillWidth = isDesktop
                      ? (constraints.maxWidth - 36) / 4
                      : (constraints.maxWidth - 12) / 2;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: pillWidth,
                        child: _buildAgoraPill(
                          title: 'Audio Call',
                          minutes: _todayStats.todayAudioMinutes,
                          icon: Icons.call,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(
                        width: pillWidth,
                        child: _buildAgoraPill(
                          title: 'Video Call',
                          minutes: _todayStats.todayVideoMinutes,
                          icon: Icons.videocam,
                          color: const Color(0xFFEC4899),
                        ),
                      ),
                      SizedBox(
                        width: pillWidth,
                        child: _buildAgoraPill(
                          title: 'Audio Room',
                          minutes: _todayStats.todayAudioRoomMinutes,
                          icon: Icons.mic,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      SizedBox(
                        width: pillWidth,
                        child: _buildAgoraPill(
                          title: 'Live Video Room',
                          minutes: _todayStats.todayLiveRoomMinutes,
                          icon: Icons.live_tv,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '👆 Tap to view User-Wise breakdown & Daily / Weekly / Monthly stats',
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgoraPill({
    required String title,
    required int minutes,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$minutes min',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
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
