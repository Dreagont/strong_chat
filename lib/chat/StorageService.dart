
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'FireStoreService.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;
  final FireStoreService _fireStoreService = FireStoreService();

  List<String> imageUrl = [];

  bool isLoading = false;
  bool isUploading = false;

  List<String> get getImageUrl => imageUrl;
  bool get getIsLoading => isLoading;
  bool get getIsUpLoading => isUploading;

  Future<String> getImage(String userId) async {
    String filePath = 'avatars/$userId.jpg';
    return await firebaseStorage.ref(filePath).getDownloadURL();
  }

  Future<void> uploadImage(String userId) async {
    isUploading = true;
    notifyListeners();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    File file = File(image.path);

    try {
      String filePath = 'avatars/$userId.jpg';

      await firebaseStorage.ref(filePath).putFile(file);

      String imageUrl = await firebaseStorage.ref(filePath).getDownloadURL();

      _fireStoreService.updateUserAvatar(userId, imageUrl);
      notifyListeners();
    } catch(e) {
      print(e);
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }
}