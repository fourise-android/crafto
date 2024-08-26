// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pic_poster/screens/HomePage/edit_templet.dart';
import 'package:pic_poster/screens/Settings/setting_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  List<String> filters = [];
  String selectedFilter = '';
  bool isLoading = true;
  bool isDataLoaded = false;
  String preferredLanguage = 'Loading...';
  List<Map<String, dynamic>> images = [];
  List<Map<String, dynamic>> filteredImages = [];
  String searchQuery = '';
  int currentIndex = 0;

  final int _imagesPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_details')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          preferredLanguage = data['preferredLanguage'] ?? 'Not set';
          isDataLoaded = true;
        });
        _fetchFiltersAndImages();
      } else {
        setState(() {
          preferredLanguage = 'Not set';
          isDataLoaded = true;
        });
        _fetchFiltersAndImages();
      }
    } catch (e) {
      setState(() {
        preferredLanguage = 'Error fetching language';
        isDataLoaded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error fetching user details.'),
        ),
      );
      _fetchFiltersAndImages();
    }
  }

  Future<Map<String, String>> fetchUserForTemplets(String email) async {
    final userQuery = await FirebaseFirestore.instance
        .collection('user_details')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception("No user found with the provided email.");
    }

    final String userId = userQuery.docs.first.id;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('User_Images')
        .child(userId)
        .child('DP.jpg');

    final firestoreDoc = await FirebaseFirestore.instance
        .collection('user_details')
        .doc(userId)
        .get();

    final String profilePhotoUrl = await storageRef.getDownloadURL();
    final String userName = firestoreDoc.data()?['name'] ?? 'Unknown';

    return {
      'profilePhotoUrl': profilePhotoUrl,
      'userName': userName,
    };
  }

  Future<void> _fetchFiltersAndImages() async {
    try {
      String languageFolder = 'templates/$preferredLanguage/';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(languageFolder);
      final ListResult result = await storageRef.listAll();

      if (result.prefixes.isEmpty) {
        setState(() {
          filters = [];
          isLoading = false;
        });
        _loadAllImages();
      } else {
        setState(() {
          filters = result.prefixes.map((ref) => ref.name).toList();
          isLoading = false;
        });
        _loadAllImages();
      }
    } catch (e) {
      print('Error fetching filters and images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching data. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadImagesForSelectedFolder() async {
    if (selectedFilter.isEmpty) {
      _loadAllImages();
      return;
    }

    setState(() {
      isLoading = true;
      images.clear();
    });

    try {
      String folderPath = 'templates/$preferredLanguage/$selectedFilter/';
      final Reference folderRef =
          FirebaseStorage.instance.ref().child(folderPath);
      final ListResult folderResult = await folderRef.listAll();

      final List<Future<void>> fetchImageTasks =
          folderResult.items.map((imageRef) async {
        final String imageUrl = await imageRef.getDownloadURL();
        final FullMetadata metadata = await imageRef.getMetadata();
        images.add({
          'url': imageUrl,
          'name': imageRef.name,
          'timeCreated': metadata.timeCreated ?? DateTime.now(),
        });
      }).toList();

      await Future.wait(fetchImageTasks);

      images.sort((a, b) => b['timeCreated'].compareTo(a['timeCreated']));
      _applySearchFilter();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading images for selected folder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error loading images. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllImages() async {
    setState(() {
      isLoading = true;
      images.clear();
    });

    try {
      String languageFolder = 'templates/$preferredLanguage/';
      final Reference storageRef =
          FirebaseStorage.instance.ref().child(languageFolder);

      final List<Future<void>> fetchImageTasks =
          (await storageRef.listAll()).prefixes.map((subfolder) async {
        final ListResult subfolderResult = await subfolder.listAll();
        final List<Future<void>> subfolderImageTasks =
            subfolderResult.items.map((imageRef) async {
          final String imageUrl = await imageRef.getDownloadURL();
          final FullMetadata metadata = await imageRef.getMetadata();
          images.add({
            'url': imageUrl,
            'name': imageRef.name,
            'timeCreated': metadata.timeCreated ?? DateTime.now(),
          });
        }).toList();

        await Future.wait(subfolderImageTasks);
      }).toList();

      await Future.wait(fetchImageTasks);

      images.sort((a, b) => b['timeCreated'].compareTo(a['timeCreated']));
      _applySearchFilter();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error loading images. Please try again.')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applySearchFilter() {
    setState(() {
      filteredImages = images
          .where((image) =>
              image['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              image['timeCreated']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF3F5F7),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 55, 8, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F5F7),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: 'Search',
                                          border: InputBorder.none,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            searchQuery = value.toLowerCase();
                                            _applySearchFilter();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F5F7),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SettingPage(email: widget.email),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 15),
                                textStyle: const TextStyle(
                                  fontFamily: 'CircularStd',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedFilter = '';
                                  currentIndex = 0;
                                });
                                _loadAllImages();
                              },
                              child: Text(preferredLanguage),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: filters.map((filter) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedFilter = filter;
                                        currentIndex = 0;
                                      });
                                      _loadImagesForSelectedFolder();
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: selectedFilter == filter
                                          ? Colors.white
                                          : Colors.black,
                                      backgroundColor: selectedFilter == filter
                                          ? const Color(0xFF5151C6)
                                          : Colors.grey[150],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    child: Text(filter),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5151C6),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: filteredImages.length,
                      itemBuilder: (context, index) {
                        final image = filteredImages[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final double cardHeight =
                                    constraints.maxWidth * (4 / 3);

                                return Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.width * 4 / 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        30), // Circular corners
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white,
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: const Offset(
                                            0, 3), // Shadow direction
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 8, 8, 0),
                                              child: IconButton(
                                                onPressed: () {},
                                                icon: const Icon(
                                                  Icons.edit_square,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(15, 15, 15, 50),
                                        child: CachedNetworkImage(
                                          imageUrl: image['url'],
                                          placeholder: (context, url) =>
                                              const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(30)),
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 35,
                                        left: 15,
                                        child: Container(
                                          color: Colors.white,
                                          width: 350,
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                15, 15, 15, 15),
                                            child: FutureBuilder<
                                                Map<String, String>>(
                                              future: fetchUserForTemplets(
                                                  widget.email),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else if (snapshot.hasData) {
                                                  final userDetails =
                                                      snapshot.data!;
                                                  return Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 30,
                                                        backgroundImage:
                                                            NetworkImage(
                                                                userDetails[
                                                                    'profilePhotoUrl']!),
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        userDetails[
                                                            'userName']!,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else {
                                                  return const Text(
                                                      'No user details available');
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: -15,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 0, 15, 15),
                                          child: FutureBuilder<
                                              Map<String, String>>(
                                            future: fetchUserForTemplets(
                                                widget.email),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else if (snapshot.hasData) {
                                                final userDetails =
                                                    snapshot.data!;
                                                return Column(
                                                  children: [
                                                    const SizedBox(height: 15),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        EditTemplet(
                                                                  imageUrl:
                                                                      image[
                                                                          'url'],
                                                                  userName:
                                                                      userDetails[
                                                                          'userName']!,
                                                                  profilePhotoUrl:
                                                                      userDetails[
                                                                          'profilePhotoUrl']!,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            height: 36,
                                                            width: 140,
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                      0xFF888BF4),
                                                                  Color(
                                                                      0xFF5151C6),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                            ),
                                                            child: const Center(
                                                              child: Text(
                                                                "Share",
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'CircularStd',
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 40),
                                                        InkWell(
                                                          onTap: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        EditTemplet(
                                                                  imageUrl:
                                                                      image[
                                                                          'url'],
                                                                  userName:
                                                                      userDetails[
                                                                          'userName']!,
                                                                  profilePhotoUrl:
                                                                      userDetails[
                                                                          'profilePhotoUrl']!,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          child: Container(
                                                            height: 36,
                                                            width: 140,
                                                            decoration:
                                                                BoxDecoration(
                                                              gradient:
                                                                  const LinearGradient(
                                                                colors: [
                                                                  Color(
                                                                      0xFF888BF4),
                                                                  Color(
                                                                      0xFF5151C6),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50),
                                                            ),
                                                            child: const Center(
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .file_download_outlined,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          10),
                                                                  Text(
                                                                    "Download",
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontFamily:
                                                                          'CircularStd',
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                );
                                              } else {
                                                return const Text(
                                                    'No user details available');
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
