import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' as foundation;
import 'package:strong_chat/services/AuthService.dart';

class MyQRCodePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String? avatarUrl;

  MyQRCodePage({
    required this.userId,
    required this.userName,
    this.avatarUrl,
  });

  final GlobalKey _globalKey = GlobalKey();


  Future<void> _saveQrCodeToGallery(BuildContext context, GlobalKey globalKey) async {
    try {
      // Capture the QR code widget as an image
      final boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (foundation.kIsWeb) {
        // For web: Trigger download via the browser
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..target = 'blank'
          ..download = 'qrcode_${AuthService().getCurrentUserId()}.png';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR Code saved to gallery')),
        );
      } else {
        if (await Permission.storage.request().isGranted) {
          final directory = Directory('/storage/emulated/0/Pictures/StrongChat');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final filePath = '${directory.path}/qrcode_${AuthService().getCurrentUserId()}.png';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);

          final result = await GallerySaver.saveImage(filePath);
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('QR Code saved to gallery')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save QR Code saved to gallery')),
            );
          }
        } else {
          print('Storage permission is required');
        }
      }
    } catch (e) {
      print("Error saving QR Code: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My QR Code'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveQrCodeToGallery(context, _globalKey),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null ? Icon(Icons.person, size: 50) : null,
            ),
            SizedBox(height: 10),
            Text(
              userName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            RepaintBoundary(
              key: _globalKey,
              child: QrImageView(
                backgroundColor: Colors.white,
                data: userId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed:() => _saveQrCodeToGallery(context, _globalKey),
              child: Text("Save to Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}
