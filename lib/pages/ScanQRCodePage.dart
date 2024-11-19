import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/services/FireStoreService.dart';

import '../contacts/UserProfilePage.dart';
import '../services/FriendService.dart';

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

  Future<String> checkFriendStatus(var friendId) async {
    String relationshipStatus = "";
    final String userId = fireStoreService.authService.getCurrentUserId();

    final bool isFriend = await friendService.checkIfFriends(userId, friendId);
    final bool hasPendingRequest =
        await friendService.checkPendingRequest(userId, friendId);
    final bool hasReceivedRequest =
        await friendService.checkReceivedRequest(userId, friendId);

    if (isFriend) {
      relationshipStatus = 'remove';
    } else if (hasPendingRequest) {
      relationshipStatus = 'cancel';
    } else if (hasReceivedRequest) {
      relationshipStatus = 'accept';
    } else {
      relationshipStatus = 'add';
    }

    return relationshipStatus;
  }

  void _showProfileConfirmationDialog(
      BuildContext context, String friendId, Uint8List? image) async {
    final DocumentSnapshot friendSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .get();
    final friendData = friendSnapshot.data() as Map<String, dynamic>?;
    final String status = await checkFriendStatus(friendId);
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
                  backgroundImage: friendAvatar.isNotEmpty
                      ? NetworkImage(friendAvatar)
                      : null,
                  child: friendAvatar.isEmpty
                      ? Icon(Icons.person, size: 30)
                      : null,
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
                  _controller
                      .start();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserProfilePage(userData: friendData, relationshipStatus: status,),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend not found!')),
      );
      _controller.start();
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

            _controller
                .stop();
            _showProfileConfirmationDialog(context, barcodeData, image);
          }
        },
      ),
    );
  }
}
