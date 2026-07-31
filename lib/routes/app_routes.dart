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
  static const String sellerManagement = '/seller-management';
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
  static const String blockedUsersManagement = '/blocked-users-management';
  static const String userBanManagement = '/user-ban-management';
  static const String levelSystemManagement = '/level-system-management';
  static const String hostAgencyManagement = '/host-agency-management';
  static const String withdrawalManagement = '/withdrawal-management';
  static const String giftTransactions = '/gift-transactions';
  static const String officialItems = '/official-items';
  static const String bannerManagement = '/banner-management';
  static const String officialChannels = '/official-channels';
  static const String gameManagement = '/game-management';
  static const String customRoomIds = '/custom-room-ids';
  static const String superAdmin = '/super-admin';

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
    'sellerManagement': sellerManagement,
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
    'blockedUsersManagement': blockedUsersManagement,
    'userBanManagement': userBanManagement,
    'levelSystemManagement': levelSystemManagement,
    'hostAgencyManagement': hostAgencyManagement,
    'withdrawalManagement': withdrawalManagement,
    'giftTransactions': giftTransactions,
    'officialItems': officialItems,
    'bannerManagement': bannerManagement,
    'officialChannels': officialChannels,
    'gameManagement': gameManagement,
    'customRoomIds': customRoomIds,
    'superAdmin': superAdmin,
  };

  // Get route name from path
  static String getRouteName(String path) {
    return routes.entries
        .firstWhere((entry) => entry.value == path, orElse: () => MapEntry('dashboard', dashboard))
        .key;
  }

  // Get path from route name
  static String getPath(String routeName) {
    return routes[routeName] ?? dashboard;
  }
}
