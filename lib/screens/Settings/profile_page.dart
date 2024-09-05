import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String email;

  const ProfilePage({Key? key, required this.email}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedLanguage;
  final List<String> _languages = ['English', 'Hindi', 'Marathi', 'Gujarati'];
  String? _profileImageUrl;
  double _uploadProgress = 0;
  bool _isLoading = true;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_details')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _selectedLanguage = data['preferredLanguage'] ?? _languages.first;
          _profileImageUrl = data['profileImage'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone number are required')),
      );
      return;
    }

    if (_phoneController.text.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be 13 digits')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? downloadUrl;

    if (_imageFile != null) {
      if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
        final previousImageRef =
            FirebaseStorage.instance.refFromURL(_profileImageUrl!);
        try {
          await previousImageRef.delete();
        } catch (e) {
          print('Error deleting previous image: $e');
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Updating Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _uploadProgress / 100),
                const SizedBox(height: 20),
                Text('${_uploadProgress.toStringAsFixed(0)}%'),
              ],
            ),
          );
        },
      );

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('User_Images')
            .child(user.uid)
            .child('DP.jpg');

        final uploadTask = storageRef.putFile(File(_imageFile!.path));

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          setState(() {
            _uploadProgress = (snapshot.bytesTransferred.toDouble() /
                    snapshot.totalBytes.toDouble()) *
                100;
          });
        });

        final snapshot = await uploadTask.whenComplete(() {});
        downloadUrl = await snapshot.ref.getDownloadURL();

        Navigator.pop(context);
      } on FirebaseException catch (e) {
        Navigator.pop(context);
        print('Error uploading image: ${e.message}');
        return;
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('user_details')
          .doc(user.uid)
          .update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileImage': downloadUrl ?? _profileImageUrl,
        'preferredLanguage': _selectedLanguage,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Your profile has been updated successfully!'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF3F5F7),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  backgroundImage: _imageFile != null
                      ? FileImage(File(_imageFile!.path))
                      : (_profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : null),
                  child: _imageFile == null && _profileImageUrl == null
                      ? const Icon(Icons.camera_alt,
                          color: Colors.white, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7F9),
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontFamily: 'CircularStd',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'CircularStd',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7F9),
                ),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(
                      color: Colors.black, // Label text color
                      fontSize: 16, // Label text size
                      fontFamily: 'CircularStd', // Label font family
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color when focused
                        width: 1.0, // Border width when focused
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black, // Text color
                    fontSize: 16, // Text size
                    fontFamily: 'CircularStd', // Font family
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  },
                  items: _languages.map((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(
                        language,
                        style: const TextStyle(
                          color: Colors.black, // Text color
                          fontSize: 16, // Text size
                          fontFamily: 'CircularStd', // Font family
                        ),
                      ),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'Preferred Language',
                    // ignore: prefer_const_constructors
                    labelStyle: TextStyle(
                      color: Colors.black, // Label text color
                      fontSize: 16, // Label text size
                      fontFamily: 'CircularStd', // Label font family
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color when focused
                        width: 1.0, // Border width when focused
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color
                        width: 1.0, // Border width
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black, // Text color
                    fontSize: 16, // Text size
                    fontFamily: 'CircularStd', // Font family
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity, // Fills the width of the parent
                height: 52, // Set the height of the button
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                      15), // Optional: Add border radius for rounded corners
                ),
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors
                        .transparent, // Set background color to transparent so the gradient is visible
                    shadowColor: Colors.transparent, // Remove shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15), // Match the container's border radius
                    ),
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(
                      color: Colors.white, // Text color
                      fontSize: 16, // Text size
                      fontFamily: 'CircularStd', // Font family
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
