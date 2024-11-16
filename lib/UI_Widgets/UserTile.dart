import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              radius: 20,
              child: avatar.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
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
            if (showSendRequestButton) ...[
              IconButton(
                icon: hasSentRequest
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: Icon(Icons.person_remove, color: Colors.white),
                )
                    : Icon(Icons.person_add, color: Colors.white),
                onPressed: hasSentRequest ? onCancelRequest : onSendRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
