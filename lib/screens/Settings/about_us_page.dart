import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Center(
          child: Text(
            'Pic Poster',
            style: TextStyle(
              color: Colors.black,
              fontFamily: 'CircularStd',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Create Your Daily Whatsapp',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'CircularStd',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              '\tWe are a passionate team dedicated to creating software solutions that make life easier. Our mission is to deliver high-quality products that meet the needs of our users. Through innovation and creativity, we aim to push the boundaries of what technology can do.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'CircularStd',
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            const Text(
              '\tOur company has grown significantly since its inception, and we continue to strive for excellence in everything we do. With a focus on customer satisfaction and a commitment to quality, we work tirelessly to provide the best possible service and support to our clients.',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'CircularStd',
              ),
              textAlign: TextAlign.justify,
            ),
            const Spacer(),
            const Text(
              'Developed by',
              style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'CircularStd',
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              height: 300,
              width: 300,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Fourise Software Solutions Pvt. Ltd',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'CircularStd',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
