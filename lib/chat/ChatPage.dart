import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:strong_chat/chat/ChatMore.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../services/StorageService.dart';
import '../utils/Utils.dart';
import 'ChatUtils/ImageWithPlaceholder.dart';
import 'ChatUtils/MessageSenderService.dart';
import 'ChatUtils/UserInput.dart';
import 'Media/FullScreenMediaView.dart';
import 'Media/VideoPlayerWidget.dart';

class ChatPage extends StatefulWidget {
  final String nickname;
  final Map<String, dynamic> friendData;

  const ChatPage(
      {super.key,
      required this.friendData,
      required this.nickname,
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
    chatService.getIsBlockedStream(userId, widget.friendData['id']).listen((blocked) {
      setState(() {
        isBlocked = blocked;
      });
    });
  }

  List<MediaItem> mediaItems = [];

  void _setupMessageStream() {
    final userId = authService.getCurrentUserId();
    _messageSubscription = chatService.getMessage(userId, widget.friendData['id']).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          var newMessages = snapshot.docs.map((doc) {
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
          }).where((msg) => !msg['deletedBy'].contains(userId)).toList();

          newMessages.sort((a, b) => (b['timeStamp'] as Timestamp).compareTo(a['timeStamp'] as Timestamp));

          allMessages = newMessages;

          mediaItems = newMessages
              .where((msg) => msg['messType'] == 'image' || msg['messType'] == 'video')
              .map((msg) => MediaItem(
            url: msg['message'] as String,
            isVideo: msg['messType'] == 'video',
            fileName: msg['fileName'] ?? 'unname',
          ))
              .toList()
              .reversed
              .toList();

          print(mediaItems);

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

  void _handleLikeMessage(String messageId, bool isLiked) async {
    final userId = authService.getCurrentUserId();
    await chatService.toggleMessageLike(userId, widget.friendData['id'], messageId);
  }

  void _handleDeleteMessage(String messageId) async {
    final userId = authService.getCurrentUserId();
    await chatService.deleteMessage(userId, widget.friendData['id'], messageId);
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
    final lastName = widget.nickname.split(' ').last;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.friendData['avatar']),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                lastName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.call_outlined),
            onPressed: () {
              print("On develop Call");
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined),
            onPressed: () {
              print("On develop VideoCall");
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatMore(
                  nickname: widget.nickname,
                  friendData: widget.friendData,
                  allMessages : allMessages
                  )
                ),
              );
            },
            icon: Icon(Icons.more_vert),
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
            ),
          ),
          StreamBuilder<bool>(
            stream: chatService.isBlockedHimStream(userId, widget.friendData['id']),
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
                          chatService.blockActionUserForFriend(userId, widget.friendData['id']);
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
            child: isLoadingMore ? CircularProgressIndicator() : SizedBox.shrink(),
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
        if(index ==0){
          if(data['isRead']== true){
            deliverStatus = 'Seen';
          }else if(data['isNoti_isDeliver']==true){
            deliverStatus = "Received";
          }else{
            deliverStatus = "Delivered";
          }
        }


        return Column(
          children: [
            MessBoxWithData(data, showTimestamp, formatTimestamp),
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
            if(index == 0 && data['senderId'] != userId)
              SizedBox(height: 10,)
          ],
        );
      },
    );
  }

  void _confirmDownload(BuildContext context, String? fileUrl, String? fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Download'),
          content: Text('Do you want to download the file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadFile(fileUrl, fileName);
              },
              child: Text('Download'),
            ),
          ],
        );
      },
    );
  }

  void _downloadFile(String? fileUrl, String? fileName) async {
    if (fileUrl == null || fileName == null) return;

    try {
      var response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        Directory? directory;

        if (await Permission.storage.request().isGranted) {
          if (Platform.isAndroid) {
            directory = await getExternalStorageDirectory();
            String newPath = "";
            List<String> paths = directory!.path.split("/");
            for (int x = 1; x < paths.length; x++) {
              String folder = paths[x];
              if (folder != "Android") {
                newPath += "/" + folder;
              } else {
                break;
              }
            }
            newPath = newPath + "/Download";
            directory = Directory(newPath);
          } else {
            directory = await getApplicationDocumentsDirectory();
          }

          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          print("File downloaded to ${file.path}");
        } else {
          print("Permission denied");
        }
      } else {
        print("Failed to download file");
      }
    } catch (e) {
      print("Error downloading file: $e");
    }
  }

  String _formatFileName(String fileName, int maxLength) {
    if (fileName.length <= maxLength) return fileName;

    int keepLength = (maxLength ~/ 2) - 2;
    String extension = fileName.split('.').last;
    String baseName = fileName.substring(0, keepLength);
    String endName = fileName.substring(fileName.length - keepLength - extension.length - 1);

    return '$baseName...$endName';
  }


  Widget MessBoxWithData(Map<String, dynamic> data, bool showTimestamp,
      String Function(Timestamp) formatTimestamp) {
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    String currentUserId = authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;
    var messageColor = isMyMess ? Colors.blue : Colors.grey;
    double screenWidth = MediaQuery.of(context).size.width;

    List<String> deletedBy = List<String>.from(data['deletedBy'] ?? []);
    if (deletedBy.contains(currentUserId)) {
      return SizedBox.shrink();
    }

    List<String> likes = List<String>.from(data['likes'] ?? []);
    bool hasLikes = likes.isNotEmpty;
    bool isLikedByCurrentUser = likes.contains(currentUserId);

    void showOptionsMenu(BuildContext context) {
      Timestamp messageTime = data['timeStamp'];
      DateTime now = DateTime.now();
      Duration difference = now.difference(messageTime.toDate());
      bool isUndoable = difference.inMinutes <= 15;

      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.favorite,
                  color: isLikedByCurrentUser ? Colors.red : null,
                ),
                title: Text(isLikedByCurrentUser ? "Unlike Message" : "Like Message"),
                onTap: () {
                  Navigator.pop(context);
                  _handleLikeMessage(data['id'], isLikedByCurrentUser);                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete Message"),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteMessage(data['id']);
                },
              ),
              if (isMyMess && isUndoable)
                ListTile(
                  leading: Icon(Icons.undo),
                  title: Text("Undo Send"),
                  onTap: () {
                    Navigator.pop(context);
                    chatService.undoSentMessage(currentUserId, widget.friendData['id'], data['timeStamp']);
                  },
                ),
              if (data["messType"] == null || data["messType"] == "text")
                ListTile(
                  leading: Icon(Icons.copy),
                  title: Text("Copy"),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: data["message"] ?? ''));
                  },
                ),
              ListTile(
                leading: Icon(Icons.check),
                title: Text("Check"),
                onTap: () {
                  Navigator.pop(context);
                  print("data : $data");
                },
              )
            ],
          );
        },
      );
    }

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onLongPress: () => showOptionsMenu(context),
                child: Container(
                  decoration: (data["messType"] == "image" ||
                      data["messType"] == "video" ||
                      data["messType"] == "holder")
                      ? null
                      : BoxDecoration(
                    color: messageColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: (data["messType"] == "image" ||
                      data["messType"] == "video" ||
                      data["messType"] == "holder")
                      ? null
                      : EdgeInsets.all(16),
                  margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 2 / 4 * screenWidth),
                    child: data["messType"] == "image"
                        ? ImageWithPlaceholder(
                      imageUrl: data["message"] ?? '',
                      mediaUrls: mediaItems,
                    )
                        : data["messType"] == "video"
                        ? VideoPlayerWidget(
                      videoUrl: data["message"] ?? '',
                      mediaUrls: mediaItems,
                    )
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
                        : data["messType"] == "text"
                        ? RichText(
                      text: replaceEmoticons(data["message"] ?? ''),
                    )
                        : data["messType"] == "file"
                        ? GestureDetector(
                      onTap: () {
                        _confirmDownload(context, data['message'], data['fileName']);
                      },
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  _formatFileName(data['fileName'], 26) ?? '',
                                  style: TextStyle(
                                      color: Colors.white))),
                          IconButton(
                            icon: Icon(Icons.download,
                                color: Colors.white),
                            onPressed: () {
                              _confirmDownload(context, data['message'], data['fileName']);
                            }
                          ),
                        ],
                      ),
                    )
                        : Container(),
                  ),
                ),
              ),
              if (hasLikes)
                Positioned(
                  bottom: -10,
                  left: isMyMess ? 10 : null,
                  right: isMyMess ? null : 10,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      Icon(
                        isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ),
            ],
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
