import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_io/io.dart';

import '../../services/FriendService.dart';
import '../contacts/UserProfilePage.dart';

class ScanQRCodePage extends StatefulWidget {
  @override
  _ScanQRCodePageState createState() => _ScanQRCodePageState();
}

class _ScanQRCodePageState extends State<ScanQRCodePage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );
  final FriendService friendService = FriendService();
  final FireStoreService fireStoreService = FireStoreService();

  Future<String> checkFriendStatus(String friendId) async {
    String userId = fireStoreService.authService.getCurrentUserId();
    bool isFriend = await friendService.checkIfFriends(userId, friendId);
    bool hasPendingRequest = await friendService.checkPendingRequest(userId, friendId);
    bool hasReceivedRequest = await friendService.checkReceivedRequest(userId, friendId);

    if (isFriend) return 'remove';
    if (hasPendingRequest) return 'cancel';
    if (hasReceivedRequest) return 'accept';
    return 'add';
  }

  void _showProfileConfirmationDialog(BuildContext context, String friendId, Uint8List? image) async {
    DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance.collection('Users').doc(friendId).get();
    Map<String, dynamic>? friendData = friendSnapshot.data() as Map<String, dynamic>?;
    String status = await checkFriendStatus(friendId);

    if (friendData != null) {
      String friendName = friendData['name'] ?? 'Unknown';
      String friendAvatar = friendData['avatar'] ?? '';

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
                  _controller.start();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userData: friendData,
                        relationshipStatus: status,
                      ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend not found!')));
      _controller.start();
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      print('Picked file: ${result.files.first.name}');
      // Process the picked file to scan the QR code.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = identical(0, 0.0);
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: isWeb
          ? Center(
        child: ElevatedButton(
          onPressed: _pickFile,
          child: Text('Pick QR Code from File'),
        ),
      )
          : MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          List<Barcode> barcodes = capture.barcodes;
          Uint8List? image = capture.image;
          for (Barcode barcode in barcodes) {
            String barcodeData = barcode.rawValue ?? '';
            if (barcodeData.startsWith('http://')) {
              barcodeData = barcodeData.substring(7);
            }
            print('Barcode: $barcodeData');

            _controller.stop();
            _showProfileConfirmationDialog(context, barcodeData, image);
          }
        },
      ),
    );
  }
}
