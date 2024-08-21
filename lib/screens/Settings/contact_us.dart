import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ContactFormPage extends StatefulWidget {
  @override
  _ContactFormPageState createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    final String name = _nameController.text.trim();
    final String contact = _contactController.text.trim();
    final String query = _queryController.text.trim();

    if (name.isEmpty || contact.isEmpty || query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('contact_forms').add({
        'name': name,
        'contact': contact,
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      _showSuccessDialog();

      // Clear the form after submission
      _nameController.clear();
      _contactController.clear();
      _queryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit query: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('Your query has been submitted successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context); // Navigate back to the previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Contact Us',
          style: TextStyle(
            fontFamily: 'CircularStd',
            fontSize: 20,
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF3F5F7),
                    hintText: 'Enter your name',
                    hintStyle: const TextStyle(
                      color: Color(0xFF828282),
                      fontFamily: 'CircularStd',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'CircularStd',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF3F5F7),
                    hintText: 'Enter your contact number',
                    hintStyle: const TextStyle(
                      color: Color(0xFF828282),
                      fontFamily: 'CircularStd',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'CircularStd',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _queryController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF3F5F7),
                    hintText: 'Enter your query',
                    hintStyle: const TextStyle(
                      color: Color(0xFF828282),
                      fontFamily: 'CircularStd',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'CircularStd',
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: _submitForm,
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF888BF4), Color(0xFF5151C6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'CircularStd',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
