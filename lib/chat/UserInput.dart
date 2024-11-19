import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../UI_Widgets/InputBox.dart';
import '../services/AuthService.dart';
import '../services/FireStoreService.dart';
import '../services/StorageService.dart';

class UserInput extends StatelessWidget {
  final TextEditingController messController;
  final FocusNode focusNode;
  final String friendId;
  final VoidCallback onMessageSent;
  final VoidCallback sendTextMessage;
  final VoidCallback sendImageMessage;
  final VoidCallback sendVideoMessage;
  final VoidCallback sendFileMessage;

  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();
  final StorageService storageService = StorageService();

  UserInput({
    required this.messController,
    required this.focusNode,
    required this.friendId,
    required this.onMessageSent,
    required this.sendTextMessage,
    required this.sendImageMessage,
    required this.sendVideoMessage,
    required this.sendFileMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () => showMediaOptions(context),
          ),
          Expanded(
            child: InputBox(
              hint: "Type your message",
              controller: messController,
              focusNode: focusNode,
            ),
          ),
          IconButton(
            onPressed: () => sendTextMessage(),
            icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }



  void showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMediaOption(
                context,
                Icons.image,
                'Image',
                    () => sendImageMessage(),
              ),
              _buildMediaOption(
                context,
                Icons.video_library,
                'Video',
                    () => sendVideoMessage(),
              ),
              _buildMediaOption(
                context,
                Icons.insert_drive_file,
                'File',
                    () => sendFileMessage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaOption(
      BuildContext context,
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }


  String _getChatBoxId() {
    List<String> ids = [authService.getCurrentUserId(), friendId];
    ids.sort();
    return ids.join('_');
  }
}