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
  String companyName = "";
  String businessAddress = "";
  String contactNumber = "";
  String UserContactNumber = "";
  String businessMail = "";
  String BusinessimageUrl = "";
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
        contactNumber = data?['contactNumber'];
        businessMail = data?['businessMail'];

        List<String>? logoUrls = List<String>.from(data?['businessLogoUrls']);
        BusinessimageUrl = logoUrls[0];
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
                      bottom: 0,
                      left: 0,
                      right: 0,
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
                                  isBusiness,
                                  contactNumber,
                                  name,
                                  businessLogoUrl,
                                  businessMail),
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
    bool isBusiness,
    String contactNumber,
    String name,
    String? businessLogoUrl,
    String email,
  ) {
    String imageUrl =
        isBusiness && businessLogoUrl != null && businessLogoUrl.isNotEmpty
            ? businessLogoUrl
            : (photoUrl.isNotEmpty ? photoUrl : 'default_image_url');

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 300,
        child: isBusiness
            ? PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _businessImageNameBarContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessImageNameBarRightContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessWhiteBackgroundContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessSquareImageBagroundContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.grey[300]!,
                    shadowColor: Colors.grey[600]!,
                  ),
                  _businessSquareImageBagroundContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.yellow[300]!,
                    shadowColor: Colors.yellow[600]!,
                  ),
                  _businessSquareImageBagroundContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.orange[300]!,
                    shadowColor: Colors.orange[600]!,
                  ),
                  _businessSquareImageBagroundContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.green[300]!,
                    shadowColor: Colors.green[600]!,
                  ),
                  _businessSquareImageBagroundContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.blue[300]!,
                    shadowColor: Colors.blue[600]!,
                  ),
                  _businessSquareImageBagroundRigthContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.grey[300]!,
                    shadowColor: Colors.grey[600]!,
                  ),
                  _businessSquareImageBagroundRigthContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.yellow[300]!,
                    shadowColor: Colors.yellow[600]!,
                  ),
                  _businessSquareImageBagroundRigthContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.orange[300]!,
                    shadowColor: Colors.orange[600]!,
                  ),
                  _businessSquareImageBagroundRigthContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.green[300]!,
                    shadowColor: Colors.green[600]!,
                  ),
                  _businessSquareImageBagroundRigthContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.blue[300]!,
                    shadowColor: Colors.blue[600]!,
                  ),
                  _businessSquareImageContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessSquareRigthImageContainer(
                      name: name, email: email, imageUrl: imageUrl),
                ],
              )
            : PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _userSquareImageContainer(name, imageUrl),
                  _userSquarerigthImageContainer(name, imageUrl),
                  _userSquareImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.grey[300]!,
                    Colors.grey[600]!,
                  ),
                  _userSquareImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.yellow[300]!,
                    Colors.yellow[600]!,
                  ),
                  _userSquareImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.orange[300]!,
                    Colors.orange[600]!,
                  ),
                  _userSquareImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.green[300]!,
                    Colors.green[600]!,
                  ),
                  _userSquareImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.blue[300]!,
                    Colors.blue[600]!,
                  ),
                  _userSquareRigthImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.grey[300]!,
                    Colors.grey[600]!,
                  ),
                  _userSquareRigthImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.yellow[300]!,
                    Colors.yellow[600]!,
                  ),
                  _userSquareRigthImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.orange[300]!,
                    Colors.orange[600]!,
                  ),
                  _userSquareRigthImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.green[300]!,
                    Colors.green[600]!,
                  ),
                  _userSquareRigthImageBackgroundContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.blue[300]!,
                    Colors.blue[600]!,
                  ),
                  _userimagenamebarWhitecontainer(name, imageUrl),
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.grey.withOpacity(0.5),
                    Colors.grey.withOpacity(0.8),
                  ),
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.yellow[700]!.withOpacity(0.5),
                    Colors.yellow[900]!.withOpacity(0.8),
                  ),
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.orange[700]!.withOpacity(0.5),
                    Colors.orange[900]!.withOpacity(0.8),
                  ),
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.green[700]!.withOpacity(0.5),
                    Colors.green[900]!.withOpacity(0.8),
                  ),
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.blue[700]!.withOpacity(0.5),
                    Colors.blue[900]!.withOpacity(0.8),
                  ),
                  _userwhitebagroundcontainer(name, imageUrl),
                  _userimagenamebarcontainer(name, imageUrl),
                ],
              ),
      ),
    );
  }

  Widget _businessImageNameBarContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;

    return Align(
      alignment: Alignment.bottomLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(BusinessimageUrl),
          ),
          const SizedBox(width: 5),
          Container(
            height: 85,
            width: 270,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      contactNumber,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      businessMail,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessImageNameBarRightContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Row(
          children: [
            Container(
              height: 85,
              width: 270,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        businessMail,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(businessLogoUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessWhiteBackgroundContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(BusinessimageUrl),
          ),
          const SizedBox(width: 12),
          Container(
            height: 55,
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  contactNumber,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  businessMail,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessSquareImageContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(BusinessimageUrl),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          contactNumber,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          businessMail,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _businessSquareImageBagroundContainer({
    required String name,
    required String email,
    required String imageUrl,
    required Color textBackgroundColor,
    required Color shadowColor,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Image Container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(BusinessimageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.6),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 65,
              width: 240,
              decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        businessMail,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessSquareImageBagroundRigthContainer({
    required String name,
    required String email,
    required String imageUrl,
    required Color textBackgroundColor,
    required Color shadowColor,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 65,
              width: 240,
              decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        contactNumber,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        businessMail,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(BusinessimageUrl),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.6),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessSquareRigthImageContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          contactNumber,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          businessMail,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(BusinessimageUrl),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userSquareImageContainer(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 123,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "+91 " + phone,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userSquarerigthImageContainer(String name, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "+91 " + phone,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userSquareImageBackgroundContainer(String name, String imageUrl,
      String phone, Color textBackgroundColor, Color shadowColor) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fitWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.6),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "+91 $phone",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userSquareRigthImageBackgroundContainer(String name, String imageUrl,
      String phone, Color textBackgroundColor, Color shadowColor) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 60,
              width: 240,
              decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "+91 $phone",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.fitWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.6),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userwhitebagroundcontainer(String name, String imageUrl) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 195,
        child: Column(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 12),
            Container(
              width: 400,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userShadowimagecontaineer(String name, String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 12),
            Container(
              height: 60,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    spreadRadius: 2,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "+91 " + phone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _userimagenamebarcontainer(String name, String imageUrl) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: NetworkImage(imageUrl),
          ),
          Container(
            height: 70,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "+91 " + phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userimagenamebarWhitecontainer(String name, String imageUrl) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: CircleAvatar(
              radius: 70,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white70,
                    spreadRadius: 2,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "+91 $phone",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userImageNameBarWhiteShadowContainer(String name, String imageUrl,
      String phone, Color backgroundColor, Color shadowColor) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  const BoxShadow(
                    color: Colors.white70,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: shadowColor, // Secondary shadow color
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
          ),
          // Space between the avatar and text container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              constraints: const BoxConstraints(
                minWidth: 170,
                maxWidth: 230, // Responsive width
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: backgroundColor, // Background color for text container
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white70,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Align(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        "+91 $phone",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
