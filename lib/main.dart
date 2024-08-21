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
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFF3F5F7)),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
