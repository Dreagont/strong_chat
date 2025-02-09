import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/AuthService.dart';
import '../../services/FireStoreService.dart';
import 'MessagesPageHelper.dart';

class ChatManager {
  final AuthService authService;
  final FireStoreService fireStoreService;

  ChatManager({required this.authService, required this.fireStoreService});


  Future<void> changeNickname(String friendId, String newNickname) async {
    String currentUserId = authService.getCurrentUserId();
    await fireStoreService.editNicknameForFriend(currentUserId, friendId, newNickname);
  }

  Future<void> resetNickname(BuildContext context, String friendId) async {
    String currentUserId = authService.getCurrentUserId();
    await fireStoreService.resetNicknameToDefault(currentUserId, friendId);
    _showSuccessSnackbar(context, "Nickname reset to default");
  }

  Future<void> toggleBlockUser(BuildContext context, String friendId) async {
    String currentUserId = authService.getCurrentUserId();
    bool isBlocked = await fireStoreService.isBlockedHim(currentUserId, friendId);

    String action = isBlocked ? "Unblock" : "Block";
    String message = isBlocked ? "unblock this user" : "block this user";

    _showConfirmationDialog(context, action, "Are you sure you want to $message?", () async {
      await fireStoreService.blockActionUserForFriend(currentUserId, friendId);
      _showSuccessSnackbar(context, "User ${action}ed successfully");
    });
  }


  void _showConfirmationDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }


  Future<void> hideChat(BuildContext context, String friendId) async {
    String currentUserId = authService.getCurrentUserId();
    _showConfirmationDialog(context, "Hide Chat", "Are you sure you want to hide this chat?", () async {
      await fireStoreService.hideChatForUser(currentUserId, friendId);
      _showSuccessSnackbar(context, "Hid");
    });

  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void toggleNotification(BuildContext context, String friendId) {
    final userId = authService.getCurrentUserId();
    final chatRef = FirebaseFirestore.instance
        .collection("Users")
        .doc(userId)
        .collection("chats")
        .doc(friendId);

    chatRef.get().then((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final isNotificationEnabled = data?['notificationEnabled'] ?? true;

      chatRef.update({
        'notificationEnabled': !isNotificationEnabled,
      }).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notifications ${isNotificationEnabled ? 'disabled' : 'enabled'}')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle notifications')),
        );
      });
    });
  }

  void showChangeNicknameDialog(BuildContext context, Map<String, dynamic> friendData) {
    final nicknameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Change Nickname"),
              IconButton(
                icon: Icon(Icons.restore),
                onPressed: () {
                  Navigator.pop(context);
                  resetNickname(context, friendData['id']);
                },
                tooltip: "Reset to default nickname",
              ),
            ],
          ),
          content: TextField(
            controller: nicknameController,
            decoration: InputDecoration(
              hintText: "Enter new nickname",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String newNickname = nicknameController.text.trim();
                if (newNickname.isNotEmpty) {
                  changeNickname(friendData['id'], newNickname);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

}
