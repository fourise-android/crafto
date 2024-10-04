// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print, unused_field, use_super_parameters, prefer_final_fields, sized_box_for_whitespace

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pic_poster/screens/HomePage/main_screen.dart';
import 'package:pic_poster/screens/LoginPages/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Ensure password is at least 6 characters long
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters long.')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      final existingUser = await _auth.fetchSignInMethodsForEmail(email);
      if (existingUser.isNotEmpty) {
        User? user = _auth.currentUser;

        if (user != null && user.emailVerified) {
          final userDocument = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDocument.exists) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'email': user.email,
              'name': '',
              'phone': '',
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User details added to Firestore.')),
            );
          }

          _showErrorPopup(
            'An account already exists with this email. Please log in.',
            () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          );
          return;
        }
      }

      _showLoadingPopup('Sending verification email...');

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        Navigator.pop(context);
        _showLoadingPopup('Please check your mailbox and verify your email.');

        await waitForEmailVerification(user, timeoutInSeconds: 300);

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': '',
          'phone': '',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('User details added to Firestore after verification.')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
    }
  }

  Future<void> waitForEmailVerification(User? user,
      {int timeoutInSeconds = 300}) async {
    bool emailVerified = user?.emailVerified ?? false;
    int elapsedSeconds = 0;

    while (!emailVerified && elapsedSeconds < timeoutInSeconds) {
      await Future.delayed(const Duration(seconds: 5));
      await user?.reload();
      user = _auth.currentUser;
      emailVerified = user?.emailVerified ?? false;
      elapsedSeconds += 5;
    }

    if (!emailVerified) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Email verification timed out. Please try again later.')),
      );
      return;
    }

    // Show success popup before navigating to the profile screen
    _showSuccessPopup(
      'Your email verification is successfully completed. Please complete your profile.',
      () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(email: user?.email ?? ''),
          ),
        );
      },
    );
  }

  void _showSuccessPopup(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onConfirm(); // Navigate to the next screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorPopup(String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onConfirm(); // Navigate to LoginScreen
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'CircularStd',
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return false; // Prevents the default back navigation
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
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 315,
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F5F7),
                            labelText: 'Confirm Password',
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
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'CircularStd',
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Do you have an account?",
                            style: TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: Color(0xFF5151C6),
                                fontFamily: 'CircularStd',
                                fontSize: 16,
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
}

class RegisterScreen extends StatefulWidget {
  final String email;

  const RegisterScreen({Key? key, required this.email}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  double _uploadProgress = 0;
  bool _isUploading = false;

  String? _selectedLanguage;
  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Kannada'];

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  Future<void> _uploadImageToFirebase() async {
    if (_nameController.text.isEmpty) {
      _showErrorMessage('Name is required');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showErrorMessage('Email is required');
      return;
    }
    if (_phoneController.text.isEmpty) {
      _showErrorMessage('Phone number is required');
      return;
    }
    if (_phoneController.text.length != 10) {
      _showErrorMessage('Phone number must be 10 digits');
      return;
    }
    if (_imageFile == null) {
      _showErrorMessage('Please select an image');
      return;
    }
    if (_selectedLanguage == null) {
      _showErrorMessage('Please select a preferred language');
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage('User is not authenticated');
      return;
    }

    try {
      setState(() {
        _isUploading = true;
      });

      final userId = user.uid;

      // Reference for the regular profile picture upload
      final storageRefProfile = FirebaseStorage.instance
          .ref()
          .child('User_Images')
          .child(userId)
          .child('DP.jpg');

      // Reference for the secure profile picture upload
      final storageRefSecure = FirebaseStorage.instance
          .ref()
          .child('Secure_User_Images')
          .child(userId)
          .child('Secure_DP.jpg');

      // Upload the regular profile picture
      final uploadTaskProfile =
          storageRefProfile.putFile(File(_imageFile!.path));

      uploadTaskProfile.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = (snapshot.bytesTransferred.toDouble() /
                  snapshot.totalBytes.toDouble()) *
              100;
        });
      });

      final snapshotProfile = await uploadTaskProfile.whenComplete(() {});
      final downloadUrlProfile = await snapshotProfile.ref.getDownloadURL();

      // Upload the secure profile picture
      final uploadTaskSecure = storageRefSecure.putFile(File(_imageFile!.path));

      final snapshotSecure = await uploadTaskSecure.whenComplete(() {});
      final downloadUrlSecure = await snapshotSecure.ref.getDownloadURL();

      // Store user details with both profile picture URLs
      await _storeUserDetails(downloadUrlProfile, downloadUrlSecure);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainScreen(email: user.email!),
        ),
      );
    } on FirebaseException catch (e) {
      Navigator.pop(context);
      _showErrorMessage('Error uploading image: ${e.message}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

// Method to show error messages
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Method to store user details in Firestore with both URLs
  Future<void> _storeUserDetails(
      String downloadUrlProfile, String downloadUrlSecure) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('user_details').doc(user.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'profileImage': downloadUrlProfile,
        'secureProfileImage': downloadUrlSecure,
        'preferredLanguage': _selectedLanguage,
      });
    } catch (e) {
      print('Error storing user details: $e');
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
              height: screenHeight * 0.35,
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
            top: 310,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildTextField(_nameController, 'Name'),
                    _buildTextField(_emailController, 'Email',
                        isReadOnly: true),
                    _buildPhoneField(),
                    _buildLanguageDropdown(),
                    if (_uploadProgress > 0) ...[
                      const SizedBox(height: 20),
                      LinearProgressIndicator(value: _uploadProgress / 100),
                      const SizedBox(height: 20),
                    ],
                    _buildSignUpButton(),
                    const SizedBox(height: 20),
                    _buildSignInLink(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 135,
            top: 220,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path))
                    : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt,
                        color: Colors.white, size: 30)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isReadOnly = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: 315,
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F5F7),
          labelText: label,
          hintStyle: const TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: 315,
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F5F7),
          labelText: 'Phone Number',
          hintStyle: const TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        maxLength: 10,
        onChanged: (text) {
          if (text.length > 10) {
            _phoneController.text = text.substring(0, 10);
            _phoneController.selection = TextSelection.fromPosition(
              TextPosition(offset: _phoneController.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: 315,
      child: DropdownButtonFormField<String>(
        value: _selectedLanguage,
        onChanged: (String? newValue) {
          setState(() {
            _selectedLanguage = newValue;
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F5F7),
          labelText: 'Preferred Language',
          hintStyle: const TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        items: _languages.map((String language) {
          return DropdownMenuItem<String>(
            value: language,
            child: Text(language),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: 315,
      height: 52,
      child: ElevatedButton(
        onPressed: _uploadImageToFirebase,
        style: ButtonStyle(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          backgroundColor: MaterialStateProperty.all(
            const Color(0xFF888BF4),
          ),
        ),
        child: const Text(
          'Sign Up',
          style: TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Already have an account?"),
          Text(
            ' Sign In',
            style: TextStyle(
              fontFamily: 'CircularStd',
              fontSize: 16,
              color: Color(0xFF888BF4),
            ),
          ),
        ],
      ),
    );
  }
}
