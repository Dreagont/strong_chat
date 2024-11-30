import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatTile extends StatelessWidget {
  final String messType;
  final String name;
  final String avatar;
  final String lastMessage;
  final String senderPrefix;
  final DateTime timestamp;
  final void Function()? onTap;

  const ChatTile({
    super.key,
    required this.messType,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.senderPrefix,
    required this.timestamp,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedTime = DateFormat('HH:mm').format(timestamp);

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              radius: 30,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "$senderPrefix$displayMessage",
                    style: messageStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formattedTime,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
