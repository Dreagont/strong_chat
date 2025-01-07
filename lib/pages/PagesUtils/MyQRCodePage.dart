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
      final boundary = globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      if (kIsWeb) {
        final qrValidationResult = QrValidator.validate(
          data: userId,
          version: QrVersions.auto,
          errorCorrectionLevel: QrErrorCorrectLevel.L,
        );

        if (qrValidationResult.status == QrValidationStatus.valid) {
          final qrCode = qrValidationResult.qrCode!;
          final painter = QrPainter.withQr(
            qr: qrCode,
            color: const Color(0xFF000000),
            emptyColor: const Color(0xFFFFFFFF),
            gapless: true,
          );

          final image = await painter.toImageData(200.0);
          if (image != null) {
            final bytes = image.buffer.asUint8List();
            final blob = html.Blob([bytes], 'image/png');
            final url = html.Url.createObjectUrlFromBlob(blob);

            final downloadElement = html.AnchorElement()
              ..href = url
              ..download = 'qrcode_${AuthService().getCurrentUserId()}.png'
              ..style.display = 'none';

            html.document.body!.children.add(downloadElement);
            downloadElement.click();
            html.document.body!.children.remove(downloadElement);
            html.Url.revokeObjectUrl(url);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('QR Code downloaded successfully')),
            );
          }
        }
      } else {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List pngBytes = byteData!.buffer.asUint8List();

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
              const SnackBar(content: Text('QR Code saved to gallery')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to save QR Code to gallery')),
            );
          }
        } else {
          print('Storage permission is required');
        }
      }
    } catch (e) {
      print("Error saving QR Code: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR Code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My QR Code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
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
              child: avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _globalKey,
              child: QrImageView(
                backgroundColor: Colors.white,
                data: userId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveQrCodeToGallery(context, _globalKey),
              child: const Text("Save to Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}