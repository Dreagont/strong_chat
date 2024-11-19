import 'package:cloud_firestore/cloud_firestore.dart';

class Message{
  final String senderId;
  final String friendId;
  final String message;
  final String messType;
  final Timestamp timestamp;
  final String fileName;
  bool isSynced;

  Message({
    required this.senderId,
    required this.friendId,
    required this.message,
    required this.messType,
    required this.timestamp,
    required this.fileName,
    this.isSynced = false,
  });

  Map<String, dynamic> MessToMap() {
    return{
      'senderId': senderId,
      'friendId': friendId,
      'message': message,
      'messType': messType,
      'timeStamp' : timestamp,
      'fileName': fileName
    };
  }
}