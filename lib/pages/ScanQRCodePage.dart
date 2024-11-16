import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../chat/contacts/UserProfilePage.dart';
import '../services/FriendService.dart';

class ScanQRCodePage extends StatefulWidget {
  @override
  _ScanQRCodePageState createState() => _ScanQRCodePageState();
}

class _ScanQRCodePageState extends State<ScanQRCodePage> {
  final FriendService _friendService = FriendService();
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );

  void _showProfileConfirmationDialog(BuildContext context, String friendId, Uint8List? image) async {
    final DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance.collection('Users').doc(friendId).get();
    final friendData = friendSnapshot.data() as Map<String, dynamic>?;

    if (friendData != null) {
      final friendName = friendData['name'] ?? 'Unknown';
      final friendAvatar = friendData['avatar'] ?? '';

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('View Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: friendAvatar.isNotEmpty ? NetworkImage(friendAvatar) : null,
                  child: friendAvatar.isEmpty ? Icon(Icons.person, size: 30) : null,
                ),
                SizedBox(height: 10),
                Text(friendName, style: TextStyle(fontSize: 18)),
                if (image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image(image: MemoryImage(image)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _controller.start();  // Restart the scanner when the dialog is dismissed
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userData: friendData),
                    ),
                  );
                },
                child: Text('View Profile'),
              ),
            ],
          );
        },
      );
    } else {
      // Handle case where friend data is not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend not found!')),
      );
      _controller.start();  // Restart the scanner if friend data is not found
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          final Uint8List? image = capture.image;
          for (final barcode in barcodes) {
            String barcodeData = barcode.rawValue ?? '';
            if (barcodeData.startsWith('http://')) {
              barcodeData = barcodeData.substring(7);
            }
            print('Barcode: $barcodeData');

            _controller.stop();  // Stop the scanner to prevent multiple detections
            _showProfileConfirmationDialog(context, barcodeData, image);
          }
        },
      ),
    );
  }
}
