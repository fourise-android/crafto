import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'create_quotes_page.dart';
import '../Settings/profile_page.dart';

class MainScreen extends StatefulWidget {
  final String email;

  const MainScreen({super.key, required this.email});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(email: widget.email),
      CreateQuotesPage(email: widget.email),
      ProfilePage(email: widget.email),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CreateQuotesPage(email: widget.email)),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: BottomAppBar(
              color: Colors
                  .transparent, // Make the BottomAppBar background transparent
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavigationBarItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildBottomNavigationBarItem(
                    icon: Icons.add_circle_rounded,
                    label: 'Create Quotes',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                    isSpecial: true,
                  ),
                  _buildBottomNavigationBarItem(
                    icon: Icons.person_2_outlined,
                    label: 'Profile',
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: () => _onItemTapped(1),
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Icon(
                  Icons.add_circle_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: isSpecial ? 90 : 60,
        height: isSpecial ? 90 : 75,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!isSpecial)
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds);
                },
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black54,
                  size: 50,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
