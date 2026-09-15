import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import '../services/auth_service.dart';
import '../screens/users_management.dart';
import '../screens/rooms_management.dart';
import '../screens/gift_management.dart';
import '../screens/emoji_management.dart';
import '../screens/diamonds_management.dart';
import '../screens/reports_analytics.dart';
import '../screens/settings_screen.dart';
import '../screens/daily_checkin_management.dart';
import '../screens/room_frame_management.dart';
import '../screens/user_ban_management_screen.dart';
import '../screens/game_profit_analysis_screen.dart';
import '../screens/realtime_server_setup_screen.dart';
import '../screens/html5_game_management_screen.dart';
import '../screens/room_game_management_screen.dart';
import '../screens/recharge_wallet_management_screen.dart';

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final bool showBackButton;
  final Widget? floatingActionButton;

  final PreferredSizeWidget? bottom;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = true,
    this.showBackButton = false,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: actions,
        bottom: bottom,
      ),
      drawer: showDrawer ? _buildDrawer(context) : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'IMChat Management',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
                (route) => false,
              );
            },
            isSelected: title == 'Admin Dashboard',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'Users',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Users Management');
            },
            isSelected: title == 'Users Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.room,
            title: 'Audio Rooms',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Rooms Management');
            },
            isSelected: title == 'Rooms Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.gavel,
            title: 'Ban Management',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Ban Management');
            },
            isSelected: title == 'User Ban Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.filter_frames,
            title: 'Room Frames',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Room Frames');
            },
            isSelected: title == 'Room Profile Frames',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.card_giftcard,
            title: 'Gifts',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Gifts Management');
            },
            isSelected: title == 'Gift Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.emoji_emotions,
            title: 'Emojis',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Emojis Management');
            },
            isSelected: title == 'Emoji Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.diamond,
            title: 'Diamonds Management',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Diamonds Management');
            },
            isSelected: title == 'Diamonds Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Recharge Wallet Management',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Recharge Wallet Management');
            },
            isSelected: title == 'Recharge Wallet Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.calendar_month,
            title: 'Daily Check-in',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Daily Check-in');
            },
            isSelected: title == 'Daily Check-in Management',
          ),
          const Divider(color: Colors.grey),
          _buildDrawerItem(
            context,
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Reports & Analytics');
            },
            isSelected: title == 'Reports & Analytics',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.sports_esports,
            title: '🎮 HTML 5 Game',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'HTML 5 Game');
            },
            isSelected: title == 'HTML 5 Game Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.meeting_room_rounded,
            title: 'Room Game Management',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Room Game Management');
            },
            isSelected: title == 'Room Game Management',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.pie_chart,
            title: 'Game Profit & Analysis',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Game Profit & Analysis');
            },
            isSelected: title == 'Game Profit & Analysis',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.dns,
            title: 'রিয়েল টাইম সার্ভার সেটআপ',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Realtime Server Setup');
            },
            isSelected: title == 'Realtime Server Setup',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              _navigateToScreen(context, 'Settings');
            },
            isSelected: title == 'Settings',
          ),
          const Divider(color: Colors.grey),
          _buildLogoutItem(context),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
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
    );
  }

  void _navigateToScreen(BuildContext context, String screenName) {
    Widget screen;

    switch (screenName) {
      case 'Users Management':
        screen = const UsersManagement();
        break;
      case 'Rooms Management':
        screen = const RoomsManagement();
        break;
      case 'Ban Management':
        screen = const UserBanManagementScreen();
        break;
      case 'Room Frames':
        screen = const RoomFrameManagementScreen();
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
      case 'HTML 5 Game':
        screen = const Html5GameManagementScreen();
        break;
      case 'Room Game Management':
        screen = const RoomGameManagementScreen();
        break;
      case 'Realtime Server Setup':
        screen = const RealtimeServerSetupScreen();
        break;
      case 'Settings':
        screen = const SettingsScreen();
        break;
      default:
        return; // Don't navigate if screen not found
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
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
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
}
