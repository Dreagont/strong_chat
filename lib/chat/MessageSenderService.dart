import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import '../services/StorageService.dart';


class MessageSenderService {
  final FireStoreService chatService;
  final AuthService authService;
  final StorageService storageService;
  final String friendId;
  final Function(Map<String, dynamic>) onMessageAdded;
  final VoidCallback onMessageSent;

  MessageSenderService({
    required this.chatService,
    required this.authService,
    required this.storageService,
    required this.friendId,
    required this.onMessageAdded,
    required this.onMessageSent,
  });

  String _getChatBoxId() {
    List<String> ids = [authService.getCurrentUserId(), friendId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendTextMessage(String text) async {
    if (text.isNotEmpty) {
      Timestamp timestamp = Timestamp.now();

      Map<String, dynamic> tempMessage = {
        'message': text,
        'messType': 'text',
        'timeStamp': timestamp,
        'senderId': authService.getCurrentUserId(),
        'fileName': ''
      };

      onMessageAdded(tempMessage);
      await chatService.sendMessage(friendId, text, 'text', "");
      onMessageSent();
    }
  }

  Future<void> sendImageMessage() async {
    final Timestamp timestamp = Timestamp.now();
    String chatBoxId = _getChatBoxId();
    String filePath = 'ChatData/$chatBoxId/$timestamp.jpg';

    Map<String, dynamic> tempMessage = {
      'message': '',
      'messType': 'image',
      'timeStamp': timestamp,
      'senderId': authService.getCurrentUserId(),
      'fileName': ''
    };

    onMessageAdded(tempMessage);
    await storageService.uploadImage(timestamp.toString(), 'ChatData/$chatBoxId');
    String mess = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
    await chatService.sendMessage(friendId, mess, 'image', "");
    onMessageSent();
  }

  Future<void> sendVideoMessage() async {
    final Timestamp timestamp = Timestamp.now();
    String chatBoxId = _getChatBoxId();

    Map<String, dynamic> tempMessage = {
      'message': '',
      'messType': 'video',
      'timeStamp': timestamp,
      'senderId': authService.getCurrentUserId(),
      'fileName': ''
    };

    onMessageAdded(tempMessage);
    await storageService.uploadVideo(
        timestamp.toString(),
        'ChatData/$chatBoxId',
        chatBoxId,
        friendId
    );
    onMessageSent();
  }

  Future<void> sendFileMessage() async {
    final Timestamp timestamp = Timestamp.now();
    String chatBoxId = _getChatBoxId();

    Map<String, dynamic> tempMessage = {
      'message': '',
      'messType': 'file',
      'timeStamp': timestamp,
      'senderId': authService.getCurrentUserId(),
      'fileName': 'sending file....'
    };

    onMessageAdded(tempMessage);
    await storageService.uploadFile(
        timestamp.toString(),
        'ChatData/$chatBoxId',
        chatBoxId,
        friendId
    );
    onMessageSent();
  }
}
