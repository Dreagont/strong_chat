import 'package:cloud_firestore/cloud_firestore.dart';

class Message{
  final String senderId;
  final String friendId;
  final String message;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.friendId,
    required this.message,
    required this.timestamp
  });

  Map<String, dynamic> MessToMap() {
    return{
      'senderId': senderId,
      'friendId': friendId,
      'message': message,
      'timeStamp' : timestamp
    };
  }
}