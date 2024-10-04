import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pic_poster/screens/Splach/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pic Poster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFF3F5F7)),
        useMaterial3: true,
      ),
      home: WillPopScope(
        onWillPop: () async {
          final shouldPop = await showExitPopup(context);
          return shouldPop ?? false;
        },
        child: SplashScreen(),
      ),
    );
  }

  Future<bool?> showExitPopup(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
