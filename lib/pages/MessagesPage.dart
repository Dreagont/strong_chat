import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import '../chat/ChatPage.dart';
import '../UI_Widgets/ChatTile.dart';

class MessagesPage extends StatelessWidget {
  final FireStoreService fireStoreService = FireStoreService();
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userList(),
    );
  }

  Widget userList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fireStoreService.getChatsStream(authService.getCurrentUserId()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('StreamBuilder Error: ${snapshot.error}');
          return const Center(child: Text("Error"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snapshot.data;
        if (friends == null || friends.isEmpty) {
          return const Center(child: Text("No Friends Found"));
        }

        return ListView(
          children: friends.map<Widget>((friendData) => friendListItem(friendData, context)).toList(),
        );
      },
    );
  }

  Widget friendListItem(Map<String, dynamic> friendData, BuildContext context) {
    final String currentUserId = authService.getCurrentUserId();

    return StreamBuilder<QuerySnapshot>(
      stream: fireStoreService.getMessage(currentUserId, friendData['id']),
      builder: (context, messageSnapshot) {
        if (messageSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (messageSnapshot.hasError) {
          return Text('Error: ${messageSnapshot.error}');
        }
        if (!messageSnapshot.hasData || messageSnapshot.data!.docs.isEmpty) {
          return SizedBox.shrink();  // Hide friends with no messages
        }

        final lastMessageDoc = messageSnapshot.data!.docs.last;
        final lastMessage = lastMessageDoc['message'];
        final senderId = lastMessageDoc['senderId'];
        final timestamp = (lastMessageDoc['timeStamp'] as Timestamp).toDate();

        final senderPrefix = senderId == currentUserId ? 'Me: ' : '${friendData["name"]}: ';
        final formattedMessage = '$senderPrefix$lastMessage';

        return ChatTile(
          name: friendData["name"],
          avatar: friendData["avatar"],
          lastMessage: formattedMessage,
          timestamp: timestamp,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  friendName: friendData["name"],
                  friendId: friendData["id"],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
