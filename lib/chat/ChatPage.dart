import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/auth/AuthService.dart';
import 'package:strong_chat/chat/FireStoreService.dart';
import 'package:strong_chat/chat/InputBox.dart';
import 'package:strong_chat/chat/MessageBox.dart';

import 'StorageService.dart';

class ChatPage extends StatefulWidget {
  final String friendName;
  final String friendId;

  ChatPage({super.key, required this.friendName, required this.friendId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messController = TextEditingController();
  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();
  final FireStoreService _fireStoreService = FireStoreService();
  final StorageService storageService = StorageService();

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void sendTextMessage() async {
    if (messController.text.isNotEmpty) {
      await chatService.sendMessage(widget.friendId, messController.text, 'text');

      messController.clear();
    }
  }

  void sendImageMessage(BuildContext context) async {
    final Timestamp timestamp = Timestamp.now();
    List<String> ids = [authService.getCurrentUserId(), widget.friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    String filePath = 'chatImages/$chatBoxId/$timestamp.jpg';
    await storageService.uploadImage(timestamp.toString(), 'chatImages/$chatBoxId');
    String mess = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
    await chatService.sendMessage(widget.friendId, mess, 'image');
    //setState(() {});
  }

  void showMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Image'),
                onTap: () {
                  Navigator.pop(context);
                  sendImageMessage(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.video_library),
                title: Text('Video'),
                onTap: () {
                  Navigator.pop(context);
                  // Add logic to handle video upload
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  // Add logic to handle file upload
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(
        children: [
          Expanded(child: MessageList()),
          UserInput(context)
        ],
      ),
    );
  }

  Widget MessageList() {
    String userId = authService.getCurrentUserId();
    return StreamBuilder(
        stream: chatService.getMessage(userId, widget.friendId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("Loading..."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) => MessBox(doc)).toList(),
          );
        }
    );
  }

  Widget MessBox(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          color: isMyMess ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 250), // limit the width
          child: data["messType"] == "image"
              ? Image.network(
            data["message"], // Load the image from the URL
            fit: BoxFit.cover,
          )
              : Text(
            data["message"],
            style: TextStyle(color: Colors.white),
            softWrap: true,
          ),
        ),
      ),
    );
  }


  Widget UserInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: () => showMediaOptions(context),
          ),
          Expanded(child: InputBox(hint: "Type your message", controller: messController)),
          IconButton(onPressed: sendTextMessage, icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
