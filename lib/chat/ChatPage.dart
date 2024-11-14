import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/UI_Widgets/InputBox.dart';
import 'package:intl/intl.dart';

import '../services/StorageService.dart';
import '../ultils/Utils.dart';

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
  final StorageService storageService = StorageService();
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => goToBot());
      }
    });

    Future.delayed(Duration(milliseconds: 500), () => goToBot());
  }

  @override
  void dispose() {
    focusNode.dispose();
    messController.dispose();
    super.dispose();
  }

  void goToBot() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
  }

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
      await chatService.sendMessage(
          widget.friendId, messController.text, 'text');

      messController.clear();
      goToBot();
    }
  }

  void sendImageMessage(BuildContext context) async {
    final Timestamp timestamp = Timestamp.now();
    List<String> ids = [authService.getCurrentUserId(), widget.friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    String filePath = 'chatImages/$chatBoxId/$timestamp.jpg';
    await storageService.uploadImage(
        timestamp.toString(), 'chatImages/$chatBoxId');
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
        children: [Expanded(child: MessageList()), UserInput(context)],
      ),
    );
  }

// Utility function to format the timestamp
  String formatTimestamp(Timestamp timestamp) {
    final messageTime = timestamp.toDate();
    return DateFormat('HH:mm dd/MM/yyyy').format(messageTime);
  }

// Modified MessBox widget to include time display logic between messages
  Widget MessageList() {
    String userId = authService.getCurrentUserId();
    Timestamp? lastTimestamp;

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
          controller: scrollController,
          children: snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            Timestamp currentTimestamp = data["timeStamp"];
            bool showTimestamp = lastTimestamp == null ||
                currentTimestamp.toDate().difference(lastTimestamp!.toDate()).inHours > 3;
            lastTimestamp = currentTimestamp;

            return MessBox(doc, showTimestamp);
          }).toList(),
        );
      },
    );
  }

  Widget MessBox(DocumentSnapshot doc, bool showTimestamp) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isMyMess ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Display the time above the message if the flag is true
          if (showTimestamp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Center(
                child: Text(
                  formatTimestamp(data["timeStamp"]),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Container(
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
                  : RichText(
                text: replaceEmoticons(data["message"]),
              ),
            ),
          ),
        ],
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
          Expanded(
              child: InputBox(
            hint: "Type your message",
            controller: messController,
            focusNode: focusNode,
          )),
          IconButton(onPressed: sendTextMessage, icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
