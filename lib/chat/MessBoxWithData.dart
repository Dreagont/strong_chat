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

class MessageBoxWithData extends StatelessWidget {
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

  double _getMaxWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isPhone = screenWidth < 600;
    return isPhone ? screenWidth * 0.5 : 300.0;
  }

  @override
  Widget build(BuildContext context) {
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    String currentUserId = authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;
    var messageColor = isMyMess
        ? (themeProvider.themeMode == ThemeMode.dark
        ? Colors.cyan[700]
        : Colors.lightBlue)
        : (themeProvider.themeMode == ThemeMode.dark
        ? Colors.grey[900]
        : Colors.white);

    List<String> deletedBy = List<String>.from(data['deletedBy'] ?? []);
    if (deletedBy.contains(currentUserId)) {
      return SizedBox.shrink();
    }

    List<String> likes = List<String>.from(data['likes'] ?? []);
    bool hasLikes = likes.isNotEmpty;
    bool isLikedByCurrentUser = likes.contains(currentUserId);

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
                    constraints: BoxConstraints(
                      maxWidth: _getMaxWidth(context),
                      maxHeight: data["messType"] == "image" || data["messType"] == "video"
                          ? _getMaxWidth(context) * (3/4)
                          : double.infinity,
                    ),
                    child: _buildMessageContent(context),
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
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (data["messType"]) {
      case "image":
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageWithPlaceholder(
            imageUrl: data["message"] ?? '',
            mediaUrls: mediaItems,
          ),
        );
      case "video":
        return VideoPlayerWidget(
          videoUrl: data["message"] ?? '',
          mediaUrls: mediaItems,
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
                    color: themeProvider.themeMode == ThemeMode.dark
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
            if (data["message"] is Uint8List)
              Image.memory(
                data["message"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? Colors.white
                        : Colors.black,
                    size: 50,
                  );
                },
              )
            else
              Image.network(
                data["message"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.error,
                    color: themeProvider.themeMode == ThemeMode.dark
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
          data["message"] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white
                : Colors.black,
            fontSize: 16,
          ),
        );
      case "file":
        return GestureDetector(
          onTap: () {
            _confirmDownload(context, data['message'], data['fileName']);
          },
          child: Row(
            children: [
              Icon(Icons.insert_drive_file, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatFileName(data['fileName'], 26) ?? '',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: Icon(Icons.download, color: Colors.white),
                onPressed: () {
                  _confirmDownload(context, data['message'], data['fileName']);
                },
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }

  void showOptionsMenu(BuildContext context) {
    Timestamp messageTime = data['timeStamp'];
    DateTime now = DateTime.now();
    Duration difference = now.difference(messageTime.toDate());
    bool isUndoable = difference.inMinutes <= 15;
    List<String> likes = List<String>.from(data['likes'] ?? []);
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.favorite,
                color: likes.contains(authService.getCurrentUserId()) ? Colors.red : null,
              ),
              title: Text(
                  likes.contains(authService.getCurrentUserId()) ? "Unlike Message" : "Like Message"),
              onTap: () {
                Navigator.pop(context);
                _handleLikeMessage(data['id'], likes.contains(authService.getCurrentUserId()));
              },
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
                  chatService.undoSentMessage(
                      authService.getCurrentUserId(), friendData['id'], data['timeStamp']);
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

  void _handleLikeMessage(String messageId, bool isLiked) async {
    final userId = authService.getCurrentUserId();
    await chatService.toggleMessageLike(userId, friendData['id'], messageId);
  }

  void _handleDeleteMessage(String messageId) async {
    final userId = authService.getCurrentUserId();
    await chatService.deleteMessage(userId, friendData['id'], messageId);
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