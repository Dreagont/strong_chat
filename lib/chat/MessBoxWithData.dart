import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:strong_chat/chat/Media/FullScreenMediaView.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:universal_io/io.dart';
import '../call/Videocall.dart';
import '../pages/ChangeTheme.dart';
import 'ChatUtils/ImageWithPlaceholder.dart';
import 'Media/VideoPlayerWidget.dart';
import 'package:http/http.dart' as http;
class MessageBoxWithData extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool showTimestamp;
  final String Function(Timestamp) formatTimestamp;
  final ThemeProvider themeProvider;
  final AuthService authService;
  final FireStoreService chatService;
  final List<MediaItem> mediaItems;
  final Map<String, dynamic> friendData;

  const MessageBoxWithData({
    Key? key,
    required this.data,
    required this.showTimestamp,
    required this.formatTimestamp,
    required this.themeProvider,
    required this.authService,
    required this.chatService,
    required this.mediaItems,
    required this.friendData,
  }) : super(key: key);

  @override
  State<MessageBoxWithData> createState() => _MessageBoxWithDataState();
}

class _MessageBoxWithDataState extends State<MessageBoxWithData> {
  bool isHovered = false;
  String? userToken;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _handleHoverExit() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => isHovered = false);
      }
    });
  }

  double _getMaxWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;
    return isPhone ? screenWidth * 0.5 : 300.0;
  }

  @override
  Widget build(BuildContext context) {
    bool isWeb = identical(0, 0.0);
    bool isMyMess = widget.data['senderId'] == widget.authService.getCurrentUserId();
    String currentUserId = widget.authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;
    var messageColor = isMyMess
        ? (widget.themeProvider.themeMode == ThemeMode.dark
        ? Colors.cyan[700]
        : Colors.lightBlue)
        : (widget.themeProvider.themeMode == ThemeMode.dark
        ? Colors.grey[900]
        : Colors.white);

    List<String> deletedBy = List<String>.from(widget.data['deletedBy'] ?? []);
    if (deletedBy.contains(currentUserId)) {
      return SizedBox.shrink();
    }

    List<String> likes = List<String>.from(widget.data['likes'] ?? []);
    bool hasLikes = likes.isNotEmpty;

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
        isMyMess ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (widget.showTimestamp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Center(
                child: Text(
                  widget.formatTimestamp(widget.data["timeStamp"]),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          MouseRegion(
            onEnter: isWeb ? (_) => setState(() => isHovered = true) : null,
            onExit: isWeb ? (_) => _handleHoverExit() : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onLongPress: !isWeb ? () => showOptionsMenu(context) : null,
                  child: Container(
                    decoration: (widget.data["messType"] == "image" ||
                        widget.data["messType"] == "video" ||
                        widget.data["messType"] == "holder" || widget.data["messType"] == 'call')
                        ? null
                        : BoxDecoration(
                      color: messageColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: (widget.data["messType"] == "image" ||
                        widget.data["messType"] == "video" ||
                        widget.data["messType"] == "holder" || widget.data["messType"] == 'call')
                        ? null
                        : EdgeInsets.all(16),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _getMaxWidth(context),
                        maxHeight: widget.data["messType"] == "image" || widget.data["messType"] == "video"
                            ? _getMaxWidth(context) * (3/4)
                            : double.infinity,
                      ),
                      child: _buildMessageContent(context, isMyMess),
                    ),
                  ),
                ),
                if (isWeb && isHovered)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: isMyMess ? -20 : null,
                    right: isMyMess ? null : -20,
                    child: Center(
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: widget.themeProvider.themeMode == ThemeMode.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            color: widget.themeProvider.themeMode == ThemeMode.dark
                                ? Colors.white
                                : Colors.black54,
                          ),
                          onPressed: () => showOptionsMenu(context),
                        ),
                      ),
                    ),
                  ),
                if (hasLikes)
                  Positioned(
                    bottom: -5,
                    left: isMyMess ? 10 : null,
                    right: isMyMess ? null : 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.themeProvider.themeMode == ThemeMode.dark
                            ? Colors.grey[700]
                            : Colors.white38,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: likes.length == 1
                          ? Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 14,
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            ' ${likes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, bool isMyMess) {
    String userId = AuthService().getCurrentUserId();
    switch (widget.data["messType"]) {
      case "image":
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageWithPlaceholder(
            imageUrl: widget.data["message"] ?? '',
            mediaUrls: widget.mediaItems,
          ),
        );
      case "video":
        return VideoPlayerWidget(
          videoUrl: widget.data["message"] ?? '',
          mediaUrls: widget.mediaItems,
        );
      case "VHolder":
        return Container(
          height: 100,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(),
              Positioned(
                bottom: 10,
                child: Text(
                  'Uploading...',
                  style: TextStyle(
                    color: widget.themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      case "holder":
        return Stack(
          children: [
            if (widget.data["message"] is Uint8List)
              Image.memory(
                widget.data["message"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: widget.themeProvider.themeMode == ThemeMode.dark
                        ? isMyMess ? Colors.white : Colors.black
                        : Colors.black,
                    size: 50,
                  );
                },
              )
            else
              Image.network(
                widget.data["message"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: widget.themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
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
        );
      case "text":
        return Text(
          widget.data["message"] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: widget.themeProvider.themeMode == ThemeMode.dark
                ? isMyMess ? Colors.white : Colors.white
                : isMyMess ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        );
      case "file":
        return GestureDetector(
          onTap: () {
            _confirmDownload(context, widget.data['message'], widget.data['fileName']);
          },
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, color: widget.themeProvider.themeMode == ThemeMode.dark
              ? isMyMess ? Colors.white : Colors.white
                  : isMyMess ? Colors.white : Colors.black),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatFileName(widget.data['fileName'], 26) ?? '',
                  style: TextStyle(color: widget.themeProvider.themeMode == ThemeMode.dark
                      ? isMyMess ? Colors.white : Colors.white
                      : isMyMess ? Colors.white : Colors.black),
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, color: widget.themeProvider.themeMode == ThemeMode.dark
                    ? isMyMess ? Colors.white : Colors.white
                    : isMyMess ? Colors.white : Colors.black),
                onPressed: () {
                  _confirmDownload(context, widget.data['message'], widget.data['fileName']);
                },
              ),
            ],
          ),
        );
      case "call":
        return Container(
          decoration: BoxDecoration(
            color: widget.themeProvider.themeMode == ThemeMode.dark
                ? Colors.grey[850]
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
              },
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          widget.data['message'] == 'Missing Call'
                              ? Icons.phone_callback
                              : Icons.call,
                          color: widget.data['message'] == 'Missing Call'
                              ? Colors.red
                              : widget.themeProvider.themeMode == ThemeMode.dark
                              ? isMyMess ? Colors.green : Colors.blue
                              : isMyMess ? Colors.green : Colors.blue,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.data['message'] == 'Missing Call'
                                ? 'Missing Call'
                                : isMyMess ? 'Call' : 'Incoming Call',
                            style: TextStyle(
                              color: widget.themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.data['message'] != 'Missing Call') ...[
                      SizedBox(height: 8),
                      Text(
                        "Duration: ${widget.data['message']}" ,
                        style: TextStyle(
                          color: widget.themeProvider.themeMode == ThemeMode.dark
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildCallBackButton(
      BuildContext context, {
        required IconData icon,
        required bool isVoice,
        required String? userToken,
        required Map<String, dynamic> friendData,
        required String userId,
      }) {
    return IconButton(
      icon: Icon(icon, color: Colors.green.shade600),
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: userToken != null
          ? () async {
        final name = await FireStoreService().fetchUserName(userId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallPage(
              number: 1,
              notificationToken: userToken,
              CaleeName: friendData['name'],
              CallerName: name,
              roomId: '',
              isVoice: isVoice,
              callerId: userId,
              calleeId: friendData['id'],
              hangupPerson: true,
            ),
          ),
        );
      }
          : null,
    );
  }

  void showOptionsMenu(BuildContext context) {
    Timestamp messageTime = widget.data['timeStamp'];
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime.toDate());
    bool isUndoable = difference.inMinutes <= 15;
    List<String> likes = List<String>.from(widget.data['likes'] ?? []);
    bool isMyMess = widget.data['senderId'] == widget.authService.getCurrentUserId();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: likes.contains(widget.authService.getCurrentUserId()) ? Colors.red : null,
              ),
              title: Text(
                  likes.contains(widget.authService.getCurrentUserId()) ? "Unlike Message" : "Like Message"),
              onTap: () {
                Navigator.pop(context);
                _handleLikeMessage(widget.data['id'], likes.contains(widget.authService.getCurrentUserId()));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text("Delete Message"),
              onTap: () {
                Navigator.pop(context);
                _handleDeleteMessage(widget.data['id']);
              },
            ),
            if (isMyMess && isUndoable && widget.data['messType'] != 'call')
              ListTile(
                leading: Icon(Icons.undo),
                title: Text("Undo Send"),
                onTap: () {
                  Navigator.pop(context);
                  widget.chatService.undoSentMessage(
                      widget.authService.getCurrentUserId(), widget.friendData['id'], widget.data['timeStamp']);
                },
              ),
            if (widget.data["messType"] == null || widget.data["messType"] == "text")
              ListTile(
                leading: Icon(Icons.copy),
                title: Text("Copy"),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: widget.data["message"] ?? ''));
                },
              ),
          ],
        );
      },
    );
  }

  void _handleLikeMessage(String messageId, bool isLiked) async {
    final userId = widget.authService.getCurrentUserId();
    await widget.chatService.toggleMessageLike(userId, widget.friendData['id'], messageId);
  }

  void _handleDeleteMessage(String messageId) async {
    final userId = widget.authService.getCurrentUserId();
    await widget.chatService.deleteMessage(userId, widget.friendData['id'], messageId);
  }

  String _formatFileName(String fileName, int maxLength) {
    if (fileName.length <= maxLength) return fileName;

    int keepLength = (maxLength ~/ 2) - 2;
    String extension = fileName.split('.').last;
    String baseName = fileName.substring(0, keepLength);
    String endName =
    fileName.substring(fileName.length - keepLength - extension.length - 1);

    return '$baseName...$endName';
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

    bool isWeb = identical(0, 0.0);

    if (isWeb) {
      try {
        final anchor = html.AnchorElement(href: fileUrl)
          ..target = 'blank'
          ..download = fileName;
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        print("File download initiated in web environment");
      } catch (e) {
        print("Error handling file download for web: $e");
      }
    } else {
      try {
        var response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode == 200) {
          Directory? directory;
            if (Platform.isAndroid) {
              if (int.parse(await DeviceInfoPlugin().androidInfo.then((value) => value.version.release)) < 13) {
                if (!await Permission.storage.request().isGranted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Storage permission is required')),
                  );
                  return;
                }
              }
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
          print("Failed to download file");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download file')),
          );
        }
      } catch (e) {
        print("Error downloading file: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file'"Error downloading file: $e")),
        );
      }
    }
  }
}