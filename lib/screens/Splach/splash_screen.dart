// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pic_poster/Controllers/storagepermission.dart';
import 'package:pic_poster/screens/HomePage/main_screen.dart';
import 'package:pic_poster/screens/Splach/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StoragePermissionManager permissionManager = StoragePermissionManager();
  

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    permissionManager.requestStoragePermission;
  }

  Future<void> _checkUserStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    User? user = _auth.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen(email: user.email ?? '')),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset('assets/images/splash.png'),
      ),
    );
  }
}
