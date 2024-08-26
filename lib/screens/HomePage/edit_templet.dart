// ignore_for_file: use_super_parameters, use_build_context_synchronously, sized_box_for_whitespace

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditTemplet extends StatefulWidget {
  final String imageUrl;
  final String userName;
  final String profilePhotoUrl;

  const EditTemplet({
    Key? key,
    required this.imageUrl,
    required this.userName,
    required this.profilePhotoUrl,
  }) : super(key: key);

  @override
  State<EditTemplet> createState() => _EditTempletState();
}

class _EditTempletState extends State<EditTemplet> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool isBusiness = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  String name = "";
  String photoUrl = "";
  String businessLogoUrl = "";
  bool isPickingImage = false;
  // Additional fields for business
  String companyName = "";
  String businessAddress = "";
  String contactNumber = "";
  String phone = "";
  String businessMail = "";
  List<String> storedImageUrls = [];
  List<String> imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? widget.userName;
      photoUrl = prefs.getString('profilePhotoUrl') ?? widget.profilePhotoUrl;
      phone = prefs.getString('userPhone') ?? "";
    });
  }

  Future<void> _updateUserData(
      String newName, String newPhotoUrl, String newPhone) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = newName;
      photoUrl = newPhotoUrl;
      phone = newPhone;
    });
    await prefs.setString('userName', newName);
    await prefs.setString('profilePhotoUrl', newPhotoUrl);
    await prefs.setString('userPhone', newPhone);
  }

  Future<String?> _pickImage({required bool isBusinessLogo}) async {
    if (isPickingImage) return null;

    setState(() {
      isPickingImage = true;
    });

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (isBusinessLogo) {
            businessLogoUrl = pickedFile.path;
          } else {
            photoUrl = pickedFile.path;
          }
        });
        return pickedFile.path;
      } else {
        return null;
      }
    } finally {
      setState(() {
        isPickingImage = false;
      });
    }
  }

  Future<String> fetchName(bool isBusiness, String uid) async {
    String name = '';

    if (isBusiness) {
      // Fetch from 'business_information' collection for business users
      final businessDoc = await FirebaseFirestore.instance
          .collection('business_information')
          .doc(uid)
          .get();

      if (businessDoc.exists) {
        final data = businessDoc.data();
        name = data?['companyName'] ?? '';
      }
    } else {
      // Fetch from 'user_details' collection for regular users
      final userDoc = await FirebaseFirestore.instance
          .collection('user_details')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        name = data?['name'] ?? '';
      }
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Desing",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 20,
            fontFamily: 'CircularStd',
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: !isBusiness
                          ? Colors.lightBlue[100]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isBusiness = false;
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        "Personal",
                        style: TextStyle(
                          color: !isBusiness ? Colors.blueAccent : Colors.black,
                          fontSize: 16,
                          fontFamily: 'CircularStd',
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBusiness
                          ? Colors.lightBlue[100]
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          isBusiness = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        "Business",
                        style: TextStyle(
                          color: isBusiness ? Colors.blueAccent : Colors.black,
                          fontSize: 16,
                          fontFamily: 'CircularStd',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 5,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Screenshot(
                    controller: screenshotController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: FutureBuilder<String>(
                                future: fetchName(isBusiness, uid),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return const Center(
                                        child: Text('Error fetching name'));
                                  } else if (snapshot.hasData) {
                                    final name = snapshot.data ?? '';
                                    return Positioned(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                      child: GestureDetector(
                                        onTap: () async {
                                          if (isBusiness) {
                                            _showBusinessUpdateDialog();
                                          } else {
                                            _showPersonalUpdateDialog();
                                          }
                                        },
                                        child: _buildUserPhotoAndName(
                                            isBusiness,
                                            name,
                                            photoUrl,
                                            businessLogoUrl),
                                      ),
                                    );
                                  } else {
                                    return const Center(
                                        child: Text('No name available'));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    await _shareScreenshot();
                  },
                  child: Container(
                    height: 36,
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Text(
                        "Share",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'CircularStd',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () async {
                    await _downloadScreenshot(context);
                  },
                  child: Container(
                    height: 36,
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Download",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (isBusiness) {
                  _showBusinessUpdateDialog();
                } else {
                  _showPersonalUpdateDialog();
                }
              },
              child: Text(isBusiness
                  ? "Update Business Details"
                  : "Update Personal Details"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPhotoAndName(
      bool isBusiness, String name, String? photoUrl, String? businessLogoUrl) {
    String imageUrl =
        isBusiness && businessLogoUrl != null && businessLogoUrl.isNotEmpty
            ? businessLogoUrl
            : (photoUrl != null && photoUrl.isNotEmpty
                ? photoUrl
                : 'default_image_url');

    return Container(
      height: 100,
      child: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildSingleContainer(name, imageUrl),
          _buildSquareContainer(name, imageUrl),
          _buildSingleContainer(name, imageUrl),
        ],
      ),
    );
  }

  Widget _buildSingleContainer(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareContainer(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 5,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareScreenshot() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/screenshot.png').create();
    await imagePath.writeAsBytes(image);

    Share.shareXFiles([XFile(imagePath.path)], text: 'Check out this image!');
  }

  Future<void> _downloadScreenshot(BuildContext context) async {
    await Permission.storage.request();
    final image = await screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        File('${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png');
    await imagePath.writeAsBytes(image);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screenshot saved to gallery')),
    );
  }

  Future<void> _showPersonalUpdateDialog() async {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController phoneController =
        TextEditingController(text: phone);

    // Fetch all images from the user's folder
    List<String> userImages = await _fetchUserImages();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Personal Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  await _pickImage(isBusinessLogo: false);
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: photoUrl.isNotEmpty
                      ? (photoUrl.startsWith('http')
                          ? NetworkImage(photoUrl)
                          : FileImage(File(photoUrl)) as ImageProvider)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: userImages.map((imageUrl) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          photoUrl = imageUrl;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: photoUrl == imageUrl
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                String newName = nameController.text;
                String newPhone = phoneController.text;

                String newPhotoUrl = photoUrl;

                if (photoUrl != widget.profilePhotoUrl) {
                  newPhotoUrl = await _uploadImage(photoUrl);
                }

                await _updateUserData(newName, newPhotoUrl, newPhone);

                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _fetchUserImages() async {
    final storageReference =
        FirebaseStorage.instance.ref().child("User_Images/$uid/");

    final ListResult result = await storageReference.listAll();
    final List<String> imageUrls = [];

    for (var item in result.items) {
      final String downloadUrl = await item.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  Future<List<String>> _fetchBusinessImages() async {
    final storageReference =
        FirebaseStorage.instance.ref().child("business_images/$uid/");

    final ListResult result = await storageReference.listAll();
    final List<String> imageUrls = [];

    for (var item in result.items) {
      final String downloadUrl = await item.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  Future<String> _uploadImage(String filePath) async {
    final storageReference =
        FirebaseStorage.instance.ref().child("User_Images/$uid/");

    final ListResult result = await storageReference.listAll();
    final List<Reference> allFiles = result.items;

    int imageIndex = 1;
    String newFileName;
    do {
      newFileName = "image$imageIndex.jpg";
      imageIndex++;
    } while (allFiles.any((file) => file.name == newFileName));

    final newImageReference = storageReference.child(newFileName);

    final uploadTask = newImageReference.putFile(File(filePath));
    final completedTask = await uploadTask.whenComplete(() {});

    return await completedTask.ref.getDownloadURL();
  }

  Future<void> loadImages() async {
    try {
      final ListResult result =
          await FirebaseStorage.instance.ref('business_images/$uid').listAll();

      final List<String> urls = await Future.wait(
        result.items.map((Reference ref) => ref.getDownloadURL()).toList(),
      );

      setState(() {
        imageUrls = urls;
      });
    } catch (e) {
      print('Failed to load images: $e');
    }
  }

  void _onImageTap(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              const SizedBox(height: 16),
              const Text('You selected this image.'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

    Future<void> _showBusinessUpdateDialog() async {
      // Fetch the current data
      final document = await FirebaseFirestore.instance
          .collection('business_information')
          .doc(uid)
          .get();
      final data = document.data() as Map<String, dynamic>?;

      String companyName = data?['companyName'] ?? '';
      String businessAddress = data?['businessAddress'] ?? '';
      String contactNumber = data?['contactNumber'] ?? '';
      String businessMail = data?['businessMail'] ?? '';
      final List<String> storedImageUrls =
          List<String>.from(data?['businessLogoUrls'] ?? []);

      // Initialize controllers with the fetched data
      final TextEditingController companyNameController =
          TextEditingController(text: companyName);
      final TextEditingController businessAddressController =
          TextEditingController(text: businessAddress);
      final TextEditingController contactNumberController =
          TextEditingController(text: contactNumber);
      final TextEditingController businessMailController =
          TextEditingController(text: businessMail);

      List<String> userImages = await _fetchBusinessImages();
      List<String> imageUrls = List.from(storedImageUrls);
      String selectedImageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

      // Flag to check if an image is selected
      bool imageSelected = false;

      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Update Business Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GestureDetector(
                    onTap: () async {
                      final imageUrl = await _pickImage(isBusinessLogo: true);
                      if (imageUrl != null) {
                        setState(() {
                          selectedImageUrl = imageUrl;
                          imageUrls.insert(0, imageUrl);
                          imageSelected = true;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: selectedImageUrl.isNotEmpty
                          ? NetworkImage(selectedImageUrl)
                          : null,
                      child: selectedImageUrl.isEmpty
                          ? const Icon(Icons.add_a_photo)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: userImages.map((imageUrl) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              photoUrl = imageUrl;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: photoUrl == imageUrl
                                    ? Colors.blue
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  TextField(
                    controller: companyNameController,
                    decoration: const InputDecoration(labelText: "Company Name"),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: businessAddressController,
                    decoration: const InputDecoration(labelText: "Address"),
                  ),
                  TextField(
                    controller: contactNumberController,
                    decoration:
                        const InputDecoration(labelText: "Contact Number"),
                  ),
                  TextField(
                    controller: businessMailController,
                    decoration: const InputDecoration(labelText: "Business Mail"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String newCompanyName = companyNameController.text;
                  String newBusinessAddress = businessAddressController.text;
                  String newContactNumber = contactNumberController.text;
                  String newBusinessMail = businessMailController.text;

                  // Prepare the updated data
                  Map<String, dynamic> updatedData = {
                    'companyName': newCompanyName,
                    'businessAddress': newBusinessAddress,
                    'contactNumber': newContactNumber,
                    'businessMail': newBusinessMail,
                  };

                  // If an image was selected, update the image URLs
                  if (imageSelected) {
                    for (int i = 0; i < imageUrls.length; i++) {
                      imageUrls[i] =
                          await _uploadBusinessImage(imageUrls[i], uid, i + 1);
                    }
                    updatedData['businessLogoUrls'] = imageUrls;
                  }

                  await FirebaseFirestore.instance
                      .collection('business_information')
                      .doc(uid)
                      .set(updatedData);

                  setState(() {
                    companyName = newCompanyName;
                    businessAddress = newBusinessAddress;
                    contactNumber = newContactNumber;
                    businessMail = newBusinessMail;
                    if (imageUrls.isNotEmpty) {
                      businessLogoUrl = imageUrls[0];
                    }
                  });

                  Navigator.of(context).pop();
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      );
    }

    Future<String> _uploadBusinessImage(
        String imagePath, String uid, int index) async {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('business_images/$uid/image_$index.jpg');
      final uploadTask = storageRef.putFile(File(imagePath));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
  }
