import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/admin_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await AdminAuthService.checkPersistedLogin();
      
      final isAuth = AdminAuthService.isAuthenticated;
      
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
      
      debugPrint('Auth state checked: $_isAuthenticated');
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  // Method to refresh auth state (can be called from login screen)
  void refreshAuthState() {
    _checkAuthState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    if (_isAuthenticated) {
      return const AdminDashboard();
    }
    
    return LoginScreen(onLoginSuccess: refreshAuthState);
  }
}
