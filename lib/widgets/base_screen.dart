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

class BaseScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showDrawer;
  final bool showBackButton;
  final Widget? floatingActionButton;

  const BaseScreen({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showDrawer = true,
    this.showBackButton = false,
    this.floatingActionButton,
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
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
            decoration: BoxDecoration(
              color: Colors.black,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
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
      case 'Daily Check-in':
        screen = const DailyCheckInManagementScreen();
        break;
      case 'Reports & Analytics':
        screen = const ReportsAnalytics();
        break;
      case 'Settings':
        screen = const SettingsScreen();
        break;
      default:
        return; // Don't navigate if screen not found
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildLogoutItem(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout,
        color: Colors.red,
        size: 24,
      ),
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
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}