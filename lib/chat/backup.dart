import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/StorageService.dart';
import '../utils/Utils.dart';
import 'ImageWithPlaceholder.dart';
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

  List<Map<String, dynamic>> allMessages = [];
  List<Map<String, dynamic>> displayedMessages = [];

  static const int messagesPerPage = 14;
  bool isLoadingMore = false;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    messageSender = MessageSenderService(
      chatService: chatService,
      authService: authService,
      storageService: storageService,
      friendId: widget.friendId,
      onMessageAdded: _handleMessageAdded,
      onMessageSent: goToBot,
    );

    scrollController.addListener(_scrollListener);
    _setupMessageStream();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => goToBot());
      }
    });
  }
  void _setupMessageStream() {
    final userId = authService.getCurrentUserId();
    _messageSubscription = chatService
        .getMessage(userId, widget.friendId)
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          allMessages = snapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'message': data['message'],
              'messType': data['messType'],
              'timeStamp': data['timeStamp'],
              'senderId': data['senderId'],
              'fileName': data['fileName'],
            };
          }).toList();

          allMessages.sort((a, b) =>
              (b['timeStamp'] as Timestamp).compareTo(a['timeStamp'] as Timestamp));

          if (displayedMessages.isEmpty) {
            displayedMessages = allMessages.take(messagesPerPage).toList();
          } else {
            // Find the newest message that wasn't in displayedMessages
            var newMessages = allMessages.where((message) => !displayedMessages
                .any((displayed) =>
            displayed['timeStamp'] == message['timeStamp'] &&
                displayed['message'] == message['message']))
                .toList();

            if (newMessages.isNotEmpty) {
              displayedMessages.insertAll(0, newMessages);
            }
          }
        });
      }
    });
  }

  void _scrollListener() {
    if (scrollController.position.pixels <= 100 && !isLoadingMore) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() {
    if (isLoadingMore || displayedMessages.length >= allMessages.length) return;

    setState(() {
      isLoadingMore = true;

      int startIndex = displayedMessages.length;
      int endIndex = startIndex + messagesPerPage;
      if (endIndex > allMessages.length) {
        endIndex = allMessages.length;
      }

      displayedMessages.addAll(allMessages.sublist(startIndex, endIndex));

      isLoadingMore = false;
    });
  }

  void _handleMessageAdded(Map<String, dynamic> message) {
    setState(() {
      if (!displayedMessages.any((m) =>
      m['timeStamp'] == message['timeStamp'] &&
          m['message'] == message['message'])) {
        displayedMessages.insert(0, message);
      }
    });
  }

  void goToBot() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void sendTextMessage() async {
    if (messController.text.isNotEmpty) {
      String text = messController.text;
      messController.clear();
      goToBot();
      await messageSender.sendTextMessage(text);
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final messageTime = timestamp.toDate();
    return DateFormat('HH:mm dd/MM/yyyy').format(messageTime);
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

  Widget MessageList() {
    String userId = authService.getCurrentUserId();

    if (displayedMessages.isEmpty) {
      return const Center(
          child: Text("No messages yet. Start the conversation!")
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: displayedMessages.length + 1,
      itemBuilder: (context, index) {
        if (index == displayedMessages.length) {
          return displayedMessages.length < allMessages.length
              ? Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.center,
            child: isLoadingMore
                ? CircularProgressIndicator()
                : SizedBox.shrink(),
          )
              : SizedBox.shrink();
        }

        Map<String, dynamic> data = displayedMessages[index];
        Timestamp currentTimestamp = data["timeStamp"];

        bool showTimestamp = index == displayedMessages.length - 1;
        if (!showTimestamp && index < displayedMessages.length - 1) {
          Timestamp nextTimestamp = displayedMessages[index + 1]["timeStamp"];
          showTimestamp = currentTimestamp
              .toDate()
              .difference(nextTimestamp.toDate())
              .inHours > 3;
        }

        return MessBoxWithData(data, showTimestamp);
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
                  ? ImageWithPlaceholder(imageUrl: data["message"] ?? '')
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
  @override
  void dispose() {
    _messageSubscription?.cancel();
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    focusNode.dispose();
    messController.dispose();
    super.dispose();
  }
}
