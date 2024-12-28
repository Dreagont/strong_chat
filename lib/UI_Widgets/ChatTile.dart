import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';

class ChatTile extends StatelessWidget {
  final String messType;
  final String name;
  final String avatar;
  final String lastMessage;
  final String senderPrefix;
  final DateTime timestamp;
  final void Function()? onTap;
  final ThemeProvider theme;

  const ChatTile({
    super.key,
    required this.messType,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.senderPrefix,
    required this.timestamp,
    this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatTime(timestamp);

    String displayMessage;
    TextStyle messageStyle = TextStyle(fontSize: 14, color: Colors.grey[600]);

    switch (messType) {
      case 'text':
        displayMessage = lastMessage;
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
      default:
        displayMessage = '[Unknown message type]';
        messageStyle = messageStyle.copyWith(fontStyle: FontStyle.italic);
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.white,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Add spacing inside ListTile
              leading: CircleAvatar(
                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                radius: 25,
                child: avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
              ),
              title: Text(
                name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "$senderPrefix$displayMessage",
                style: messageStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: Text(
                formattedTime,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 85), // Adjust this value as needed to align with the text start
              child: Divider(color: theme.themeMode == ThemeMode.dark
                  ? Colors.grey[900]
                  : Colors.grey[100], thickness: 1, height: 1), // Set divider color to grey[900]
            ),
          ],
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
      return DateFormat('EEE').format(dateTime); // Day of the week (Mon, Tue, Wed, ...)
    } else if (now.year == dateTime.year) {
      return DateFormat('dd MMM').format(dateTime); // day month
    } else {
      return DateFormat('dd MMM yyyy').format(dateTime); // day month year
    }
  }
}
