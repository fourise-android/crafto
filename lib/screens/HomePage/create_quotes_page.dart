// ignore_for_file: use_key_in_widget_constructors

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
  final ImagePicker _picker = ImagePicker();
  List<File> _images = [];
  File? _selectedImage;

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
        _images = imagePaths.map((path) => File(path)).toList();
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
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
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
        print('No images selected.');
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
    String uid = 'example_uid'; // Replace with your actual uid logic
    String email = widget.email; // Access email from widget

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
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double containerHeight = MediaQuery.of(context).size.height / 2;
    double containerWidth = containerHeight * 3 / 4;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Quotes')),
      body: Column(
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
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    )
                  : const Center(child: Text('No image selected')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed:
                  _handleButtonPress, // No need to pass uid and email here
              child:
                  Text(_selectedImage == null ? 'Pick Images' : 'Edit Quote'),
            ),
          ),
          Expanded(
            child: _images.isEmpty
                ? const Center(child: Text('No images selected.'))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _onImageSelected(_images[index]),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Image.file(
                            _images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
