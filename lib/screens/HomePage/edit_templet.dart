// ignore_for_file: use_super_parameters, use_build_context_synchronously, sized_box_for_whitespace

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
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
  String companyName = "";
  String businessAddress = "";
  String contactNumber = "";
  String UserContactNumber = "";
  String phone = "";
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

  Future<void> _showBusinessUpdateDialog() async {
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
                            selectedImageUrl = imageUrl;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedImageUrl == imageUrl
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

                Map<String, dynamic> updatedData = {
                  'companyName': newCompanyName,
                  'businessAddress': newBusinessAddress,
                  'contactNumber': newContactNumber,
                  'businessMail': newBusinessMail,
                };

                if (imageSelected) {
                  for (int i = 0; i < imageUrls.length; i++) {
                    String newUrl =
                        await _uploadBusinessImage(imageUrls[i], uid, i + 1);
                    if (newUrl.isNotEmpty) {
                      imageUrls[i] = newUrl;
                    }
                  }
                  updatedData['businessLogoUrls'] = imageUrls;
                }

                await FirebaseFirestore.instance
                    .collection('business_information')
                    .doc(uid)
                    .set(updatedData, SetOptions(merge: true));

                setState(() {
                  companyName = newCompanyName;
                  businessAddress = newBusinessAddress;
                  contactNumber = newContactNumber;
                  businessMail = newBusinessMail;
                  if (imageUrls.isNotEmpty) {
                    selectedImageUrl = imageUrls[0];
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
        height: MediaQuery.of(context).size.width * 0.68,
        width: MediaQuery.of(context).size.width * 0.999,
        child: isBusiness
            ? PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _businessWhiteBackgroundContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessImageNameBarRightContainer(
                      name: name, email: email, imageUrl: imageUrl),
                  _businessImageNameBarContainer(
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
                  _businessImageNameBarWhiteShadowContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.grey.withOpacity(0.5),
                    shadowColor: Colors.grey.withOpacity(0.8),
                  ),
                  _businessImageNameBarWhiteShadowContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.yellow[700]!.withOpacity(0.5),
                    shadowColor: Colors.yellow[900]!.withOpacity(0.8),
                  ),
                  _businessImageNameBarWhiteShadowContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.orange[700]!.withOpacity(0.5),
                    shadowColor: Colors.orange[900]!.withOpacity(0.8),
                  ),
                  _businessImageNameBarWhiteShadowContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.green[700]!.withOpacity(0.5),
                    shadowColor: Colors.green[900]!.withOpacity(0.8),
                  ),
                  _businessImageNameBarWhiteShadowContainer(
                    name: name,
                    email: email,
                    imageUrl: imageUrl,
                    textBackgroundColor: Colors.blue[700]!.withOpacity(0.5),
                    shadowColor: Colors.blue[900]!.withOpacity(0.8),
                  ),
                ],
              )
            : PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  _userSquareImageContainer(name, imageUrl),
                  _userSquarerigthImageContainer(name, imageUrl),
                  _userimagenamebarWhitecontainer(name, imageUrl),
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
                  _userImageNameBarWhiteShadowContainer(
                    name,
                    imageUrl,
                    phone,
                    Colors.grey.withOpacity(0.5),
                    Colors.grey.withOpacity(0.8),
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

  Widget _businessImageNameBarRightContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.09,
              width: MediaQuery.of(context).size.height * 0.30109,
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
              radius: MediaQuery.of(context).size.width * 0.14,
              backgroundImage: NetworkImage(BusinessimageUrl),
            ),
          ],
        ),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.height * 0.13,
              height: MediaQuery.of(context).size.height * 0.13,
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
              height: MediaQuery.of(context).size.height * 0.09,
              width: MediaQuery.of(context).size.width * 0.606,
              decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withOpacity(0.9),
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

  Widget _businessImageNameBarWhiteShadowContainer({
    required String name,
    required String email,
    required String imageUrl,
    required Color textBackgroundColor,
    required Color shadowColor,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;
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
                    color: shadowColor,
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(-3, -3),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(BusinessimageUrl),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 70,
              constraints: const BoxConstraints(
                minWidth: 170,
                maxWidth: 230,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: textBackgroundColor,
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
                        style: TextStyle(
                          fontSize: fontSize,
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
                      Text(
                        "$businessMail",
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

  Widget _businessImageNameBarContainer({
    required String name,
    required String email,
    required String imageUrl,
  }) {
    double fontSize = name.length <= 17 ? 16.0 : 10.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width * 0.14,
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
              width: MediaQuery.of(context).size.height * 0.14,
              height: MediaQuery.of(context).size.height * 0.14,
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
              height: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width * 0.585,
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
              height: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width * 0.585,
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
              width: MediaQuery.of(context).size.height * 0.14,
              height: MediaQuery.of(context).size.height * 0.14,
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
              width: MediaQuery.of(context).size.height * 0.14,
              height: MediaQuery.of(context).size.height * 0.14,
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
              height: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width * 0.585,
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
              height: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width * 0.585,
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
              width: MediaQuery.of(context).size.height * 0.14,
              height: MediaQuery.of(context).size.height * 0.14,
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
              radius: MediaQuery.of(context).size.height * 0.08,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.08,
              width: MediaQuery.of(context).size.width * 0.585,
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
                    color: shadowColor,
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
              height: MediaQuery.of(context).size.height * 0.08,
              width: MediaQuery.of(context).size.width * 0.8,
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
    final imagePath = await File('${directory.path}/Quate.png').create();
    await imagePath.writeAsBytes(image);

    Share.shareXFiles([XFile(imagePath.path)], text: 'Check out this image!');
  }

  Future<void> _downloadScreenshot(BuildContext context) async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final String tempPath = '${directory.path}/temp_image.png';
      final File tempFile = File(tempPath);

      await tempFile.writeAsBytes(image);

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        TextEditingController nameController = TextEditingController();
        String? fileName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Save Your Quate'),
              content: TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Enter Quate Name'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, nameController.text),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );

        if (fileName != null && fileName.isNotEmpty) {
          final String finalPath = '$selectedDirectory/$fileName.png';
          final File finalFile = await tempFile.copy(finalPath);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Quate saved')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No directory selected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save Quate: $e')),
      );
    }
  }

  Future<void> _showPersonalUpdateDialog() async {
    final TextEditingController nameController =
        TextEditingController(text: name);
    final TextEditingController phoneController =
        TextEditingController(text: phone);

    List<String> userImages = await _fetchUserImages();

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

  Future<String> _uploadBusinessImage(
      String imagePath, String uid, int index) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('business_images/$uid/image_$index.jpg');
    final uploadTask = storageRef.putFile(File(imagePath));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Design",
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
                                        child: Text(
                                            'Image is not uploaded please upload image first'));
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
                                            contactNumber,
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
}
