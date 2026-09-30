class AppRoutes {
  // Route names
  static const String dashboard = '/';
  static const String users = '/users';
  static const String rooms = '/rooms';
  static const String gifts = '/gifts';
  static const String emojis = '/emojis';
  static const String diamonds = '/diamonds';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  static const String agencyManagement = '/agency-management';
  static const String agencyDashboard = '/agency-dashboard';
  static const String createAgency = '/create-agency';
  static const String agencyCommissionTiers = '/agency-commission-tiers';
  static const String sellerManagement = '/seller-management';
  static const String sellerRequests = '/seller-requests';
  static const String addSeller = '/add-seller';
  static const String sellerDashboard = '/seller-dashboard';
  static const String sellerRecharge = '/seller-recharge';
  static const String sellerHistory = '/seller-history';
  static const String storeManagement = '/store-management';
  static const String addStoreItem = '/add-store-item';
  static const String officialStore = '/official-store';
  static const String assignItem = '/assign-item';
  static const String userProfileManagement = '/user-profile-management';
  static const String marketManagement = '/market-management';
  static const String userHistoryStats = '/user-history-stats';
  static const String usersHistory = '/users-history';
  static const String blockedUsersManagement = '/blocked-users-management';
  static const String userBanManagement = '/user-ban-management';
  static const String levelSystemManagement = '/level-system-management';
  static const String intimacyLevelManagement = '/intimacy-level-management';
  static const String coupleLevelManagement = '/couple-level-management';
  static const String hostAgencyManagement = '/host-agency-management';
  static const String withdrawalManagement = '/withdrawal-management';
  static const String giftTransactions = '/gift-transactions';
  static const String officialItems = '/official-items';
  static const String bannerManagement = '/banner-management';
  static const String officialChannels = '/official-channels';
  static const String gameManagement = '/game-management';
  static const String customRoomIds = '/custom-room-ids';
  static const String superAdmin = '/super-admin';
  static const String subOfficialAdmin = '/sub-official-admin';
  static const String gameProfitAnalysis = '/game-profit-analysis';
  static const String realtimeServerSetup = '/realtime-server-setup';
  static const String roomGameManagement = '/room-game-management';
  static const String roomCreateDecoration = '/room-create-decoration';

  static const String audioVideoAnalytics = '/analytics-audio-video';
  static const String userRegistrationAnalytics = '/analytics-user-registration';
  static const String rechargeAnalytics = '/analytics-recharge';
  static const String giftAnalytics = '/analytics-gifts';
  static const String sellerRechargeAnalytics = '/analytics-seller-recharge';
  static const String rechargeWalletManagement = '/recharge-wallet-management';
  static const String userPositions = '/user-position';
  static const String agencyTransfers = '/agency-transfers';

  // Route paths
  static const Map<String, String> routes = {
    'dashboard': dashboard,
    'users': users,
    'rooms': rooms,
    'gifts': gifts,
    'emojis': emojis,
    'diamonds': diamonds,
    'analytics': analytics,
    'settings': settings,
    'agencyManagement': agencyManagement,
    'agencyDashboard': agencyDashboard,
    'createAgency': createAgency,
    'agencyCommissionTiers': agencyCommissionTiers,
    'agencyTransfers': agencyTransfers,
    'sellerManagement': sellerManagement,
    'sellerRequests': sellerRequests,
    'addSeller': addSeller,
    'sellerDashboard': sellerDashboard,
    'sellerRecharge': sellerRecharge,
    'sellerHistory': sellerHistory,
    'storeManagement': storeManagement,
    'addStoreItem': addStoreItem,
    'officialStore': officialStore,
    'assignItem': assignItem,
    'userProfileManagement': userProfileManagement,
    'marketManagement': marketManagement,
    'userHistoryStats': userHistoryStats,
    'usersHistory': usersHistory,
    'blockedUsersManagement': blockedUsersManagement,
    'userBanManagement': userBanManagement,
    'levelSystemManagement': levelSystemManagement,
    'intimacyLevelManagement': intimacyLevelManagement,
    'coupleLevelManagement': coupleLevelManagement,
    'hostAgencyManagement': hostAgencyManagement,
    'withdrawalManagement': withdrawalManagement,
    'giftTransactions': giftTransactions,
    'officialItems': officialItems,
    'bannerManagement': bannerManagement,
    'officialChannels': officialChannels,
    'gameManagement': gameManagement,
    'customRoomIds': customRoomIds,
    'superAdmin': superAdmin,
    'subOfficialAdmin': subOfficialAdmin,
    'gameProfitAnalysis': gameProfitAnalysis,
    'realtimeServerSetup': realtimeServerSetup,
    'roomGameManagement': roomGameManagement,
    'roomCreateDecoration': roomCreateDecoration,
    'audioVideoAnalytics': audioVideoAnalytics,
    'userRegistrationAnalytics': userRegistrationAnalytics,
    'rechargeAnalytics': rechargeAnalytics,
    'giftAnalytics': giftAnalytics,
    'sellerRechargeAnalytics': sellerRechargeAnalytics,
    'rechargeWalletManagement': rechargeWalletManagement,
  };

  // Get route name from path
  static String getRouteName(String path) {
    return routes.entries
        .firstWhere(
          (entry) => entry.value == path,
          orElse: () => MapEntry('dashboard', dashboard),
        )
        .key;
  }

  // Get path from route name
  static String getPath(String routeName) {
    return routes[routeName] ?? dashboard;
  }
}
