import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'FireStoreService.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;
  final FireStoreService _fireStoreService = FireStoreService();

  List<String> imageUrl = [];
  bool isLoading = false;
  bool isUploading = false;

  List<String> get getImageUrl => imageUrl;
  bool get getIsLoading => isLoading;
  bool get getIsUpLoading => isUploading;

  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<XFile?> pickVideo() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickVideo(source: ImageSource.gallery);
  }

  Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
    );
  }

  Future<void> uploadAvatar(String userId, String path) async {
    isUploading = true;
    notifyListeners();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      isUploading = false;
      notifyListeners();
      return;
    }

    try {
      Uint8List imageBytes = await image.readAsBytes(); // Use `readAsBytes` for both web and mobile
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception("Failed to decode image.");

      const int maxFileSize = 500 * 1024;
      img.Image resizedImage = img.copyResize(originalImage, width: 800);

      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85),
      );

      while (compressedBytes.lengthInBytes > maxFileSize) {
        resizedImage = img.copyResize(resizedImage, width: resizedImage.width ~/ 1.2);
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: 85),
        );
      }

      String filePath = '$path/$userId.jpg';

      if (kIsWeb) {
        await firebaseStorage.ref(filePath).putData(compressedBytes);
      } else {
        final tempFile = File('${image.path}_compressed.jpg');
        await tempFile.writeAsBytes(compressedBytes);
        await firebaseStorage.ref(filePath).putFile(tempFile);
      }

      String imageUrl = await firebaseStorage.ref(filePath).getDownloadURL();
      _fireStoreService.updateUserAvatar(userId, imageUrl);
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> uploadImage(XFile image, String timeStamp, String path, String fullFileName) async {
    isUploading = true;
    notifyListeners();

    try {
      Uint8List imageBytes = await image.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception("Failed to decode image.");

      const int maxFileSize = 500 * 1024;
      img.Image resizedImage = img.copyResize(originalImage, width: 800);

      Uint8List compressedBytes = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 85),
      );

      while (compressedBytes.lengthInBytes > maxFileSize) {
        resizedImage = img.copyResize(resizedImage, width: resizedImage.width ~/ 1.2);
        compressedBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: 85),
        );
      }

      String fileName = fullFileName.split('.').first;

      String filePath = '$path/$timeStamp/$fileName.jpg';

      if (kIsWeb) {
        await firebaseStorage.ref(filePath).putData(compressedBytes);
      } else {
        final tempFile = File('${image.path}_compressed.jpg');
        await tempFile.writeAsBytes(compressedBytes);
        await firebaseStorage.ref(filePath).putFile(tempFile);
      }

      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> uploadVideo(XFile video, String timeStamp, String path, String chatBoxId, String friendId, String fullFileName) async {
    isUploading = true;
    notifyListeners();

    try {
      String filePath = 'ChatData/$chatBoxId/$timeStamp/$fullFileName';

      if (kIsWeb) {
        Uint8List fileBytes = await video.readAsBytes();
        await firebaseStorage.ref(filePath).putData(fileBytes);
      } else {
        File file = File(video.path);
        await firebaseStorage.ref(filePath).putFile(file);
      }

      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<void> uploadFile(FilePickerResult result, String timeStamp, String path, String chatBoxId, String friendId) async {
    isUploading = true;
    notifyListeners();

    String pickedFileName = result.files.single.name;
    try {
      String filePath = 'ChatData/$chatBoxId/$timeStamp/$pickedFileName.${result.files.single.extension}';

      if (kIsWeb) {
        Uint8List fileBytes = result.files.single.bytes!;
        await firebaseStorage.ref(filePath).putData(fileBytes);
      } else {
        File file = File(result.files.single.path!);
        await firebaseStorage.ref(filePath).putFile(file);
      }

      String mess = await firebaseStorage.ref(filePath).getDownloadURL();
      await _fireStoreService.sendMessage(friendId, mess, 'file', pickedFileName);
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }



}
