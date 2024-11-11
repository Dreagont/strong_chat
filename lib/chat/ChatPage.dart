import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:strong_chat/auth/AuthService.dart';
import 'package:strong_chat/chat/FireStoreService.dart';
import 'package:strong_chat/chat/InputBox.dart';
import 'package:strong_chat/chat/MessageBox.dart';

class ChatPage extends StatelessWidget {
  final String friendName;
  final String friendId;
  ChatPage({super.key, required this.friendName, required this.friendId});
  final TextEditingController messController = TextEditingController();

  final FireStoreService chatService = FireStoreService();
  final AuthService authService = AuthService();

  void sendMessage() async {
    if (messController.text.isNotEmpty) {
      await chatService.sendMessage(friendId, messController.text);

      messController.clear();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(friendName),),
      body: Column(
        children: [
          Expanded(child: MessageList()),
          UserInput()
        ],
      ),
    );
  }

  Widget MessageList() {
    String userId = authService.getCurrentUserId();
    return StreamBuilder(
        stream: chatService.getMessage(userId, friendId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Text("Loading..."));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) => MessBox(doc)).toList(),
          );
        }
    );
  }

  Widget MessBox(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMyMess = data['senderId'] == authService.getCurrentUserId();
    var alignment = isMyMess ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        decoration: BoxDecoration(
          color: isMyMess ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 250), // limit the width
          child: Text(
            data["message"],
            style: TextStyle(color: Colors.white),
            softWrap: true,
          ),
        ),
      ),
    );
  }



  Widget UserInput() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: Row(
        children: [
          Expanded(child: InputBox(hint: "Type your message", controller: messController,)),
          IconButton(onPressed: sendMessage, icon: Icon(Icons.send))
        ],
      ),
    );
  }
}
