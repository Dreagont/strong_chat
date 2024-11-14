import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final String avatar;
  final void Function()? onTap;
  final void Function()? onAccept;
  final void Function()? onDecline;
  final void Function()? onSendRequest;
  final bool showRequestActions;
  final bool showSendRequestButton;

  const UserTile({
    super.key,
    required this.text,
    required this.avatar,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.onSendRequest,
    this.showRequestActions = false,
    this.showSendRequestButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              radius: 20,
              child: avatar.isEmpty ? Icon(Icons.person, color: Colors.white) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (showRequestActions) ...[
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: onAccept,
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.red),
                onPressed: onDecline,
              ),
            ],
            if (showSendRequestButton)
              IconButton(
                icon: Icon(Icons.person_add, color: Colors.white),
                onPressed: onSendRequest,
              ),
          ],
        ),
      ),
    );
  }
}
