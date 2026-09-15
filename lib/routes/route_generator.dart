import 'package:flutter/material.dart';
import '../screens/admin_dashboard.dart';
import '../screens/users_management.dart';
import '../screens/rooms_management.dart';
import '../screens/gift_management.dart';
import '../screens/emoji_management.dart';
import '../screens/diamonds_management.dart';
import '../screens/reports_analytics.dart';
import '../screens/settings_screen.dart';
import '../screens/game_profit_analysis_screen.dart';
import '../screens/user_profile_management.dart';
import '../screens/market_management.dart';
import '../screens/user_history_stats.dart';
import '../screens/blocked_users_management.dart';
import '../screens/user_ban_management_screen.dart';
import '../screens/level_system_management.dart';
import '../screens/intimacy_level_management.dart';
import '../screens/couple_level_management.dart';
import '../screens/host_agency_management.dart';
import '../screens/withdrawal_management.dart';
import '../screens/gift_transactions_screen.dart';
import '../screens/official_items_screen.dart';
import '../screens/realtime_server_setup_screen.dart';
import '../screens/room_create_decoration_screen.dart';
import '../screens/analytics/audio_video_analytics_screen.dart';
import '../screens/analytics/user_registration_analytics_screen.dart';
import '../screens/analytics/recharge_analytics_screen.dart';
import '../screens/analytics/gift_analytics_screen.dart';
import '../screens/analytics/seller_recharge_analytics_screen.dart';
import '../screens/room_game_management_screen.dart';
import '../screens/recharge_wallet_management_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.roomGameManagement:
        return MaterialPageRoute(
          builder: (_) => const RoomGameManagementScreen(),
          settings: settings,
        );
      case AppRoutes.realtimeServerSetup:
        return MaterialPageRoute(
          builder: (_) => const RealtimeServerSetupScreen(),
          settings: settings,
        );
      case AppRoutes.roomCreateDecoration:
        return MaterialPageRoute(
          builder: (_) => const RoomCreateDecorationScreen(),
          settings: settings,
        );
      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
          settings: settings,
        );

      case AppRoutes.users:
        return MaterialPageRoute(
          builder: (_) => const UsersManagement(),
          settings: settings,
        );

      case AppRoutes.rooms:
        return MaterialPageRoute(
          builder: (_) => const RoomsManagement(),
          settings: settings,
        );

      case AppRoutes.gifts:
        return MaterialPageRoute(
          builder: (_) => const GiftManagement(),
          settings: settings,
        );

      case AppRoutes.emojis:
        return MaterialPageRoute(
          builder: (_) => const EmojiManagement(),
          settings: settings,
        );

      case AppRoutes.diamonds:
        return MaterialPageRoute(
          builder: (_) => const DiamondsManagement(),
          settings: settings,
        );

      case AppRoutes.analytics:
        return MaterialPageRoute(
          builder: (_) => const ReportsAnalytics(),
          settings: settings,
        );

      case AppRoutes.gameProfitAnalysis:
        return MaterialPageRoute(
          builder: (_) => const GameProfitAnalysisScreen(),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case AppRoutes.userProfileManagement:
        return MaterialPageRoute(
          builder: (_) => const UserProfileManagement(),
          settings: settings,
        );

      case AppRoutes.marketManagement:
        return MaterialPageRoute(
          builder: (_) => const MarketManagement(),
          settings: settings,
        );

      case AppRoutes.userHistoryStats:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => UserHistoryStats(
            userId: args?['userId'] ?? '',
            username: args?['username'] ?? '',
          ),
          settings: settings,
        );

      case AppRoutes.blockedUsersManagement:
        return MaterialPageRoute(
          builder: (_) => const BlockedUsersManagement(),
          settings: settings,
        );

      case AppRoutes.userBanManagement:
        return MaterialPageRoute(
          builder: (_) => const UserBanManagementScreen(),
          settings: settings,
        );

      case AppRoutes.levelSystemManagement:
        return MaterialPageRoute(
          builder: (_) => const LevelSystemManagement(),
          settings: settings,
        );

      case AppRoutes.intimacyLevelManagement:
        return MaterialPageRoute(
          builder: (_) => const IntimacyLevelManagementScreen(),
          settings: settings,
        );

      case AppRoutes.coupleLevelManagement:
        return MaterialPageRoute(
          builder: (_) => const CoupleLevelManagementScreen(),
          settings: settings,
        );

      case AppRoutes.hostAgencyManagement:
        return MaterialPageRoute(
          builder: (_) => const HostAgencyManagement(),
          settings: settings,
        );

      case AppRoutes.withdrawalManagement:
        return MaterialPageRoute(
          builder: (_) => const WithdrawalManagement(),
          settings: settings,
        );

      case AppRoutes.giftTransactions:
        return MaterialPageRoute(
          builder: (_) => const GiftTransactionsScreen(),
          settings: settings,
        );

      case AppRoutes.officialItems:
        return MaterialPageRoute(
          builder: (_) => const OfficialItemsScreen(),
          settings: settings,
        );

      case AppRoutes.audioVideoAnalytics:
        return MaterialPageRoute(
          builder: (_) => const AudioVideoAnalyticsScreen(),
          settings: settings,
        );

      case AppRoutes.userRegistrationAnalytics:
        return MaterialPageRoute(
          builder: (_) => const UserRegistrationAnalyticsScreen(),
          settings: settings,
        );

      case AppRoutes.rechargeAnalytics:
        return MaterialPageRoute(
          builder: (_) => const RechargeAnalyticsScreen(),
          settings: settings,
        );

      case AppRoutes.giftAnalytics:
        return MaterialPageRoute(
          builder: (_) => const GiftAnalyticsScreen(),
          settings: settings,
        );

      case AppRoutes.sellerRechargeAnalytics:
        return MaterialPageRoute(
          builder: (_) => const SellerRechargeAnalyticsScreen(),
          settings: settings,
        );

      case AppRoutes.rechargeWalletManagement:
        return MaterialPageRoute(
          builder: (_) => const RechargeWalletManagementScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
          settings: settings,
        );
    }
  }

  // Helper method to get current route name
  static String getCurrentRouteName(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name ?? AppRoutes.dashboard;
  }

  // Helper method to check if current route matches
  static bool isCurrentRoute(BuildContext context, String routeName) {
    return getCurrentRouteName(context) == routeName;
  }
}
