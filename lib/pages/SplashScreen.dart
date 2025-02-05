import 'package:flutter/material.dart';
import 'package:strong_chat/auth/AuthGate.dart'; // Import AuthGate

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(Duration(seconds: 3)); // Wait for 3 seconds
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AuthGate(), // Navigate to AuthGate after the delay
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Center(
        child: CircleAvatar(
          radius: 100,
          backgroundImage: AssetImage(
              'assets/logo.jpg') as ImageProvider,
        ), // Display the image from assets
      ),
    );
  }
}