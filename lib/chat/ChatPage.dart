import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:strong_chat/UI_Widgets/InputBox.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/StorageService.dart';
import '../utils/Utils.dart';

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

  void sendTextMessage() async {
    if (messController.text.isNotEmpty) {
      await chatService.sendMessage(
          widget.friendId, messController.text, 'text', "");
      messController.clear();
      goToBot();
    }
  }

  void sendImageMessage(BuildContext context) async {
    final Timestamp timestamp = Timestamp.now();
    List<String> ids = [authService.getCurrentUserId(), widget.friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    String filePath = 'ChatData/$chatBoxId/$timestamp.jpg';
    await storageService.uploadImage(
        timestamp.toString(), 'ChatData/$chatBoxId');
    String mess = await FirebaseStorage.instance.ref(filePath).getDownloadURL();
    await chatService.sendMessage(widget.friendId, mess, 'image', "");
    goToBot();
  }

  void sendVideoMessage(BuildContext context) async {
    final Timestamp timestamp = Timestamp.now();
    List<String> ids = [authService.getCurrentUserId(), widget.friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    await storageService.uploadVideo(
        timestamp.toString(), 'ChatData/$chatBoxId', chatBoxId, widget.friendId);

    goToBot();
  }

  void sendFileMessage(BuildContext context) async {
    final Timestamp timestamp = Timestamp.now();
    List<String> ids = [authService.getCurrentUserId(), widget.friendId];
    ids.sort();
    String chatBoxId = ids.join('_');

    await storageService.uploadFile(
        timestamp.toString(), 'ChatData/$chatBoxId', chatBoxId, widget.friendId);
    goToBot();
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
                  sendVideoMessage(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file),
                title: Text('File'),
                onTap: () {
                  Navigator.pop(context);
                  sendFileMessage(context);
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
              constraints: BoxConstraints(maxWidth: 250),
              child: data["messType"] == "image"
                  ? Image.network(data["message"], fit: BoxFit.cover)
                  : data["messType"] == "video"
                  ? VideoPlayerWidget(videoUrl: data["message"])
                  : data["messType"] == "file"
                  ? GestureDetector(
                onTap: () => launchUrl(Uri.parse(data["message"])),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(child: Text(data["fileName"], style: TextStyle(color: Colors.white))),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white),
                      onPressed: () => launchUrl(Uri.parse(data["message"])),
                    ),
                  ],
                ),
              )
                  : RichText(text: replaceEmoticons(data["message"])),
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

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    )
        : Center(child: CircularProgressIndicator());
  }
}
