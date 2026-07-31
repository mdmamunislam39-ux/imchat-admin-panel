import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToAndReplace(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }

  static Future<dynamic> navigateToAndClearStack(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  static void goBack([dynamic result]) {
    return navigatorKey.currentState!.pop(result);
  }

  static void goBackUntil(String routeName) {
    return navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }

  static bool canGoBack() {
    return navigatorKey.currentState!.canPop();
  }

  // Specific navigation methods for each screen
  static Future<dynamic> goToDashboard() {
    return navigateToAndReplace(AppRoutes.dashboard);
  }

  static Future<dynamic> goToUsers() {
    return navigateTo(AppRoutes.users);
  }

  static Future<dynamic> goToRooms() {
    return navigateTo(AppRoutes.rooms);
  }

  static Future<dynamic> goToGifts() {
    return navigateTo(AppRoutes.gifts);
  }

  static Future<dynamic> goToEmojis() {
    return navigateTo(AppRoutes.emojis);
  }

  static Future<dynamic> goToDiamonds() {
    return navigateTo(AppRoutes.diamonds);
  }

  static Future<dynamic> goToAnalytics() {
    return navigateTo(AppRoutes.analytics);
  }

  static Future<dynamic> goToSettings() {
    return navigateTo(AppRoutes.settings);
  }

  // Get current route name
  static String getCurrentRouteName() {
    final route = ModalRoute.of(currentContext!);
    return route?.settings.name ?? AppRoutes.dashboard;
  }

  // Check if current route matches
  static bool isCurrentRoute(String routeName) {
    return getCurrentRouteName() == routeName;
  }
}
