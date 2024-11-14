import 'package:flutter/material.dart';

class MessageBox extends StatelessWidget {
  bool isMyMess;
  Alignment alignment;
  String message;
  MessageBox({super.key, required this.isMyMess, required this.alignment, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: isMyMess ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(12)
        ),
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        alignment: alignment,
        child: Text(message, style: TextStyle(color: Colors.white),));
  }
}
