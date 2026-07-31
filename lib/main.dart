import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:imchat_adminpanel/widgets/auth_wrapper.dart';
import 'package:imchat_adminpanel/utils/firebase_debug.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Add a small delay for web production builds
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    
    // Print detailed configuration for debugging
    FirebaseDebug.printConfiguration();
    FirebaseDebug.isConfigurationValid();
    
    // Additional web-specific initialization
    if (kIsWeb) {
      debugPrint('Web-specific Firebase initialization completed');
    }
    
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Don't crash the app, just log the error
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IMChat Admin Panel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
