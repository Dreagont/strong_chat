import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'FireStoreService.dart';
import 'package:file_picker/file_picker.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;
  final FireStoreService _fireStoreService = FireStoreService();

  List<String> imageUrl = [];
  bool isLoading = false;
  bool isUploading = false;

  List<String> get getImageUrl => imageUrl;
  bool get getIsLoading => isLoading;
  bool get getIsUpLoading => isUploading;

  Future<String> getImage(String userId, String path) async {
    String filePath = '$path/$userId.jpg';
    return await firebaseStorage.ref(filePath).getDownloadURL();
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

    File file = File(image.path);

    try {
      Uint8List imageBytes = await file.readAsBytes();
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

      final tempFile = File('${file.parent.path}/compressed_${file.uri.pathSegments.last}');
      await tempFile.writeAsBytes(compressedBytes);

      String filePath = '$path/$userId.jpg';
      await firebaseStorage.ref(filePath).putFile(tempFile);

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

  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }

  Future<void> uploadImage(XFile image, String filename, String path) async {
    isUploading = true;
    notifyListeners();

    File file = File(image.path);
    try {
      Uint8List imageBytes = await file.readAsBytes();
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

      final tempFile = File('${file.parent.path}/compressed_${file.uri.pathSegments.last}');
      await tempFile.writeAsBytes(compressedBytes);

      String filePath = '$path/$filename.jpg';
      await firebaseStorage.ref(filePath).putFile(tempFile);

      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<XFile?> pickVideo() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickVideo(source: ImageSource.gallery);
  }

  Future<void> uploadVideo(XFile video, String fileName, String path, String chatBoxId, String friendId) async {
    isUploading = true;
    notifyListeners();

    File file = File(video.path);
    try {
      String filePath = 'ChatData/$chatBoxId/$fileName.mp4';
      await firebaseStorage.ref(filePath).putFile(file);

      String mess = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
      await _fireStoreService.sendMessage(friendId, mess, 'video', "");
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
    );
  }

  Future<void> uploadFile(FilePickerResult result, String fileName, String path, String chatBoxId, String friendId) async {
    isUploading = true;
    notifyListeners();

    File file = File(result.files.single.path!);
    String pickedFileName = result.files.single.name;
    try {
      String filePath = 'ChatData/$chatBoxId/$fileName.${result.files.single.extension}';
      await firebaseStorage.ref(filePath).putFile(file);

      String mess = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
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
