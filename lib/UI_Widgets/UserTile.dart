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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (showSendRequestButton) ...[
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
                      ],
                    ],
                  ),
                  if (showRequestActions)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: onAccept,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: onDecline,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
