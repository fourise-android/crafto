import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditQuote extends StatefulWidget {
  final File image;
  final String uid;
  final String email;

  const EditQuote(
      {required this.image, required this.uid, required this.email});

  @override
  _EditQuoteState createState() => _EditQuoteState();
}

class _EditQuoteState extends State<EditQuote> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool isBusiness = false;
  String name = '';
  String photoUrl = '';
  String businessLogoUrl = '';
  String phone = '';
  bool isPickingImage = false;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('userName') ?? '';
      photoUrl = prefs.getString('profilePhotoUrl') ?? '';
      phone = prefs.getString('userPhone') ?? '';
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

  Future<String> fetchName(bool isBusiness, String uid) async {
    String name = '';
    if (isBusiness) {
      final businessDoc = await FirebaseFirestore.instance
          .collection('business_information')
          .doc(uid)
          .get();
      if (businessDoc.exists) {
        final data = businessDoc.data();
        name = data?['companyName'] ?? '';
      }
    } else {
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

  Future<void> _showBusinessUpdateDialog() async {
    final document = await FirebaseFirestore.instance
        .collection('business_information')
        .doc(widget.uid)
        .get();
    final data = document.data() as Map<String, dynamic>?;

    String companyName = data?['companyName'] ?? '';
    String businessAddress = data?['businessAddress'] ?? '';
    String contactNumber = data?['contactNumber'] ?? '';
    String businessMail = data?['businessMail'] ?? '';
    final List<String> storedImageUrls =
        List<String>.from(data?['businessLogoUrls'] ?? []);

    final TextEditingController companyNameController =
        TextEditingController(text: companyName);
    final TextEditingController businessAddressController =
        TextEditingController(text: businessAddress);
    final TextEditingController contactNumberController =
        TextEditingController(text: contactNumber);
    final TextEditingController businessMailController =
        TextEditingController(text: businessMail);

    List<String> imageUrls = List.from(storedImageUrls);
    String selectedImageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

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
                TextField(
                  controller: companyNameController,
                  decoration: const InputDecoration(labelText: "Company Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: businessAddressController,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactNumberController,
                  decoration:
                      const InputDecoration(labelText: "Contact Number"),
                ),
                const SizedBox(height: 10),
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

                Map<String, dynamic> updatedData = {
                  'companyName': newCompanyName,
                  'businessAddress': newBusinessAddress,
                  'contactNumber': newContactNumber,
                  'businessMail': newBusinessMail,
                };

                if (selectedImageUrl.isNotEmpty) {
                  updatedData['businessLogoUrls'] = imageUrls;
                }

                await FirebaseFirestore.instance
                    .collection('business_information')
                    .doc(widget.uid)
                    .set(updatedData);

                Navigator.of(context).pop();
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPersonalUpdateDialog() async {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController phoneController =
        TextEditingController(text: phone);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Personal Details"),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 10),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
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
                String newName = nameController.text;
                String newPhone = phoneController.text;

                String newPhotoUrl = photoUrl;

                if (!photoUrl.startsWith('http')) {
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

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height / 2;
    double containerWidth = containerHeight * 3 / 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Image Details')),
      body: Column(
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
                    color:
                        isBusiness ? Colors.lightBlue[100] : Colors.transparent,
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
          const SizedBox(height: 10),
          Container(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: screenshotController,
                child: Stack(
                  children: [
                    Container(
                      width: containerWidth,
                      height: containerHeight,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.file(
                          widget.image,
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
                            return GestureDetector(
                              onTap: () async {
                                if (isBusiness) {
                                  _showBusinessUpdateDialog();
                                } else {
                                  _showPersonalUpdateDialog();
                                }
                              },
                              child: _buildUserPhotoAndName(
                                  isBusiness, name, photoUrl, businessLogoUrl),
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
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
        ],
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
}
