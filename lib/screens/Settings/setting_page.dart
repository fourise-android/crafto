// ignore_for_file: file_names, use_build_context_synchronously, sort_child_properties_last

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pic_poster/screens/Settings/about_us_page.dart';
import 'package:pic_poster/screens/Settings/contact_us.dart';
import 'package:pic_poster/screens/Settings/profile_page.dart';
import 'package:pic_poster/screens/LoginPages/login_screen.dart';

class SettingPage extends StatefulWidget {
  final String email;

  const SettingPage({super.key, required this.email});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_details')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      throw Exception("Error fetching user details: $e");
    }
  }

  Future<String> _fetchProfilePhotoUrl() async {
    try {
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('User_Images/$uid/DP.jpg');
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception("Error fetching profile photo: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  Future<void> _changeLanguage(BuildContext context) async {
    final List<String> languages = ['English', 'Hindi', 'Marathi', 'Gujarati'];
    String? selectedLanguage;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((String language) {
              return RadioListTile<String>(
                title: Text(language),
                value: language,
                groupValue: selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    selectedLanguage = value;
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selectedLanguage != null) {
      try {
        await FirebaseFirestore.instance
            .collection('user_details')
            .doc(uid)
            .update({'preferredLanguage': selectedLanguage});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language changed to $selectedLanguage')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing language: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double fontSize = widget.email.length <= 20 ? 9.0 : 12.0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Center(child: Text('Settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No user data found.'));
          } else {
            final userData = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProfilePage(email: widget.email),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1FE),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          FutureBuilder<String>(
                            future: _fetchProfilePhotoUrl(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircleAvatar(
                                  radius: 40,
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return const CircleAvatar(
                                  radius: 40,
                                  child: Icon(Icons.error),
                                );
                              } else if (!snapshot.hasData) {
                                return const CircleAvatar(
                                  radius: 40,
                                  child: Icon(Icons.person),
                                );
                              } else {
                                return CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(snapshot.data!),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData['name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'CircularStd',
                                ),
                              ),
                              Text(
                                widget.email,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.grey,
                                  fontFamily: 'CircularStd',
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Other Settings",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'CircularStd',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSettingButton(
                    icon: Icons.contact_mail,
                    label: 'Contact Us',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactFormPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSettingButton(
                    icon: Icons.language,
                    label: 'Change Language',
                    onPressed: () => _changeLanguage(context),
                  ),
                  const SizedBox(height: 10),
                  _buildSettingButton(
                    icon: Icons.info,
                    label: 'About Us',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildSettingButton(
                    icon: Icons.logout,
                    label: 'Logout',
                    onPressed: _logout,
                    textColor: Colors.black,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSettingButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFFF6F7F9),
    Color textColor = Colors.black,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
