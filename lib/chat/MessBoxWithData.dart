import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:strong_chat/chat/Media/FullScreenMediaView.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import 'package:universal_io/io.dart';
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
                // Message content
                GestureDetector(
                  onLongPress: !isWeb ? () => showOptionsMenu(context) : null,
                  child: Container(
                    decoration: (widget.data["messType"] == "image" ||
                        widget.data["messType"] == "video" ||
                        widget.data["messType"] == "holder")
                        ? null
                        : BoxDecoration(
                      color: messageColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: (widget.data["messType"] == "image" ||
                        widget.data["messType"] == "video" ||
                        widget.data["messType"] == "holder")
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
                // Likes indicator
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
                            color: Colors.blueGrey,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 20,
                        ),
                      ],
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
                        : Colors.black,
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
              Icon(Icons.insert_drive_file, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatFileName(widget.data['fileName'], 26) ?? '',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  _confirmDownload(context, widget.data['message'], widget.data['fileName']);
                },
              ),
            ],
          ),
        );
      case "call":
        return Row(
          children: [
            Icon(
              Icons.call,
              color: widget.themeProvider.themeMode == ThemeMode.dark
                  ? Colors.white
                  : Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.data["message"] ?? '',
                style: TextStyle(
                  color: widget.themeProvider.themeMode == ThemeMode.dark
                      ? Colors.white
                      : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      default:
        return Container();
    }
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
            if (isMyMess && isUndoable)
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
            ListTile(
              leading: Icon(Icons.check),
              title: Text("Check"),
              onTap: () {
                Navigator.pop(context);
                print("data : $widget.data");
              },
            )
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
  }
}