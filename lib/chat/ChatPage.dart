import 'dart:async';
import 'dart:math';
import 'package:strong_chat/chat/MessBoxWithData.dart';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:strong_chat/chat/ChatMore.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:intl/intl.dart';

import '../call/Videocall.dart';
import '../pages/ChangeTheme.dart';
import '../services/StorageService.dart';
import 'ChatUtils/MessageSenderService.dart';
import 'ChatUtils/UserInput.dart';
import 'Media/FullScreenMediaView.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> friendData;

  const ChatPage({
    super.key,
    required this.friendData,
  });

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
      friendId: widget.friendData['id'],
      onMessageAdded: _handleMessageAdded,
      onMessageSent: goToBot,
      context: context
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
    chatService
        .getIsBlockedStream(userId, widget.friendData['id'])
        .listen((blocked) {
      setState(() {
        isBlocked = blocked;
      });
    });
  }

  List<MediaItem> mediaItems = [];

  void _setupMessageStream() {
    final userId = authService.getCurrentUserId();
    _messageSubscription = chatService
        .getMessage(userId, widget.friendData['id'])
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          var newMessages = snapshot.docs
              .map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'message': data['message'],
                  'messType': data['messType'],
                  'timeStamp': data['timeStamp'],
                  'senderId': data['senderId'],
                  'fileName': data['fileName'],
                  'isNoti_isDeliver': data['isNoti_isDeliver'],
                  'isRead': data['isRead'],
                  'likes': List<String>.from(data['likes'] ?? []),
                  'deletedBy': List<String>.from(data['deletedBy'] ?? []),
                };
              })
              .where((msg) => !msg['deletedBy'].contains(userId))
              .toList();

          newMessages.sort((a, b) => (b['timeStamp'] as Timestamp)
              .compareTo(a['timeStamp'] as Timestamp));

          allMessages = newMessages;

          mediaItems = newMessages
              .where((msg) =>
                  msg['messType'] == 'image' || msg['messType'] == 'video')
              .map((msg) => MediaItem(
                    url: msg['message'] as String,
                    isVideo: msg['messType'] == 'video',
                    fileName: msg['fileName'] ?? 'unname',
                  ))
              .toList()
              .reversed
              .toList();

          if (displayedMessages.isEmpty) {
            displayedMessages = allMessages.take(messagesPerPage).toList();
          } else {
            var lastVisibleTimestamp = displayedMessages.last['timeStamp'];

            var currentDisplayCount = displayedMessages.length;
            var updatedDisplayMessages = allMessages
                .take(max(currentDisplayCount, messagesPerPage))
                .toList();

            displayedMessages = updatedDisplayMessages;

            if (currentDisplayCount > messagesPerPage) {
              var lastVisibleIndex = allMessages.indexWhere(
                  (msg) => msg['timeStamp'] == lastVisibleTimestamp);
              if (lastVisibleIndex != -1) {
                displayedMessages = allMessages
                    .sublist(0, min(lastVisibleIndex + 1, allMessages.length))
                    .toList();
              }
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    final userId = authService.getCurrentUserId();

    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.blueGrey[100],
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.friendData['avatar']),
            ),
            SizedBox(width: 8),
            Flexible(
              child: StreamBuilder<String?>(
                stream: FireStoreService().getNicknameStream(userId, widget.friendData['id']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  final nickname = snapshot.data ?? widget.friendData['name'];
                  final lastName = nickname.split(' ').last;
                  return Text(
                    lastName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? Colors.white
                          : Colors.white,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? Colors.grey[850]
            : Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined),
            color: Colors.white,
            onPressed: () async {
              final cameras = await availableCameras();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                            cameras: cameras,
                            isCameraOn: false,
                          )));
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined),
            color: Colors.white,
            onPressed: () async {
              final cameras = await availableCameras();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VideoCallPage(
                            cameras: cameras,
                            isCameraOn: true,
                          )));
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatMore(
                        friendData: widget.friendData,
                        allMessages: allMessages)),
              );
            },
            icon: Icon(Icons.more_vert),
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(
                displayedMessages: displayedMessages,
                allMessages: allMessages,
                scrollController: scrollController,
                isLoadingMore: isLoadingMore,
                formatTimestamp: formatTimestamp,
                themeProvider: themeProvider),
          ),
          StreamBuilder<bool>(
            stream:
                chatService.isBlockedHimStream(userId, widget.friendData['id']),
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
                          chatService.blockActionUserForFriend(
                              userId, widget.friendData['id']);
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

              if (!isBlocked) {
                return UserInput(
                  messController: messController,
                  focusNode: focusNode,
                  friendId: widget.friendData['id'],
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
    required ThemeProvider themeProvider,
  }) {
    String userId = authService.getCurrentUserId();

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

        String deliverStatus = '';
        if (index == 0) {
          if (data['isRead'] == true) {
            deliverStatus = 'Seen';
          } else if (data['isNoti_isDeliver'] == true) {
            deliverStatus = "Received";
          } else {
            deliverStatus = "Delivered";
          }
        }

        return Column(
          children: [
            MessageBoxWithData(data: data, showTimestamp: showTimestamp, formatTimestamp: formatTimestamp,
                themeProvider: themeProvider,authService: authService,chatService: chatService, mediaItems: mediaItems,
            friendData: widget.friendData,),
            if (index == 0 && data['senderId'] == userId) ...[
              Padding(
                padding: const EdgeInsets.only(right: 25.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    deliverStatus,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
            if (index == 0 && data['senderId'] != userId)
              SizedBox(
                height: 10,
              )
          ],
        );
      },
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
