import 'package:flutter/material.dart';
import 'package:strong_chat/pages/ChangeTheme.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String avatar;
  final void Function()? onTap;
  final void Function()? onAccept;
  final void Function()? onDecline;
  final void Function()? onSendRequest;
  final void Function()? onCancelRequest;
  final bool showRequestActions;
  final bool showSendRequestButton;
  final bool hasSentRequest;
  final ThemeProvider themeProvider;

  const UserTile({
    super.key,
    required this.text,
    required this.avatar,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.onSendRequest,
    this.onCancelRequest,
    this.showRequestActions = false,
    this.showSendRequestButton = false,
    this.hasSentRequest = false,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        leading: CircleAvatar(
          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
          radius: 30,
          child: avatar.isEmpty ? const Icon(Icons.person, size: 30) : null,
        ),
        title: Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSendRequestButton)
              IconButton(
                icon: hasSentRequest
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: Icon(Icons.person_remove, color: Colors.blue),
                )
                    : Icon(Icons.person_add, color: Colors.blue),
                onPressed: hasSentRequest ? onCancelRequest : onSendRequest,
              ),
            if (showRequestActions) ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onAccept,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onDecline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
