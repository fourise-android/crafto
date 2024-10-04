// ignore_for_file: use_key_in_widget_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pic_poster/screens/HomePage/edit_quote.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CreateQuotesPage extends StatefulWidget {
  final String email;

  CreateQuotesPage({required this.email});

  @override
  _CreateQuotesPageState createState() => _CreateQuotesPageState();
}

class _CreateQuotesPageState extends State<CreateQuotesPage> {
  final String UID = FirebaseAuth.instance.currentUser!.uid;
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  File? _selectedImage;
  final List<File> _selectedImages = [];
  String? name; // Define name
  String? photoUrl; // Define photoUrl

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? imagePaths = prefs.getStringList('imagePaths');
    if (imagePaths != null) {
      setState(() {
        // Ensure only valid files are loaded
        _images = imagePaths
            .map((path) => File(path))
            .where((file) => file.existsSync())
            .toList();
      });
    }
  }

  Future<void> _saveImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePaths = _images.map((file) => file.path).toList();
    await prefs.setStringList('imagePaths', imagePaths);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final newImages =
            pickedFiles.map((XFile file) => File(file.path)).toList();

        setState(() {
          _images = newImages + _images;
          if (_selectedImage == null && newImages.isNotEmpty) {
            _selectedImage = newImages.first;
          }
        });

        await _saveImages();
      } else {
        print('Please select your image first.');
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void _onImageSelected(File image) {
    setState(() {
      _selectedImage = image;
    });
  }

  void _handleButtonPress() {
    String uid = UID;
    String email = widget.email;

    if (_selectedImage == null) {
      _pickImages();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditQuote(
            image: _selectedImage!,
            uid: uid,
            email: email,
            userName: name ?? '',
            profilePhotoUrl: photoUrl ?? '',
          ),
        ),
      );
    }
  }

  void _deleteSelectedImages() {
    setState(() {
      if (_selectedImages.contains(_selectedImage)) {
        _selectedImage = null;
      }
      _images.removeWhere((image) => _selectedImages.contains(image));
      _selectedImages.clear();
    });
    _saveImages();
  }

  void _onImageLongPressed(File image) {
    setState(() {
      if (_selectedImages.contains(image)) {
        _selectedImages.remove(image);
      } else {
        _selectedImages.add(image);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height / 2.2;
    double containerWidth = containerHeight * 3 / 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Quotes')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: containerWidth,
            height: containerHeight,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 200, 216, 244),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: containerWidth,
                          height: containerHeight,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Please load images to create custom templates',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                _pickImages();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 40,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                if (_selectedImage != null)
                  Positioned(
                    right: 8.0,
                    top: 8.0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _images.remove(_selectedImage);
                          _selectedImage = null;
                        });
                        _saveImages();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: const Icon(
                          Icons.delete,
                          size: 24.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _pickImages(),
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
                      "Add New Images",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'CircularStd',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _handleButtonPress(),
                child: Container(
                  height: 36,
                  width: 140,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Edit Selected Image",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'CircularStd',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images selected.'))
                : Column(
                    children: [
                      if (_selectedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedImages.length} selected',
                                style: const TextStyle(fontSize: 16.0),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: _deleteSelectedImages,
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4.0,
                            mainAxisSpacing: 4.0,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final image = _images[index];

                            // Ensure image is valid before showing
                            if (!image.existsSync()) {
                              return const SizedBox.shrink();
                            }

                            final isSelected = _selectedImages.contains(image);

                            return GestureDetector(
                              onTap: () => _onImageSelected(image),
                              onLongPress: () => _onImageLongPressed(image),
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.0,
                                    child: Image.file(
                                      image,
                                      fit: BoxFit.cover,
                                      color: isSelected
                                          ? Colors.black.withOpacity(0.6)
                                          : null,
                                      colorBlendMode:
                                          isSelected ? BlendMode.darken : null,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
