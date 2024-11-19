import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/UI_Widgets/InputBox.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/StorageService.dart';
import '../utils/Utils.dart';
import 'MessageSenderService.dart';
import 'UserInput.dart';
import 'VideoPlayerWidget.dart';

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
  late final MessageSenderService messageSender;
  FocusNode focusNode = FocusNode();
  ScrollController scrollController = ScrollController();
  late List<Map<String, dynamic>> messages;

  @override
  void initState() {
    super.initState();
    messages = [];
    messageSender = MessageSenderService(
      chatService: chatService,
      authService: authService,
      storageService: storageService,
      friendId: widget.friendId,
      onMessageAdded: _handleMessageAdded,
      onMessageSent: goToBot,
    );

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => goToBot());
      }
    });

    Future.delayed(Duration(milliseconds: 500), () => goToBot());
  }

  void goToBot() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300), curve: Curves.fastOutSlowIn);
  }


  void _handleMessageAdded(Map<String, dynamic> message) {
    setState(() {
      messages.add(message);
      messages.sort((a, b) => a['timeStamp'].compareTo(b['timeStamp']));
    });
  }

  void sendTextMessage() async {
    if (messController.text.isNotEmpty) {
      String text = messController.text;
      messController.clear();
      await messageSender.sendTextMessage(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.friendName)),
      body: Column(children: [
        Expanded(child: MessageList()),
        UserInput(
          messController: messController,
          focusNode: focusNode,
          friendId: widget.friendId,
          onMessageSent: goToBot,
          sendTextMessage: sendTextMessage,
          sendImageMessage: messageSender.sendImageMessage,
          sendVideoMessage: messageSender.sendVideoMessage,
          sendFileMessage: messageSender.sendFileMessage,
        ),
      ]),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    final messageTime = timestamp.toDate();
    return DateFormat('HH:mm dd/MM/yyyy').format(messageTime);
  }

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

        if (messages.isEmpty && snapshot.data!.docs.isNotEmpty) {
          messages = snapshot.data!.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('timeStamp')) {
              return {
                'message': data['message'],
                'messType': data['messType'],
                'timeStamp': data['timeStamp'],
                'senderId': data['senderId'],
                'fileName': data['fileName'],
              };
            }
            return null;
          }).where((element) => element != null).map((element) => element as Map<String, dynamic>).toList();

          messages.sort((a, b) => a['timeStamp'].compareTo(b['timeStamp']));
        }

        print(messages.last);

        return ListView(
          controller: scrollController,
          children: messages.map((data) {
            Timestamp currentTimestamp = data["timeStamp"];
            bool showTimestamp = lastTimestamp == null ||
                currentTimestamp.toDate().difference(lastTimestamp!.toDate()).inHours > 3;
            lastTimestamp = currentTimestamp;
            return MessBoxWithData(data, showTimestamp);
          }).toList(),
        );
      },
    );
  }


  Widget MessBoxWithData(Map<String, dynamic> data, bool showTimestamp) {
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;
    var messageColor = isMyMess ? Colors.blue : Colors.grey;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isMyMess ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
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
              color: messageColor,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 250),
              child: data["messType"] == "image"
                  ? Image.network(data["message"] ?? '', fit: BoxFit.cover)
                  : data["messType"] == "video"
                  ? VideoPlayerWidget(videoUrl: data["message"] ?? '')
                  : data["messType"] == "file"
                  ? GestureDetector(
                onTap: () => launchUrl(Uri.parse(data["message"] ?? '')),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(data["fileName"] ?? '', style: TextStyle(color: Colors.white))),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white),
                      onPressed: () => launchUrl(Uri.parse(data["message"] ?? '')),
                    ),
                  ],
                ),
              )
                  : RichText(text: replaceEmoticons(data["message"] ?? '')),
            ),
          ),
        ],
      ),
    );
  }

}
