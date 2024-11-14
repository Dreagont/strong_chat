import 'package:flutter/material.dart';
import 'package:strong_chat/services/AuthService.dart';
import 'package:strong_chat/services/FireStoreService.dart';
import '../chat/ChatPage.dart';
import '../UI_Widgets/UserTile.dart';

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
      stream: fireStoreService.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Text("Loading..."));
        }
        final users = snapshot.data;
        if (users == null) {
          return const Center(child: Text("No Users Found"));
        }
        final currentUserId = authService.getCurrentUserId();

        final filteredUsers = users.where((user) {
          return user['id'] != currentUserId;
        }).toList();

        return ListView(
          children: filteredUsers.map<Widget>((userData) => userListItem(userData, context)).toList(),
        );
      },
    );
  }

  Widget userListItem(Map<String, dynamic> userData, BuildContext context) {
    return UserTile(
      text: userData["name"],
      avatar: userData["avatar"],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(friendName: userData["name"], friendId: userData["id"],),
          ),
        );
      },
    );
  }
}
