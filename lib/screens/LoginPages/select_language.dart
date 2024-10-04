// ignore_for_file: use_key_in_widget_constructors, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pic_poster/screens/HomePage/home_screen.dart';

class SelectLanguage extends StatefulWidget {
  @override
  _SelectLanguageState createState() => _SelectLanguageState();
}

class _SelectLanguageState extends State<SelectLanguage> {
  int _selectedIndex = 1;
  final List<String> _languages = ['Marathi', 'English', 'Hindi', 'Kannada'];
  final List<List<Color>> _colors = [
    [Colors.orange, Colors.red],
    [Colors.blue, Colors.lightBlue],
    [Colors.green, Colors.teal],
    [Colors.purple, Colors.pink],
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedLanguage = prefs.getString('selectedLanguage');
      if (savedLanguage != null) {
        setState(() {
          _selectedIndex = _languages.indexOf(savedLanguage);
        });
      }
    } catch (e) {
      print('Failed to load selected language: $e');
    }
  }

  void _onLanguageSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveLanguageAndNavigate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_selectedIndex != -1) {
      await prefs.setString('selectedLanguage', _languages[_selectedIndex]);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(
            email: '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.31,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Image.asset(
                'assets/images/singup.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 277,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Select Language',
                    style: TextStyle(
                      fontFamily: 'CircularStd',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _onLanguageSelected(index),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _colors[index],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _selectedIndex == index
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _languages[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 52,
                    width: 315,
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30)),
                    child: ElevatedButton(
                      onPressed: _selectedIndex == -1
                          ? null
                          : _saveLanguageAndNavigate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Create Now',
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
