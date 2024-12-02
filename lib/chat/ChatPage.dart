import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/StorageService.dart';
import '../utils/Utils.dart';
import 'ChatUtils/ImageWithPlaceholder.dart';
import 'ChatUtils/MessageSenderService.dart';
import 'ChatUtils/UserInput.dart';
import 'Media/VideoPlayerWidget.dart';

class ChatPage extends StatefulWidget {
  final String friendName;
  final String friendId;
  final String nickname;

  const ChatPage(
      {super.key,
      required this.friendName,
      required this.friendId,
      required this.nickname});

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
  bool isBlocked = false;

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
    _setupBlockedStream();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => goToBot());
      }
    });
  }

  void _setupBlockedStream() {
    final userId = authService.getCurrentUserId();
    chatService.getIsBlockedStream(userId, widget.friendId).listen((blocked) {
      setState(() {
        isBlocked = blocked;
      });
    });
  }

  void _setupMessageStream() {
    final userId = authService.getCurrentUserId();
    _messageSubscription =
        chatService.getMessage(userId, widget.friendId).listen((snapshot) {
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

          allMessages.sort((a, b) => (b['timeStamp'] as Timestamp)
              .compareTo(a['timeStamp'] as Timestamp));

          if (displayedMessages.isEmpty) {
            displayedMessages = allMessages.take(messagesPerPage).toList();
          } else {
            var newMessages = allMessages
                .take(messagesPerPage)
                .where((message) => !displayedMessages.any((displayed) =>
                    displayed['timeStamp'] == message['timeStamp'] &&
                    displayed['message'] == message['message']))
                .toList();

            if (newMessages.isNotEmpty) {
              displayedMessages = allMessages.take(messagesPerPage).toList();
            }
          }
        });
      }
    });
  }

  void _scrollListener() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent &&
        !isLoadingMore &&
        displayedMessages.length < allMessages.length) {
      _loadMoreMessages();
    }
  }

  void _loadMoreMessages() async {
    if (isLoadingMore || displayedMessages.length >= allMessages.length) return;

    setState(() {
      isLoadingMore = true;
    });

    final currentScrollPosition = scrollController.position.pixels;

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      int startIndex = displayedMessages.length;
      int endIndex = startIndex + messagesPerPage;
      if (endIndex > allMessages.length) {
        endIndex = allMessages.length;
      }

      displayedMessages.addAll(allMessages.sublist(startIndex, endIndex));
      isLoadingMore = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          currentScrollPosition,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleMessageAdded(Map<String, dynamic> message) {
    setState(() {
      bool messageExists = displayedMessages.any((msg) =>
          msg['timeStamp'] == message['timeStamp'] &&
          msg['message'] == message['message']);

      if (!messageExists) {
        displayedMessages.insert(0, message);

        if (displayedMessages.length > messagesPerPage) {
          displayedMessages = displayedMessages.sublist(0, messagesPerPage);
        }
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
      await messageSender.sendTextMessage(text);
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final messageTime = timestamp.toDate();
    return DateFormat('HH:mm dd/MM/yyyy').format(messageTime);
  }

  @override
  Widget build(BuildContext context) {
    final userId = authService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(title: Text(widget.nickname)),
      body: Column(
        children: [
          Expanded(
            child: MessageList(
              displayedMessages: displayedMessages,
              allMessages: allMessages,
              scrollController: scrollController,
              isLoadingMore: isLoadingMore,
              formatTimestamp: formatTimestamp,
            ),
          ),
          StreamBuilder<bool>(
            stream: chatService.isBlockedHimStream(userId, widget.friendId),
            builder: (context, snapshot) {
              bool amIBlockedThisUser = snapshot.data ?? false;

              if (amIBlockedThisUser) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.yellow[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "You have blocked this user",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          chatService.blockActionUserForFriend(userId, widget.friendId);
                        },
                        child: Text("Unblock"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // If not blocked by current user, show input or blocked message
              if (!isBlocked) {
                return UserInput(
                  messController: messController,
                  focusNode: focusNode,
                  friendId: widget.friendId,
                  onMessageSent: goToBot,
                  sendTextMessage: sendTextMessage,
                  sendImageMessage: messageSender.sendImageMessage,
                  sendVideoMessage: messageSender.sendVideoMessage,
                  sendFileMessage: messageSender.sendFileMessage,
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "You have been blocked by your friend and cannot send messages.",
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget MessageList({
    required List<Map<String, dynamic>> displayedMessages,
    required List<Map<String, dynamic>> allMessages,
    required ScrollController scrollController,
    required bool isLoadingMore,
    required String Function(Timestamp) formatTimestamp,
  }) {
    String userId = authService.getCurrentUserId();

    if (displayedMessages.isEmpty) {
      return const Center(
          child: Text("No messages yet. Start the conversation!"));
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      itemCount: displayedMessages.length +
          (displayedMessages.length < allMessages.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayedMessages.length) {
          return Container(
            padding: EdgeInsets.all(16),
            alignment: Alignment.center,
            child:
                isLoadingMore ? CircularProgressIndicator() : SizedBox.shrink(),
          );
        }

        Map<String, dynamic> data = displayedMessages[index];
        Timestamp currentTimestamp = data["timeStamp"];

        bool showTimestamp = index == displayedMessages.length - 1;
        if (!showTimestamp && index < displayedMessages.length - 1) {
          Timestamp nextTimestamp = displayedMessages[index + 1]["timeStamp"];
          showTimestamp = currentTimestamp
                  .toDate()
                  .difference(nextTimestamp.toDate())
                  .inHours >
              3;
        }

        return MessBoxWithData(data, showTimestamp, formatTimestamp);
      },
    );
  }

  Widget MessBoxWithData(Map<String, dynamic> data, bool showTimestamp,
      String Function(Timestamp) formatTimestamp) {
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;
    var messageColor = isMyMess ? Colors.blue : Colors.grey;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isMyMess ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                  : data["messType"] == "VHolder"
                      ? Container(
                          height: 100,
                          width: 250,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(),
                              Positioned(
                                bottom: 10,
                                child: Text(
                                  'Uploading...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : data["messType"] == "holder"
                          ? Stack(
                              children: [
                                Image.file(
                                  File(data["message"]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 50,
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'Uploading...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : data["messType"] == "video"
                              ? VideoPlayerWidget(
                                  videoUrl: data["message"] ?? '')
                              : data["messType"] == "file"
                                  ? GestureDetector(
                                      onTap: () => launchUrl(
                                          Uri.parse(data["message"] ?? '')),
                                      child: Row(
                                        children: [
                                          Icon(Icons.insert_drive_file,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  data["fileName"] ?? '',
                                                  style: TextStyle(
                                                      color: Colors.white))),
                                          IconButton(
                                            icon: Icon(Icons.download,
                                                color: Colors.white),
                                            onPressed: () => launchUrl(
                                                Uri.parse(
                                                    data["message"] ?? '')),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RichText(
                                      text: replaceEmoticons(
                                          data["message"] ?? '')),
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
