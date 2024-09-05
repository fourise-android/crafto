import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pic_poster/screens/HomePage/main_screen.dart';
import 'package:pic_poster/screens/LoginPages/forgot_password_screen.dart';
import 'package:pic_poster/screens/LoginPages/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else {
        message = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showExitPopup(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/login.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 310,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 315,
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F5F7),
                            labelText: 'Email',
                            hintStyle: const TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 315,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F5F7),
                            labelText: 'Password',
                            hintStyle: const TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF5252C7),
                            fontSize: 14,
                            fontFamily: 'CircularStd',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5151C6), Color(0xFF888BF4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'CircularStd',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignupScreen()),
                              );
                            },
                            child: const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontFamily: 'CircularStd',
                                color: Color(0xFF5252C7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> showExitPopup(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Exit App',
          style: TextStyle(
            fontFamily: 'CircularStd',
            color: Color(0xFF242424),
            fontSize: 30,
          ),
        ),
        content: const Text(
          'Do you want to exit the app?',
          style: TextStyle(
            fontFamily: 'CircularStd',
            color: Color(0xFF242424),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Color(0xFF5252C7))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes',
              style: TextStyle(color: Color(0xFF5252C7)),
            ),
          ),
        ],
      ),
    );
  }
  
}
