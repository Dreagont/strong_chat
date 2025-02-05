import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';

class ChatTile extends StatefulWidget {
  final String messType;
  final String name;
  final String avatar;
  final String lastMessage;
  final String senderPrefix;
  final DateTime timestamp;
  final void Function()? onTap;
  final void Function()? onOptionsPressed;
  final ThemeProvider theme;
  final int count;

  const ChatTile({
    super.key,
    required this.messType,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.senderPrefix,
    required this.timestamp,
    this.onTap,
    this.onOptionsPressed,
    required this.theme,
    required this.count
  });

  @override
  State<ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<ChatTile> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatTime(widget.timestamp);

    String displayMessage;
    TextStyle messageStyle = TextStyle(
      fontSize: 14,
      color: widget.theme.themeMode == ThemeMode.dark
          ? (widget.count > 0 ? Colors.white : Colors.grey[600])
          : (widget.count > 0 ? Colors.black : Colors.grey[600]),
      fontWeight: widget.count > 0 ? FontWeight.bold : FontWeight.normal,
    );

    switch (widget.messType) {
      case 'text':
        displayMessage = widget.lastMessage;
        break;
      case 'image':
        displayMessage = '[Sent an image]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'video':
        displayMessage = '[Sent a video]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'file':
        displayMessage = '[Sent a file]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      case 'call':
        displayMessage = '[A call]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
      default:
        displayMessage = '[Unknown message type]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
    }

    return MouseRegion(
      onEnter: kIsWeb ? (_) => setState(() => isHovered = true) : null,
      onExit: kIsWeb ? (_) => setState(() => isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: widget.theme.themeMode == ThemeMode.dark
              ? Colors.black
              : Colors.white,
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                leading: CircleAvatar(
                  backgroundImage: widget.avatar.isNotEmpty ? NetworkImage(widget.avatar) : null,
                  radius: 25,
                  child: widget.avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.name,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formattedTime,
                      style: TextStyle(fontSize:14,
                          color: Colors.grey[600]),
                    ),
                  ],
                ),
                subtitle: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${widget.senderPrefix}$displayMessage",
                        style: messageStyle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (widget.count > 0)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          widget.count.toString(),
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white),
                        ),
                      ),
                  ],
                ),
                trailing: kIsWeb && isHovered && widget.onOptionsPressed != null
                    ? Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onOptionsPressed,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.theme.themeMode == ThemeMode.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        size: 20,
                        color: widget.theme.themeMode == ThemeMode.dark
                            ? Colors.grey[300]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                )
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 85),
                child: Divider(
                  color: widget.theme.themeMode == ThemeMode.dark
                      ? Colors.grey[900]
                      : Colors.grey[100],
                  thickness: 1,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else if (now.year == dateTime.year) {
      return DateFormat('dd MMM').format(dateTime);
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime);
    }
  }
}